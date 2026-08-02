import 'package:dartz/dartz.dart';

import '../models/material_type_entity.dart';

abstract class MaterialTypeRepository {
  Future<Either<String, List<MaterialTypeEntity>>> getMaterialTypes({String? search});

  Future<Either<String, MaterialTypeEntity>> createMaterialType({
    required String name,
    required double weight,
    required double length,
    required double thickness,
  });

  Future<Either<String, MaterialTypeEntity>> updateMaterialType({
    required int id,
    required String name,
    required double weight,
    required double length,
    required double thickness,
  });

  Future<Either<String, bool>> deleteMaterialType(int id);
}