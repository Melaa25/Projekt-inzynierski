import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../models/location_entity.dart';
import 'location_repository.dart';
import 'location_remote_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;

  LocationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<LocationEntity>>> getLocations({String? type, int? parentId, bool onlyRoot = false}) async {
    try {
      final locations = await remoteDataSource.getLocations(type: type, parentId: parentId, onlyRoot: onlyRoot);
      return Right(locations);
    } catch (e) {
      return Left(_error(e));
    }
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

  String _error(dynamic e) {
    if (e is DioException && e.response?.data is Map && e.response?.data['message'] != null) {
      return e.response?.data['message'];
    }

    return 'Coś poszło nie tak, spróbuj ponownie.';
  }
}