import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../models/material_type_entity.dart';
import 'material_type_remote_data_source.dart';
import 'material_type_repository.dart';

class MaterialTypeRepositoryImpl implements MaterialTypeRepository {
  final MaterialTypeRemoteDataSource remoteDataSource;

  MaterialTypeRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<MaterialTypeEntity>>> getMaterialTypes({String? search}) async {
    try {
      final types = await remoteDataSource.getMaterialTypes(search: search);
      return Right(types);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas pobierania materiałów.');
    }
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

  String _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    return 'Błąd API: ${e.response?.statusCode ?? 'brak kodu'}';
  }
}