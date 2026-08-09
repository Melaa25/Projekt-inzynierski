import 'package:dartz/dartz.dart';

import '../models/location_entity.dart';

abstract class LocationRepository {
  Future<Either<String, List<LocationEntity>>> getLocations({String? type, int? parentId, bool onlyRoot = false});

  Future<Either<String, LocationEntity>> createLocation({
    String? code,
    required String name,
    required String type,
    int? parentId,
    String? description,
  });

  Future<Either<String, LocationEntity>> updateLocation({
    required int id,
    String? code,
    required String name,
    required String type,
    int? parentId,
    String? description,
  });

  Future<Either<String, bool>> deleteLocation(int id);
}