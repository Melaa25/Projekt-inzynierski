import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../services/material_type_remote_data_source.dart';
import '../../services/material_type_repository.dart';
import '../../services/material_type_repository_impl.dart';
import '../../services/material_batch_remote_data_source.dart';
import '../../services/material_batch_repository.dart';
import '../../services/material_batch_repository_impl.dart';
import '../../services/location_remote_data_source.dart';
import '../../services/location_repository.dart';
import '../../services/location_repository_impl.dart';
import '../../services/auth_service.dart';
import '../../services/user_remote_data_source.dart';
import '../../services/user_repository.dart';
import '../../services/user_repository_impl.dart';
import '../network/dio_client.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  getIt.registerLazySingleton<DioClient>(DioClient.new);
  getIt.registerLazySingleton<Dio>(() => getIt<DioClient>().dio);

  getIt.registerLazySingleton<AuthService>(() => AuthService(getIt<Dio>()));

  getIt.registerLazySingleton<MaterialTypeRemoteDataSource>(
    () => MaterialTypeRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<MaterialTypeRepository>(
    () => MaterialTypeRepositoryImpl(getIt<MaterialTypeRemoteDataSource>()),
  );

  getIt.registerLazySingleton<MaterialBatchRemoteDataSource>(
    () => MaterialBatchRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<MaterialBatchRepository>(
    () => MaterialBatchRepositoryImpl(getIt<MaterialBatchRemoteDataSource>()),
  );

  getIt.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(getIt<LocationRemoteDataSource>()),
  );

  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(getIt<UserRemoteDataSource>()),
  );
}