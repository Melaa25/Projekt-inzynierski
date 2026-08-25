import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../core/offline/api_cache.dart';
import '../core/offline/connectivity_service.dart';
import '../models/location_entity.dart';
import '../models/location_model.dart';
import '../models/location_tree_node.dart';
import 'location_repository.dart';
import 'location_remote_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;
  final ApiCache cache;
  final ConnectivityService connectivity;

  LocationRepositoryImpl(this.remoteDataSource, this.cache, this.connectivity);

  @override
  Future<Either<String, List<LocationEntity>>> getLocations({String? type, int? parentId, bool onlyRoot = false}) async {
    List<Map<String, dynamic>> raw;

    try {
      raw = await remoteDataSource.getLocationsRaw();
      await cache.saveList(ApiCache.locationsKey, raw);
      connectivity.reportSuccess();
    } on DioException catch (e) {
      if (!_isNetworkError(e)) {
        return Left(_error(e));
      }

      connectivity.reportFailure();
      raw = cache.readList(ApiCache.locationsKey);

      if (raw.isEmpty) {
        return const Left('Brak połączenia z serwerem i brak zapisanych lokalizacji w pamięci telefonu.');
      }
    } catch (e) {
      return Left(_error(e));
    }

    final locations = raw.map((item) => LocationModel.fromJson(item)).toList();

    final filtered = locations.where((location) {
      if (type != null && location.type != type) {
        return false;
      }

      if (onlyRoot) {
        return location.parentId == null;
      }

      if (parentId != null && location.parentId != parentId) {
        return false;
      }

      return true;
    }).toList();

    // Sortujemy po pelnej sciezce, zeby polki z jednego sektora i regalu
    // byly obok siebie na liscie wyboru.
    filtered.sort((a, b) => (a.fullPath ?? a.name).compareTo(b.fullPath ?? b.name));

    return Right(filtered);
  }

  @override
  Future<Either<String, List<LocationTreeNode>>> getLocationsTree() async {
    List<Map<String, dynamic>> raw;

    try {
      raw = await remoteDataSource.getLocationsRaw();
      await cache.saveList(ApiCache.locationsKey, raw);
      connectivity.reportSuccess();
    } on DioException catch (e) {
      if (!_isNetworkError(e)) {
        return Left(_error(e));
      }

      connectivity.reportFailure();
      raw = cache.readList(ApiCache.locationsKey);

      if (raw.isEmpty) {
        return const Left('Brak połączenia z serwerem i brak zapisanych lokalizacji w pamięci telefonu.');
      }
    } catch (e) {
      return Left(_error(e));
    }

    final locations = raw.map((item) => LocationModel.fromJson(item)).toList();

    return Right(_buildTree(locations));
  }

  /// Sklada plaska liste lokalizacji w drzewo sektor -> regal -> polka.
  List<LocationTreeNode> _buildTree(List<LocationModel> locations) {
    final sectors = locations.where((l) => l.type == 'sektor' && l.parentId == null).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return sectors.map((sector) {
      final racks = locations.where((l) => l.type == 'regal' && l.parentId == sector.id).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return LocationTreeNode(
        id: sector.id,
        code: sector.code,
        name: sector.name,
        type: 'sektor',
        children: racks.map((rack) {
          final shelves = locations.where((l) => l.type == 'polka' && l.parentId == rack.id).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return LocationTreeNode(
            id: rack.id,
            code: rack.code,
            name: rack.name,
            type: 'regal',
            children: shelves
                .map((shelf) => LocationTreeNode(
                      id: shelf.id,
                      code: shelf.code,
                      name: shelf.name,
                      type: 'polka',
                    ))
                .toList(),
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  Future<Either<String, LocationEntity>> createLocation({
    String? code,
    required String name,
    required String type,
    int? parentId,
    String? description,
  }) async {
    try {
      final location = await remoteDataSource.createLocation(
        code: code,
        name: name,
        type: type,
        parentId: parentId,
        description: description,
      );
      return Right(location);
    } catch (e) {
      return Left(_error(e));
    }
  }

  @override
  Future<Either<String, LocationEntity>> updateLocation({
    required int id,
    String? code,
    required String name,
    required String type,
    int? parentId,
    String? description,
  }) async {
    try {
      final location = await remoteDataSource.updateLocation(
        id: id,
        code: code,
        name: name,
        type: type,
        parentId: parentId,
        description: description,
      );
      return Right(location);
    } catch (e) {
      return Left(_error(e));
    }
  }

  @override
  Future<Either<String, bool>> deleteLocation(int id) async {
    try {
      await remoteDataSource.deleteLocation(id);
      return const Right(true);
    } catch (e) {
      return Left(_error(e));
    }
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.unknown;
  }

  String _error(dynamic e) {
    if (e is DioException && e.response?.data is Map && e.response?.data['message'] != null) {
      return e.response?.data['message'];
    }

    return 'Coś poszło nie tak, spróbuj ponownie.';
  }
}