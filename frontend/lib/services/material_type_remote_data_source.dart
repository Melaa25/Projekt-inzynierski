import 'package:dio/dio.dart';

import '../models/material_type_model.dart';

abstract class MaterialTypeRemoteDataSource {
  Future<List<MaterialTypeModel>> getMaterialTypes({String? search});

  Future<MaterialTypeModel> createMaterialType({
    required String name,
    required double weight,
    required double length,
    required double thickness,
  });

  Future<MaterialTypeModel> updateMaterialType({
    required int id,
    required String name,
    required double weight,
    required double length,
    required double thickness,
  });

  Future<void> deleteMaterialType(int id);
}

class MaterialTypeRemoteDataSourceImpl implements MaterialTypeRemoteDataSource {
  final Dio dio;

  MaterialTypeRemoteDataSourceImpl(this.dio);

  @override
  Future<List<MaterialTypeModel>> getMaterialTypes({String? search}) async {
    final response = await dio.get(
      '/materials',
      queryParameters: (search == null || search.trim().isEmpty) ? null : {'search': search.trim()},
    );

    final data = response.data as List<dynamic>;

    return data.map((item) => MaterialTypeModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<MaterialTypeModel> createMaterialType({
    required String name,
    required double weight,
    required double length,
    required double thickness,
  }) async {
    final response = await dio.post(
      '/materials',
      data: {
        'name': name,
        'weight': weight,
        'length': length,
        'thickness': thickness,
      },
    );

    return MaterialTypeModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MaterialTypeModel> updateMaterialType({
    required int id,
    required String name,
    required double weight,
    required double length,
    required double thickness,
  }) async {
    final response = await dio.put(
      '/materials/$id',
      data: {
        'name': name,
        'weight': weight,
        'length': length,
        'thickness': thickness,
      },
    );

    return MaterialTypeModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteMaterialType(int id) async {
    await dio.delete('/materials/$id');
  }
}