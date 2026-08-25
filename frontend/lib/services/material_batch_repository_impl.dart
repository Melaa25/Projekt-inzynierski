import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/offline/api_cache.dart';
import '../core/offline/connectivity_service.dart';
import '../core/offline/offline_queue.dart';
import '../core/offline/pending_operation.dart';
import '../models/material_batch_entity.dart';
import '../models/material_batch_model.dart';
import '../models/material_movement_entity.dart';
import 'material_batch_remote_data_source.dart';
import 'material_batch_repository.dart';

class MaterialBatchRepositoryImpl implements MaterialBatchRepository {
  final MaterialBatchRemoteDataSource remoteDataSource;
  final ApiCache cache;
  final ConnectivityService connectivity;
  final OfflineQueue queue;

  final Uuid _uuid = const Uuid();

  MaterialBatchRepositoryImpl(
    this.remoteDataSource,
    this.cache,
    this.connectivity,
    this.queue,
  );

  @override
  Future<Either<String, List<MaterialBatchEntity>>> getBatches({
    String? search,
    String? status,
    String? type,
    int? locationId,
  }) async {
    List<Map<String, dynamic>> raw;

    try {
      raw = await remoteDataSource.getBatchesRaw();
      await cache.saveList(ApiCache.batchesKey, raw);
      connectivity.reportSuccess();
    } on DioException catch (e) {
      if (!_isNetworkError(e)) {
        return Left(_mapDioError(e));
      }

      connectivity.reportFailure();
      raw = cache.readList(ApiCache.batchesKey);

      if (raw.isEmpty) {
        return const Left('Brak połączenia z serwerem i brak zapisanych danych w pamięci telefonu.');
      }
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas pobierania partii.');
    }

    final batches = raw.map((item) => MaterialBatchModel.fromJson(item)).toList();

    return Right(_filterBatches(
      batches,
      search: search,
      status: status,
      type: type,
      locationId: locationId,
    ));
  }

  @override
  Future<Either<String, MaterialBatchEntity>> getBatchByCode(String batchCode) async {
    // Partie utworzone offline istnieja tylko lokalnie - nie ma sensu pytac serwera.
    if (batchCode.startsWith('OFF-')) {
      final local = _findCachedBatchByCode(batchCode);

      if (local != null) {
        return Right(MaterialBatchModel.fromJson(local));
      }
    }

    try {
      final raw = await remoteDataSource.getBatchRawByCode(batchCode);
      connectivity.reportSuccess();

      return Right(MaterialBatchModel.fromJson(raw));
    } on DioException catch (e) {
      if (!_isNetworkError(e)) {
        return Left(_mapDioError(e));
      }

      connectivity.reportFailure();

      final local = _findCachedBatchByCode(batchCode);

      if (local != null) {
        return Right(MaterialBatchModel.fromJson(local));
      }

      return const Left('Brak połączenia, a tej partii nie ma w pamięci telefonu.');
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas wyszukiwania partii.');
    }
  }

  @override
  Future<Either<String, MaterialBatchEntity?>> suggestExisting({
    int? materialId,
    required String type,
    required int locationId,
  }) async {
    try {
      final batch = await remoteDataSource.suggestExisting(
        materialId: materialId,
        type: type,
        locationId: locationId,
      );

      connectivity.reportSuccess();

      return Right(batch);
    } on DioException catch (e) {
      if (!_isNetworkError(e)) {
        return Left(_mapDioError(e));
      }

      connectivity.reportFailure();

      // Bez sieci szukamy pasujacej partii w kopii lokalnej - taka sama regula jak na serwerze.
      for (final item in cache.readList(ApiCache.batchesKey)) {
        final matchesType = item['type'] == type;
        final matchesMaterial = item['material_id'] == materialId;
        final matchesLocation = item['current_location_id'] == locationId;
        final matchesStatus = item['status'] == 'in_stock';

        if (matchesType && matchesMaterial && matchesLocation && matchesStatus) {
          return Right(MaterialBatchModel.fromJson(item));
        }
      }

      return const Right(null);
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas sprawdzania lokalizacji.');
    }
  }

