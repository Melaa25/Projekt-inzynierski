import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/materials/presentation/bloc/materials_bloc.dart';
import 'features/materials/presentation/pages/materials_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MaterialsBloc>(
      create: (_) => getIt<MaterialsBloc>(),
      child: MaterialApp(
        title: 'Magazyn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MaterialsPage(),
      ),
    );
  }
}
