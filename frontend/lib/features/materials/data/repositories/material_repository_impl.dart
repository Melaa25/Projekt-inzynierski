import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/material_entity.dart';
import '../../domain/repositories/material_repository.dart';
import '../datasources/material_remote_datasource.dart';

class MaterialRepositoryImpl implements MaterialRepository {
  final MaterialRemoteDataSource remoteDataSource;

  MaterialRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<MaterialEntity>>> getMaterials() async {
    try {
      final materials = await remoteDataSource.getMaterials();
      return Right(materials);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas pobierania materiałów');
    }
  }

  @override
  Future<Either<String, MaterialEntity>> createMaterial({
    required String name,
    required double weight,
    required double length,
    String? location,
  }) async {
    try {
      final material = await remoteDataSource.createMaterial(
        name: name,
        weight: weight,
        length: length,
        location: location,
      );

      return Right(material);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas dodawania materiału');
    }
  }

  @override
  Future<Either<String, MaterialEntity>> updateMaterial({
    required int id,
    required String name,
    required double weight,
    required double length,
    String? location,
  }) async {
    try {
      final material = await remoteDataSource.updateMaterial(
        id: id,
        name: name,
        weight: weight,
        length: length,
        location: location,
      );

      return Right(material);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas edycji materiału');
    }
  }

  @override
  Future<Either<String, bool>> deleteMaterial(int id) async {
    try {
      await remoteDataSource.deleteMaterial(id);
      return const Right(true);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas usuwania materiału');
    }
  }

  String _mapDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }

      return 'Błąd API: ${e.response?.statusCode}';
    }

    return 'Błąd sieci. Sprawdź połączenie z backendem.';
  }
}
