import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/materials/data/datasources/material_remote_datasource.dart';
import '../../features/materials/data/repositories/material_repository_impl.dart';
import '../../features/materials/domain/repositories/material_repository.dart';
import '../../features/materials/domain/usecases/get_materials.dart';
import '../../features/materials/presentation/bloc/materials_bloc.dart';
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

  getIt.registerLazySingleton<GetMaterials>(
    () => GetMaterials(getIt<MaterialRepository>()),
  );

  getIt.registerFactory<MaterialsBloc>(
    () => MaterialsBloc(getIt<GetMaterials>()),
  );
}
