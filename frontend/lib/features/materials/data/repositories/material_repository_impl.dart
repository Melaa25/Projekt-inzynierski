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
      return const Left('Wystapil nieoczekiwany blad podczas pobierania materialow');
    }
  }

  String _mapDioError(DioException e) {
    if (e.response != null) {
      return 'Blad API: ${e.response?.statusCode}';
    }

    return 'Blad sieci. Sprawdz polaczenie z backendem.';
  }
}
