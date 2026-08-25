import 'package:flutter/material.dart';

import 'core/di/injection_container.dart';
import 'core/offline/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'views/auth/change_password_view.dart';
import 'views/auth/login_view.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();

  final authService = getIt<AuthService>();

  // Odtwarzamy sesje zapisana na urzadzeniu - dziala takze bez internetu.
  await authService.restoreSession();

  final connectivity = getIt<ConnectivityService>();
  final syncService = getIt<SyncService>();

  // Gdy polaczenie wroci, wysylamy zaleglosci automatycznie.
  connectivity.addListener(() {
    if (connectivity.isOnline) {
      syncService.syncNow();
    }
  });

  connectivity.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = getIt<AuthService>();

    Widget startView;

    if (!authService.isAuthenticated) {
      startView = const LoginView();
    } else if (authService.mustChangePassword) {
      startView = const ChangePasswordView();
    } else {
      startView = const HomeView();
    }

    return MaterialApp(
      title: 'Magazyn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: startView,
    );
  }
}