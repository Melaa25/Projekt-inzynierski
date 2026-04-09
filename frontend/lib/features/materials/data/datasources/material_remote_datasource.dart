import 'package:dio/dio.dart';

import '../models/material_model.dart';

abstract class MaterialRemoteDataSource {
  Future<List<MaterialModel>> getMaterials();

  Future<MaterialModel> createMaterial({
    required String name,
    required String serialNumber,
    required double weight,
    required double length,
    String? location,
  });

  Future<MaterialModel> updateMaterial({
    required int id,
    required String name,
    required String serialNumber,
    required double weight,
    required double length,
    String? location,
  });

  Future<void> deleteMaterial(int id);
}

class MaterialRemoteDataSourceImpl implements MaterialRemoteDataSource {
  final Dio dio;

  MaterialRemoteDataSourceImpl(this.dio);

  @override
  Future<List<MaterialModel>> getMaterials() async {
    final Response<dynamic> response = await dio.get('/materials');

    final List<dynamic> data = response.data as List<dynamic>;

    return data
        .map((item) => MaterialModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MaterialModel> createMaterial({
    required String name,
    required String serialNumber,
    required double weight,
    required double length,
    String? location,
  }) async {
    final Response<dynamic> response = await dio.post(
      '/materials',
      data: {
        'name': name,
        'serial_number': serialNumber,
        'weight': weight,
        'length': length,
        'location': location,
      },
    );

    return MaterialModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MaterialModel> updateMaterial({
    required int id,
    required String name,
    required String serialNumber,
    required double weight,
    required double length,
    String? location,
  }) async {
    final Response<dynamic> response = await dio.put(
      '/materials/$id',
      data: {
        'name': name,
        'serial_number': serialNumber,
        'weight': weight,
        'length': length,
        'location': location,
      },
    );

    return MaterialModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteMaterial(int id) async {
    await dio.delete('/materials/$id');
  }
}
