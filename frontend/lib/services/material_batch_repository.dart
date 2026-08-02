import 'package:dartz/dartz.dart';

import '../models/material_batch_entity.dart';
import '../models/material_movement_entity.dart';

abstract class MaterialBatchRepository {
  Future<Either<String, List<MaterialBatchEntity>>> getBatches({
    String? search,
    String? status,
    String? type,
    int? locationId,
  });

  Future<Either<String, MaterialBatchEntity>> getBatchByCode(String batchCode);

  Future<Either<String, MaterialBatchEntity?>> suggestExisting({
    int? materialId,
    required String type,
    required int locationId,
  });

  Future<Either<String, MaterialBatchEntity>> receiveMaterial({
    required int materialId,
    required int quantity,
    required int locationId,
    int? targetBatchId,
    String? note,
  });

  Future<Either<String, MaterialBatchEntity>> receiveWaste({
    required int quantity,
    double? weight,
    required int locationId,
    int? targetBatchId,
    String? note,
  });

  Future<Either<String, MaterialBatchEntity>> issueBatch({
    required int batchId,
    required int quantity,
    String? destination,
    String? note,
  });

  Future<Either<String, MaterialBatchEntity>> updateBatchStatus({
    required int batchId,
    required String status,
    String? note,
  });

  Future<Either<String, bool>> deleteBatch(int batchId);

  Future<Either<String, List<MaterialMovementEntity>>> getMovements({String? type});
}