import 'package:dio/dio.dart';

import '../models/material_model.dart';

abstract class MaterialRemoteDataSource {
  Future<List<MaterialModel>> getMaterials();

  Future<MaterialModel> createMaterial({
    required String name,
    required double weight,
    required double length,
    String? location,
    int? currentLocationId,
    required String status,
  });

  Future<MaterialModel> updateMaterial({
    required int id,
    required String name,
    required double weight,
    required double length,
    String? location,
    int? currentLocationId,
    required String status,
  });

  Future<void> deleteMaterial(int id);

  Future<MaterialModel> recordMovement({
    required int materialId,
    required String type,
    String? destination,
    String? note,
    int? newLocationId,
  });
}

class MaterialRemoteDataSourceImpl implements MaterialRemoteDataSource {
  final Dio dio;

  MaterialRemoteDataSourceImpl(this.dio);

  @override
  Future<List<MaterialModel>> getMaterials() async {
    final Response<dynamic> response = await dio.get('/materials');

    final List<dynamic> data = response.data as List<dynamic>;

    return data.map((item) => MaterialModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<MaterialModel> createMaterial({
    required String name,
    required double weight,
    required double length,
    String? location,
    int? currentLocationId,
    required String status,
  }) async {
    final Response<dynamic> response = await dio.post(
      '/materials',
      data: {
        'name': name,
        'weight': weight,
        'length': length,
        'location': location,
        'current_location_id': currentLocationId,
        'status': status,
      },
    );

    return MaterialModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MaterialModel> updateMaterial({
    required int id,
    required String name,
    required double weight,
    required double length,
    String? location,
    int? currentLocationId,
    required String status,
  }) async {
    final Response<dynamic> response = await dio.put(
      '/materials/$id',
      data: {
        'name': name,
        'weight': weight,
        'length': length,
        'location': location,
        'current_location_id': currentLocationId,
        'status': status,
      },
    );

    return MaterialModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteMaterial(int id) async {
    await dio.delete('/materials/$id');
  }

  @override
  Future<MaterialModel> recordMovement({
    required int materialId,
    required String type,
    String? destination,
    String? note,
    int? newLocationId,
  }) async {
    final Response<dynamic> response = await dio.post(
      '/materials/$materialId/movements',
      data: {
        'type': type,
        'destination': destination,
        'note': note,
        'new_location_id': newLocationId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return MaterialModel.fromJson(data['material'] as Map<String, dynamic>);
  }
}