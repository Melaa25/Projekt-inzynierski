import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../models/material_batch_entity.dart';
import '../models/material_movement_entity.dart';
import 'material_batch_remote_data_source.dart';
import 'material_batch_repository.dart';

class MaterialBatchRepositoryImpl implements MaterialBatchRepository {
  final MaterialBatchRemoteDataSource remoteDataSource;

  MaterialBatchRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<MaterialBatchEntity>>> getBatches({
    String? search,
    String? status,
    String? type,
    int? locationId,
  }) async {
    try {
      final batches = await remoteDataSource.getBatches(
        search: search,
        status: status,
        type: type,
        locationId: locationId,
      );
      return Right(batches);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas pobierania partii.');
    }
  }

  @override
  Future<Either<String, MaterialBatchEntity>> getBatchByCode(String batchCode) async {
    try {
      final batch = await remoteDataSource.getBatchByCode(batchCode);
      return Right(batch);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
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
      return Right(batch);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
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
    try {
      final batch = await remoteDataSource.receiveMaterial(
        materialId: materialId,
        quantity: quantity,
        locationId: locationId,
        targetBatchId: targetBatchId,
        note: note,
      );
      return Right(batch);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
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
    try {
      final batch = await remoteDataSource.receiveWaste(
        quantity: quantity,
        weight: weight,
        locationId: locationId,
        targetBatchId: targetBatchId,
        note: note,
      );
      return Right(batch);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
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
    try {
      final batch = await remoteDataSource.issueBatch(
        batchId: batchId,
        quantity: quantity,
        destination: destination,
        note: note,
      );
      return Right(batch);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
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
    try {
      final batch = await remoteDataSource.updateBatchStatus(
        batchId: batchId,
        status: status,
        note: note,
      );
      return Right(batch);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas zmiany statusu.');
    }
  }

  @override
  Future<Either<String, bool>> deleteBatch(int batchId) async {
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
      return Right(movements);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas pobierania ruchów.');
    }
  }

  String _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    return 'Błąd API: ${e.response?.statusCode ?? 'brak kodu'}';
  }
}