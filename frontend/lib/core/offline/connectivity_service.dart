import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Sprawdza, czy backend jest osiagalny.
/// Nie pyta systemu o WiFi, tylko realnie odpytuje endpoint /ping,
/// bo WiFi bez internetu to dla nas nadal tryb offline.
class ConnectivityService extends ChangeNotifier {
  final Dio dio;

  bool _isOnline = false;
  bool _isChecking = false;
  Timer? _timer;

  ConnectivityService(this.dio);

  bool get isOnline => _isOnline;

  bool get isChecking => _isChecking;

  /// Uruchamia cykliczne sprawdzanie co 15 sekund.
  void start() {
    checkNow();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => checkNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Jednorazowe sprawdzenie polaczenia. Zwraca true, gdy serwer odpowiedzial.
  Future<bool> checkNow() async {
    if (_isChecking) {
      return _isOnline;
    }

    _isChecking = true;

    bool online;

    try {
      final response = await dio.get(
        '/ping',
        options: Options(
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );

      online = response.statusCode == 200;
    } catch (_) {
      online = false;
    }

    _isChecking = false;

    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }

    return online;
  }

  /// Wywolywane, gdy zapytanie do API nie doszlo - nie czekamy wtedy
  /// na kolejny cykl timera, tylko od razu przelaczamy sie w tryb offline.
  void reportFailure() {
    if (_isOnline) {
      _isOnline = false;
      notifyListeners();
    }
  }

  /// Wywolywane, gdy zapytanie do API sie powiodlo.
  void reportSuccess() {
    if (!_isOnline) {
      _isOnline = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}