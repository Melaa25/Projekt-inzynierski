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
import '../../services/report_remote_data_source.dart';
import '../../services/report_repository.dart';
import '../../services/report_repository_impl.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../services/user_remote_data_source.dart';
import '../../services/user_repository.dart';
import '../../services/user_repository_impl.dart';
import '../network/dio_client.dart';
import '../offline/api_cache.dart';
import '../offline/connectivity_service.dart';
import '../offline/local_storage.dart';
import '../offline/offline_queue.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Pamiec lokalna musi byc gotowa zanim powstana serwisy, ktore z niej korzystaja.
  final localStorage = LocalStorage();
  await localStorage.init();
  getIt.registerSingleton<LocalStorage>(localStorage);

  getIt.registerLazySingleton<ApiCache>(() => ApiCache(getIt<LocalStorage>()));

  getIt.registerLazySingleton<OfflineQueue>(() => OfflineQueue(getIt<LocalStorage>()));

  getIt.registerLazySingleton<DioClient>(DioClient.new);
  getIt.registerLazySingleton<Dio>(() => getIt<DioClient>().dio);

  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(getIt<Dio>()),
  );

  getIt.registerLazySingleton<AuthService>(
    () => AuthService(getIt<Dio>(), getIt<LocalStorage>()),
  );

  getIt.registerLazySingleton<MaterialTypeRemoteDataSource>(
    () => MaterialTypeRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<MaterialTypeRepository>(
    () => MaterialTypeRepositoryImpl(
      getIt<MaterialTypeRemoteDataSource>(),
      getIt<ApiCache>(),
      getIt<ConnectivityService>(),
    ),
  );

  getIt.registerLazySingleton<MaterialBatchRemoteDataSource>(
    () => MaterialBatchRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<MaterialBatchRepository>(
    () => MaterialBatchRepositoryImpl(
      getIt<MaterialBatchRemoteDataSource>(),
      getIt<ApiCache>(),
      getIt<ConnectivityService>(),
      getIt<OfflineQueue>(),
    ),
  );

  getIt.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(
      getIt<LocationRemoteDataSource>(),
      getIt<ApiCache>(),
      getIt<ConnectivityService>(),
    ),
  );

  getIt.registerLazySingleton<ReportRemoteDataSource>(
    () => ReportRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(getIt<ReportRemoteDataSource>()),
  );

  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(getIt<UserRemoteDataSource>()),
  );

  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      getIt<Dio>(),
      getIt<OfflineQueue>(),
      getIt<ApiCache>(),
      getIt<ConnectivityService>(),
      getIt<AuthService>(),
      getIt<MaterialBatchRemoteDataSource>(),
    ),
  );
}