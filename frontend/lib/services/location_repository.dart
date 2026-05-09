import 'package:dartz/dartz.dart';

import '../models/location_entity.dart';

abstract class LocationRepository {
  Future<Either<String, List<LocationEntity>>> getLocations();

  Future<Either<String, LocationEntity>> createLocation({
    String? code,
    required String name,
    String? type,
    int? parentId,
    String? description,
  });

  Future<Either<String, LocationEntity>> updateLocation({
    required int id,
    String? code,
    required String name,
    String? type,
    int? parentId,
    String? description,
  });

  Future<Either<String, bool>> deleteLocation(int id);
}
