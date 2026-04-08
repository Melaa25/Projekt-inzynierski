import 'package:dartz/dartz.dart';

import '../entities/material_entity.dart';
import '../repositories/material_repository.dart';

class GetMaterials {
  final MaterialRepository repository;

  GetMaterials(this.repository);

  Future<Either<String, List<MaterialEntity>>> call() {
    return repository.getMaterials();
  }
}
