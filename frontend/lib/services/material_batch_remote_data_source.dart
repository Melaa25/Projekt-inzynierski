import 'package:dio/dio.dart';

import '../models/material_batch_model.dart';
import '../models/material_movement_entity.dart';
import '../models/material_movement_model.dart';

abstract class MaterialBatchRemoteDataSource {
  /// Pobiera wszystkie partie bez filtrow - filtrowanie robimy w repozytorium,
  /// zeby dzialalo tak samo online i offline.
  Future<List<Map<String, dynamic>>> getBatchesRaw();

  Future<Map<String, dynamic>> getBatchRawByCode(String batchCode);

  Future<MaterialBatchModel?> suggestExisting({
    int? materialId,
    required String type,
    required int locationId,
  });

  Future<MaterialBatchModel> receiveMaterial(Map<String, dynamic> payload);

  Future<MaterialBatchModel> receiveWaste(Map<String, dynamic> payload);

  /// batchIdentifier to id z serwera albo client_uuid partii utworzonej offline.
  Future<MaterialBatchModel> issueBatch(String batchIdentifier, Map<String, dynamic> payload);

  Future<MaterialBatchModel> updateBatchStatus(String batchIdentifier, Map<String, dynamic> payload);

  Future<void> deleteBatch(int batchId);

  Future<List<MaterialMovementEntity>> getMovements({String? type});
}

class MaterialBatchRemoteDataSourceImpl implements MaterialBatchRemoteDataSource {
  final Dio dio;

  MaterialBatchRemoteDataSourceImpl(this.dio);

  @override
  Future<List<Map<String, dynamic>>> getBatchesRaw() async {
    final response = await dio.get('/batches');

    final data = response.data as List<dynamic>;

    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  @override
  Future<Map<String, dynamic>> getBatchRawByCode(String batchCode) async {
    final response = await dio.get('/batches/$batchCode');

    return response.data as Map<String, dynamic>;
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
  Future<MaterialBatchModel> receiveMaterial(Map<String, dynamic> payload) async {
    final response = await dio.post('/batches/receive-material', data: payload);

    return MaterialBatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MaterialBatchModel> receiveWaste(Map<String, dynamic> payload) async {
    final response = await dio.post('/batches/receive-waste', data: payload);

    return MaterialBatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MaterialBatchModel> issueBatch(String batchIdentifier, Map<String, dynamic> payload) async {
    final response = await dio.post('/batches/$batchIdentifier/issue', data: payload);

    return MaterialBatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MaterialBatchModel> updateBatchStatus(String batchIdentifier, Map<String, dynamic> payload) async {
    final response = await dio.post('/batches/$batchIdentifier/status', data: payload);

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