import 'package:dio/dio.dart';

import '../models/material_model.dart';

abstract class MaterialRemoteDataSource {
  Future<List<MaterialModel>> getMaterials();
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
}
