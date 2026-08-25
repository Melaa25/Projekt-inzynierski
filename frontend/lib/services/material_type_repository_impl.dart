import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../core/offline/api_cache.dart';
import '../core/offline/connectivity_service.dart';
import '../models/material_type_entity.dart';
import '../models/material_type_model.dart';
import 'material_type_remote_data_source.dart';
import 'material_type_repository.dart';

class MaterialTypeRepositoryImpl implements MaterialTypeRepository {
  final MaterialTypeRemoteDataSource remoteDataSource;
  final ApiCache cache;
  final ConnectivityService connectivity;

  MaterialTypeRepositoryImpl(this.remoteDataSource, this.cache, this.connectivity);

  @override
  Future<Either<String, List<MaterialTypeEntity>>> getMaterialTypes({String? search}) async {
    List<Map<String, dynamic>> raw;

    try {
      raw = await remoteDataSource.getMaterialTypesRaw();
      await cache.saveList(ApiCache.materialTypesKey, raw);
      connectivity.reportSuccess();
    } on DioException catch (e) {
      if (!_isNetworkError(e)) {
        return Left(_mapDioError(e));
      }

      connectivity.reportFailure();
      raw = cache.readList(ApiCache.materialTypesKey);

      if (raw.isEmpty) {
        return const Left('Brak połączenia z serwerem i brak zapisanego katalogu materiałów.');
      }
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas pobierania materiałów.');
    }

    final types = raw.map((item) => MaterialTypeModel.fromJson(item)).toList();

    final query = (search ?? '').trim().toLowerCase();

    if (query.isEmpty) {
      return Right(types);
    }

    return Right(
      types.where((type) => type.name.toLowerCase().contains(query)).toList(),
    );
  }

  @override
  Future<Either<String, MaterialTypeEntity>> createMaterialType({
    required String name,
    required double weight,
    required double length,
    required double thickness,
  }) async {
    try {
      final type = await remoteDataSource.createMaterialType(
        name: name,
        weight: weight,
        length: length,
        thickness: thickness,
      );
      return Right(type);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas dodawania materiału.');
    }
  }

  @override
  Future<Either<String, MaterialTypeEntity>> updateMaterialType({
    required int id,
    required String name,
    required double weight,
    required double length,
    required double thickness,
  }) async {
    try {
      final type = await remoteDataSource.updateMaterialType(
        id: id,
        name: name,
        weight: weight,
        length: length,
        thickness: thickness,
      );
      return Right(type);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas edycji materiału.');
    }
  }

  @override
  Future<Either<String, bool>> deleteMaterialType(int id) async {
    try {
      await remoteDataSource.deleteMaterialType(id);
      return const Right(true);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas usuwania materiału.');
    }
  }

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