  @override
  Future<Either<String, MaterialBatchEntity>> receiveMaterial({
    required int materialId,
    required int quantity,
    required int locationId,
    int? targetBatchId,
    String? note,
  }) async {
    final operationId = _uuid.v4();
    final clientUuid = _uuid.v4();
    final performedAt = DateTime.now();

    final payload = <String, dynamic>{
      'material_id': materialId,
      'quantity': quantity,
      'location_id': locationId,
      'target_batch_id': _serverIdOrNull(targetBatchId),
      'target_batch_uuid': _clientUuidForBatch(targetBatchId),
      'note': note,
      'client_uuid': clientUuid,
      'client_operation_id': operationId,
      'performed_at': performedAt.toIso8601String(),
    };

    try {
      final batch = await remoteDataSource.receiveMaterial(payload);
      connectivity.reportSuccess();

      return Right(batch);
    } on DioException catch (e) {
      if (!_isNetworkError(e)) {
        return Left(_mapDioError(e));
      }

      connectivity.reportFailure();

      await queue.add(PendingOperation(
        id: operationId,
        endpoint: '/batches/receive-material',
        payload: payload,
        description: 'Przyjęcie materiału: $quantity szt.',
        createdAt: performedAt,
      ));

      final localBatch = await _applyReceiveLocally(
        type: 'material',
        clientUuid: clientUuid,
        materialId: materialId,
        quantity: quantity,
        weight: null,
        locationId: locationId,
        targetBatchId: targetBatchId,
      );

      return Right(localBatch);
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas przyjęcia materiału.');
    }
  }

  @override
  Future<Either<String, MaterialBatchEntity>> receiveWaste({
    required int quantity,
    double? weight,
    required int locationId,
    int? targetBatchId,
    String? note,
  }) async {
    final operationId = _uuid.v4();
    final clientUuid = _uuid.v4();
    final performedAt = DateTime.now();

    final payload = <String, dynamic>{
      'quantity': quantity,
      'weight': weight,
      'location_id': locationId,
      'target_batch_id': _serverIdOrNull(targetBatchId),
      'target_batch_uuid': _clientUuidForBatch(targetBatchId),
      'note': note,
      'client_uuid': clientUuid,
      'client_operation_id': operationId,
      'performed_at': performedAt.toIso8601String(),
    };

    try {
      final batch = await remoteDataSource.receiveWaste(payload);
      connectivity.reportSuccess();

      return Right(batch);
    } on DioException catch (e) {
      if (!_isNetworkError(e)) {
        return Left(_mapDioError(e));
      }

      connectivity.reportFailure();

      await queue.add(PendingOperation(
        id: operationId,
        endpoint: '/batches/receive-waste',
        payload: payload,
        description: 'Przyjęcie odpadu: $quantity szt.',
        createdAt: performedAt,
      ));

      final localBatch = await _applyReceiveLocally(
        type: 'waste',
        clientUuid: clientUuid,
        materialId: null,
        quantity: quantity,
        weight: weight,
        locationId: locationId,
        targetBatchId: targetBatchId,
      );

      return Right(localBatch);
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas przyjęcia odpadu.');
    }
  }

  @override
  Future<Either<String, MaterialBatchEntity>> issueBatch({
    required int batchId,
    required int quantity,
    String? destination,
    String? note,
  }) async {
    final identifier = _batchIdentifier(batchId);

    if (identifier == null) {
      return const Left('Nie można wydać z tej partii offline - brak jej danych w pamięci telefonu.');
    }

    final operationId = _uuid.v4();
    final performedAt = DateTime.now();

    final payload = <String, dynamic>{
      'quantity': quantity,
      'destination': destination,
      'note': note,
      'client_operation_id': operationId,
      'performed_at': performedAt.toIso8601String(),
    };

    try {
      final batch = await remoteDataSource.issueBatch(identifier, payload);
      connectivity.reportSuccess();

      return Right(batch);
    } on DioException catch (e) {
      if (!_isNetworkError(e)) {
        return Left(_mapDioError(e));
      }

      connectivity.reportFailure();

      final localBatch = await _applyQuantityChangeLocally(batchId, -quantity);

      if (localBatch == null) {
        return const Left('Wydanie offline nie powiodło się - w partii nie ma tylu sztuk.');
      }

      await queue.add(PendingOperation(
        id: operationId,
        endpoint: '/batches/$identifier/issue',
        payload: payload,
        description: 'Wydanie $quantity szt. z partii ${localBatch.batchCode}',
        createdAt: performedAt,
      ));

      return Right(localBatch);
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas wydania materiału.');
    }
  }

