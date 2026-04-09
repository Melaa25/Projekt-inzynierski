import 'package:dartz/dartz.dart';

import '../entities/material_entity.dart';

abstract class MaterialRepository {
  Future<Either<String, List<MaterialEntity>>> getMaterials();

  Future<Either<String, MaterialEntity>> createMaterial({
    required String name,
    required String serialNumber,
    required double weight,
    required double length,
    String? location,
  });

  Future<Either<String, MaterialEntity>> updateMaterial({
    required int id,
    required String name,
    required String serialNumber,
    required double weight,
    required double length,
    String? location,
  });

  Future<Either<String, bool>> deleteMaterial(int id);
}
