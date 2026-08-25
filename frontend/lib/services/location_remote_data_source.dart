import 'package:dio/dio.dart';

import '../models/location_model.dart';

abstract class LocationRemoteDataSource {
  /// Pobiera wszystkie lokalizacje - filtrowanie po typie i rodzicu
  /// odbywa sie w repozytorium, zeby dzialalo takze offline.
  Future<List<Map<String, dynamic>>> getLocationsRaw();

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
  Future<List<Map<String, dynamic>>> getLocationsRaw() async {
    final response = await dio.get('/locations');

    final data = response.data as List<dynamic>;

    return data.map((e) => e as Map<String, dynamic>).toList();
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