  @override
  Future<Either<String, MaterialBatchEntity>> updateBatchStatus({
    required int batchId,
    required String status,
    String? note,
  }) async {
    final identifier = _batchIdentifier(batchId);

    if (identifier == null) {
      return const Left('Nie można zmienić statusu offline - brak danych partii w pamięci telefonu.');
    }

    final operationId = _uuid.v4();
    final performedAt = DateTime.now();

    final payload = <String, dynamic>{
      'status': status,
      'note': note,
      'client_operation_id': operationId,
      'performed_at': performedAt.toIso8601String(),
    };

    try {
      final batch = await remoteDataSource.updateBatchStatus(identifier, payload);
      connectivity.reportSuccess();

      return Right(batch);
    } on DioException catch (e) {
      if (!_isNetworkError(e)) {
        return Left(_mapDioError(e));
      }

      connectivity.reportFailure();

      final localBatch = await _applyStatusChangeLocally(batchId, status);

      if (localBatch == null) {
        return const Left('Zmiana statusu offline nie powiodła się - brak danych partii.');
      }

      await queue.add(PendingOperation(
        id: operationId,
        endpoint: '/batches/$identifier/status',
        payload: payload,
        description: 'Zmiana statusu partii ${localBatch.batchCode}',
        createdAt: performedAt,
      ));

      return Right(localBatch);
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas zmiany statusu.');
    }
  }

  @override
  Future<Either<String, bool>> deleteBatch(int batchId) async {
    if (batchId < 0) {
      return const Left('Tej partii nie można usunąć przed synchronizacją.');
    }

    try {
      await remoteDataSource.deleteBatch(batchId);
      return const Right(true);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas usuwania partii.');
    }
  }

