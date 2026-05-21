import 'package:dartz/dartz.dart';

import '../models/material_entity.dart';

abstract class MaterialRepository {
  Future<Either<String, List<MaterialEntity>>> getMaterials();

  Future<Either<String, MaterialEntity>> createMaterial({
    required String name,
    required double weight,
    required double length,
    String? location,
    int? currentLocationId,
    required String status,
  });

  Future<Either<String, MaterialEntity>> updateMaterial({
    required int id,
    required String name,
    required double weight,
    required double length,
    String? location,
    int? currentLocationId,
    required String status,
  });

  Future<Either<String, bool>> deleteMaterial(int id);

  Future<Either<String, MaterialEntity>> recordMovement({
    required int materialId,
    required String type,
    String? destination,
    String? note,
    int? newLocationId,
  });

  Future<Either<String, List<dynamic>>> getMovements({String? type});
}