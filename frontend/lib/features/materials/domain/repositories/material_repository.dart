import 'package:dartz/dartz.dart';

import '../entities/material_entity.dart';

abstract class MaterialRepository {
  Future<Either<String, List<MaterialEntity>>> getMaterials();
}
