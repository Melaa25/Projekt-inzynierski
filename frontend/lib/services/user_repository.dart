import 'package:dartz/dartz.dart';

import '../models/managed_user.dart';

abstract class UserRepository {
  Future<Either<String, List<ManagedUser>>> getUsers();

  Future<Either<String, ManagedUser>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  });

  Future<Either<String, ManagedUser>> updateUser({
    required int id,
    String? name,
    String? email,
    String? password,
    String? role,
  });

  Future<Either<String, bool>> deleteUser(int id);
}
