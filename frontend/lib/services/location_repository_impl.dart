import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../models/location_entity.dart';
import 'location_repository.dart';
import 'location_remote_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;

  LocationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<LocationEntity>>> getLocations() async {
    try {
      final locations = await remoteDataSource.getLocations();
      return Right(locations);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas pobierania lokalizacji');
    }
  }

  @override
  Future<Either<String, LocationEntity>> createLocation({String? code, required String name, String? type, int? parentId, String? description}) async {
    try {
      final location = await remoteDataSource.createLocation(code: code, name: name, type: type, parentId: parentId, description: description);
      return Right(location);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas tworzenia lokalizacji');
    }
  }

  @override
  Future<Either<String, LocationEntity>> updateLocation({required int id, String? code, required String name, String? type, int? parentId, String? description}) async {
    try {
      final location = await remoteDataSource.updateLocation(id: id, code: code, name: name, type: type, parentId: parentId, description: description);
      return Right(location);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas edycji lokalizacji');
    }
  }

  @override
  Future<Either<String, bool>> deleteLocation(int id) async {
    try {
      await remoteDataSource.deleteLocation(id);
      return const Right(true);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas usuwania lokalizacji');
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
