import 'package:dio/dio.dart';

import '../models/location_model.dart';

abstract class LocationRemoteDataSource {
  Future<List<LocationModel>> getLocations();

  Future<LocationModel> createLocation({
    String? code,
    required String name,
    String? type,
    int? parentId,
    String? description,
  });

  Future<LocationModel> updateLocation({
    required int id,
    String? code,
    required String name,
    String? type,
    int? parentId,
    String? description,
  });

  Future<void> deleteLocation(int id);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final Dio dio;

  LocationRemoteDataSourceImpl(this.dio);

  @override
  Future<List<LocationModel>> getLocations() async {
    final response = await dio.get('/locations');

    final data = response.data as List<dynamic>;

    return data.map((e) => LocationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<LocationModel> createLocation({String? code, required String name, String? type, int? parentId, String? description}) async {
    final response = await dio.post('/locations', data: {
      'code': code,
      'name': name,
      'type': type,
      'parent_id': parentId,
      'description': description,
    });

    return LocationModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LocationModel> updateLocation({required int id, String? code, required String name, String? type, int? parentId, String? description}) async {
    final response = await dio.put('/locations/$id', data: {
      'code': code,
      'name': name,
      'type': type,
      'parent_id': parentId,
      'description': description,
    });

    return LocationModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteLocation(int id) async {
    await dio.delete('/locations/$id');
  }
}
