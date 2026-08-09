import 'package:dio/dio.dart';

import '../models/location_model.dart';

abstract class LocationRemoteDataSource {
  Future<List<LocationModel>> getLocations({String? type, int? parentId, bool onlyRoot = false});

  Future<LocationModel> createLocation({
    String? code,
    required String name,
    required String type,
    int? parentId,
    String? description,
  });

  Future<LocationModel> updateLocation({
    required int id,
    String? code,
    required String name,
    required String type,
    int? parentId,
    String? description,
  });

  Future<void> deleteLocation(int id);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final Dio dio;

  LocationRemoteDataSourceImpl(this.dio);

  @override
  Future<List<LocationModel>> getLocations({String? type, int? parentId, bool onlyRoot = false}) async {
    final params = <String, dynamic>{};

    if (type != null) {
      params['type'] = type;
    }

    if (onlyRoot) {
      params['parent_id'] = 'null';
    } else if (parentId != null) {
      params['parent_id'] = parentId;
    }

    final response = await dio.get('/locations', queryParameters: params);

    final data = response.data as List<dynamic>;

    return data.map((e) => LocationModel.fromJson(e)).toList();
  }

  @override
  Future<LocationModel> createLocation({
    String? code,
    required String name,
    required String type,
    int? parentId,
    String? description,
  }) async {
    final response = await dio.post('/locations', data: {
      'code': code,
      'name': name,
      'type': type,
      'parent_id': parentId,
      'description': description,
    });

    return LocationModel.fromJson(response.data);
  }

  @override
  Future<LocationModel> updateLocation({
    required int id,
    String? code,
    required String name,
    required String type,
    int? parentId,
    String? description,
  }) async {
    final response = await dio.put('/locations/$id', data: {
      'code': code,
      'name': name,
      'type': type,
      'parent_id': parentId,
      'description': description,
    });

    return LocationModel.fromJson(response.data);
  }

  @override
  Future<void> deleteLocation(int id) async {
    await dio.delete('/locations/$id');
  }
}