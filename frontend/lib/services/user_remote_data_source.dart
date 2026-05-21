import 'package:dio/dio.dart';

import '../models/managed_user.dart';

abstract class UserRemoteDataSource {
  Future<List<ManagedUser>> getUsers();

  Future<ManagedUser> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  });

  Future<ManagedUser> updateUser({
    required int id,
    String? name,
    String? email,
    String? password,
    String? role,
  });

  Future<void> deleteUser(int id);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final Dio dio;

  UserRemoteDataSourceImpl(this.dio);

  @override
  Future<List<ManagedUser>> getUsers() async {
    final response = await dio.get('/users');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => ManagedUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ManagedUser> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await dio.post(
      '/users',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      },
    );

    return ManagedUser.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ManagedUser> updateUser({
    required int id,
    String? name,
    String? email,
    String? password,
    String? role,
  }) async {
    final response = await dio.put(
      '/users/$id',
      data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
        if (role != null) 'role': role,
      },
    );

    return ManagedUser.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteUser(int id) async {
    await dio.delete('/users/$id');
  }
}