  @override
  Future<Either<String, List<MaterialMovementEntity>>> getMovements({String? type}) async {
    try {
      final movements = await remoteDataSource.getMovements(type: type);
      connectivity.reportSuccess();

      return Right(movements);
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        connectivity.reportFailure();
        return const Left('Historia ruchów jest dostępna tylko z połączeniem internetowym.');
      }

      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas pobierania ruchów.');
    }
  }

  /// Tworzy nowa partie w kopii lokalnej albo dokłada ilosc do istniejacej.
  Future<MaterialBatchEntity> _applyReceiveLocally({
    required String type,
    required String clientUuid,
    int? materialId,
    required int quantity,
    double? weight,
    required int locationId,
    int? targetBatchId,
  }) async {
    final batches = cache.readList(ApiCache.batchesKey);

    if (targetBatchId != null) {
      for (var i = 0; i < batches.length; i++) {
        if (batches[i]['id'] == targetBatchId) {
          final updated = Map<String, dynamic>.from(batches[i]);
          updated['quantity'] = ((updated['quantity'] as int?) ?? 0) + quantity;

          if (weight != null) {
            final currentWeight = (updated['total_weight'] as num?)?.toDouble() ?? 0;
            updated['total_weight'] = currentWeight + weight;
          }

          batches[i] = updated;
          await cache.replaceList(ApiCache.batchesKey, batches);

          return MaterialBatchModel.fromJson(updated);
        }
      }
    }

    final newBatch = <String, dynamic>{
      // Ujemne id oznacza partie istniejaca na razie tylko na telefonie.
      'id': -DateTime.now().millisecondsSinceEpoch,
      'type': type,
      'material_id': materialId,
      'material': _findCachedById(ApiCache.materialTypesKey, materialId),
      'batch_code': 'OFF-${clientUuid.substring(0, 8).toUpperCase()}',
      'client_uuid': clientUuid,
      'quantity': quantity,
      'total_weight': weight,
      'current_location_id': locationId,
      'current_location': _findCachedById(ApiCache.locationsKey, locationId),
      'status': 'in_stock',
      'created_at': DateTime.now().toIso8601String(),
    };

    batches.insert(0, newBatch);
    await cache.replaceList(ApiCache.batchesKey, batches);

    return MaterialBatchModel.fromJson(newBatch);
  }

  /// Zmienia ilosc w kopii lokalnej. Zwraca null, gdy partii nie ma
  /// albo gdy stan zszedlby ponizej zera.
  Future<MaterialBatchEntity?> _applyQuantityChangeLocally(int batchId, int delta) async {
    final batches = cache.readList(ApiCache.batchesKey);

    for (var i = 0; i < batches.length; i++) {
      if (batches[i]['id'] == batchId) {
        final updated = Map<String, dynamic>.from(batches[i]);
        final newQuantity = ((updated['quantity'] as int?) ?? 0) + delta;

        if (newQuantity < 0) {
          return null;
        }

        updated['quantity'] = newQuantity;
        batches[i] = updated;
        await cache.replaceList(ApiCache.batchesKey, batches);

        return MaterialBatchModel.fromJson(updated);
      }
    }

    return null;
  }

  Future<MaterialBatchEntity?> _applyStatusChangeLocally(int batchId, String status) async {
    final batches = cache.readList(ApiCache.batchesKey);

    for (var i = 0; i < batches.length; i++) {
      if (batches[i]['id'] == batchId) {
        final updated = Map<String, dynamic>.from(batches[i]);
        updated['status'] = status;
        batches[i] = updated;
        await cache.replaceList(ApiCache.batchesKey, batches);

        return MaterialBatchModel.fromJson(updated);
      }
    }

    return null;
  }

  /// Zwraca tekst, ktory trafi do adresu URL: id z serwera albo client_uuid.
  String? _batchIdentifier(int batchId) {
    if (batchId > 0) {
      return batchId.toString();
    }

    return _clientUuidForBatch(batchId);
  }

  int? _serverIdOrNull(int? batchId) {
    if (batchId == null || batchId < 0) {
      return null;
    }

    return batchId;
  }

  String? _clientUuidForBatch(int? batchId) {
    if (batchId == null || batchId > 0) {
      return null;
    }

    for (final item in cache.readList(ApiCache.batchesKey)) {
      if (item['id'] == batchId) {
        return item['client_uuid'] as String?;
      }
    }

    return null;
  }

  Map<String, dynamic>? _findCachedById(String cacheKey, int? id) {
    if (id == null) {
      return null;
    }

    for (final item in cache.readList(cacheKey)) {
      if (item['id'] == id) {
        return item;
      }
    }

    return null;
  }

  Map<String, dynamic>? _findCachedBatchByCode(String batchCode) {
    for (final item in cache.readList(ApiCache.batchesKey)) {
      if (item['batch_code'] == batchCode) {
        return item;
      }
    }

    return null;
  }

  /// Filtrowanie po stronie aplikacji - te same reguly co wczesniej na serwerze.
  List<MaterialBatchEntity> _filterBatches(
    List<MaterialBatchEntity> batches, {
    String? search,
    String? status,
    String? type,
    int? locationId,
  }) {
    final query = (search ?? '').trim().toLowerCase();

    return batches.where((batch) {
      if (type != null && type.trim().isNotEmpty && batch.type != type) {
        return false;
      }

      if (status != null && status.trim().isNotEmpty && batch.status != status) {
        return false;
      }

      if (locationId != null && batch.currentLocationId != locationId) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final code = batch.batchCode.toLowerCase();
      final materialName = (batch.material?.name ?? '').toLowerCase();
      final locationName = (batch.currentLocation?.name ?? '').toLowerCase();
      final locationCode = (batch.currentLocation?.code ?? '').toLowerCase();

      return code.contains(query) ||
          materialName.contains(query) ||
          locationName.contains(query) ||
          locationCode.contains(query);
    }).toList();
  }

  /// Rozroznia brak sieci od bledu zwroconego przez serwer (np. 401 albo 422).
  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.unknown;
  }

  String _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    return 'Błąd API: ${e.response?.statusCode ?? 'brak kodu'}';
  }
}