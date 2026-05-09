import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../services/material_remote_data_source.dart';
import '../../services/material_repository.dart';
import '../../services/material_repository_impl.dart';
import '../../services/location_remote_data_source.dart';
import '../../services/location_repository.dart';
import '../../services/location_repository_impl.dart';
import '../network/dio_client.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Rejestracja wszystkich zaleznosci aplikacji.
  getIt.registerLazySingleton<DioClient>(DioClient.new);
  getIt.registerLazySingleton<Dio>(() => getIt<DioClient>().dio);

  getIt.registerLazySingleton<MaterialRemoteDataSource>(
    () => MaterialRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<MaterialRepository>(
    () => MaterialRepositoryImpl(getIt<MaterialRemoteDataSource>()),
  );

  // Locations
  getIt.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(getIt<LocationRemoteDataSource>()),
  );
}
