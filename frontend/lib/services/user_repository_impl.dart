import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../models/managed_user.dart';
import 'user_remote_data_source.dart';
import 'user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<ManagedUser>>> getUsers() async {
    try {
      final users = await remoteDataSource.getUsers();
      return Right(users);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystapil nieoczekiwany blad podczas pobierania uzytkownikow.');
    }
  }

  @override
  Future<Either<String, ManagedUser>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final user = await remoteDataSource.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      return Right(user);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystapil nieoczekiwany blad podczas tworzenia uzytkownika.');
    }
  }

  @override
  Future<Either<String, ManagedUser>> updateUser({
    required int id,
    String? name,
    String? email,
    String? password,
    String? role,
  }) async {
    try {
      final user = await remoteDataSource.updateUser(
        id: id,
        name: name,
        email: email,
        password: password,
        role: role,
      );
      return Right(user);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystapil nieoczekiwany blad podczas edycji uzytkownika.');
    }
  }

  @override
  Future<Either<String, bool>> deleteUser(int id) async {
    try {
      await remoteDataSource.deleteUser(id);
      return const Right(true);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystapil nieoczekiwany blad podczas usuwania uzytkownika.');
    }
  }

  String _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    return 'Blad API: ${e.response?.statusCode ?? 'brak kodu'}';
  }
}
