import 'package:dio/dio.dart';

import '../models/material_batch_model.dart';
import '../models/material_movement_entity.dart';
import '../models/material_movement_model.dart';

abstract class MaterialBatchRemoteDataSource {
  Future<List<MaterialBatchModel>> getBatches({
    String? search,
    String? status,
    String? type,
    int? locationId,
  });

  Future<MaterialBatchModel> getBatchByCode(String batchCode);

  Future<MaterialBatchModel?> suggestExisting({
    int? materialId,
    required String type,
    required int locationId,
  });

  Future<MaterialBatchModel> receiveMaterial({
    required int materialId,
    required int quantity,
    required int locationId,
    int? targetBatchId,
    String? note,
  });

  Future<MaterialBatchModel> receiveWaste({
    required int quantity,
    double? weight,
    required int locationId,
    int? targetBatchId,
    String? note,
  });

  Future<MaterialBatchModel> issueBatch({
    required int batchId,
    required int quantity,
    String? destination,
    String? note,
  });

  Future<MaterialBatchModel> updateBatchStatus({
    required int batchId,
    required String status,
    String? note,
  });

  Future<void> deleteBatch(int batchId);

  Future<List<MaterialMovementEntity>> getMovements({String? type});
}

class MaterialBatchRemoteDataSourceImpl implements MaterialBatchRemoteDataSource {
  final Dio dio;

  MaterialBatchRemoteDataSourceImpl(this.dio);

  @override
  Future<List<MaterialBatchModel>> getBatches({
    String? search,
    String? status,
    String? type,
    int? locationId,
  }) async {
    final queryParameters = <String, dynamic>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }

    if (type != null && type.trim().isNotEmpty) {
      queryParameters['type'] = type.trim();
    }

    if (locationId != null) {
      queryParameters['location_id'] = locationId;
    }

    final response = await dio.get(
      '/batches',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final data = response.data as List<dynamic>;

    return data.map((item) => MaterialBatchModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<MaterialBatchModel> getBatchByCode(String batchCode) async {
    final response = await dio.get('/batches/$batchCode');

    return MaterialBatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MaterialBatchModel?> suggestExisting({
    int? materialId,
    required String type,
    required int locationId,
  }) async {
    final response = await dio.get(
      '/batches/suggest',
      queryParameters: {
        if (materialId != null) 'material_id': materialId,
        'type': type,
        'location_id': locationId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final batchJson = data['batch'] as Map<String, dynamic>?;

    return batchJson == null ? null : MaterialBatchModel.fromJson(batchJson);
  }

  @override
  Future<MaterialBatchModel> receiveMaterial({
    required int materialId,
    required int quantity,
    required int locationId,
    int? targetBatchId,
    String? note,
  }) async {
    final response = await dio.post(
      '/batches/receive-material',
      data: {
        'material_id': materialId,
        'quantity': quantity,
        'location_id': locationId,
        'target_batch_id': targetBatchId,
        'note': note,
      },
    );

    return MaterialBatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MaterialBatchModel> receiveWaste({
    required int quantity,
    double? weight,
    required int locationId,
    int? targetBatchId,
    String? note,
  }) async {
    final response = await dio.post(
      '/batches/receive-waste',
      data: {
        'quantity': quantity,
        'weight': weight,
        'location_id': locationId,
        'target_batch_id': targetBatchId,
        'note': note,
      },
    );

    return MaterialBatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MaterialBatchModel> issueBatch({
    required int batchId,
    required int quantity,
    String? destination,
    String? note,
  }) async {
    final response = await dio.post(
      '/batches/$batchId/issue',
      data: {
        'quantity': quantity,
        'destination': destination,
        'note': note,
      },
    );

    return MaterialBatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MaterialBatchModel> updateBatchStatus({
    required int batchId,
    required String status,
    String? note,
  }) async {
    final response = await dio.post(
      '/batches/$batchId/status',
      data: {
        'status': status,
        'note': note,
      },
    );

    return MaterialBatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBatch(int batchId) async {
    await dio.delete('/batches/$batchId');
  }

  @override
  Future<List<MaterialMovementEntity>> getMovements({String? type}) async {
    final response = await dio.get(
      '/movements',
      queryParameters: type == null ? null : {'type': type},
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>;

    return items.map((e) => MaterialMovementModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}