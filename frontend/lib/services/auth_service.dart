import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/offline/local_storage.dart';
import '../models/auth_user.dart';

class AuthService extends ChangeNotifier {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  final Dio _dio;
  final LocalStorage _localStorage;

  String? _token;
  AuthUser? _currentUser;

  AuthService(this._dio, this._localStorage);

  AuthUser? get currentUser => _currentUser;

  bool get isAuthenticated => _token != null;

  bool get isAdmin => _currentUser?.role == 'admin';

  bool get mustChangePassword => _currentUser?.mustChangePassword ?? false;

  /// Odtwarza sesje zapisana na urzadzeniu. Wywolywane raz przy starcie aplikacji.
  /// Dzieki temu magazynier po restarcie aplikacji bez zasiegu nadal jest zalogowany.
  Future<void> restoreSession() async {
    final token = _localStorage.readString(tokenKey);
    final userJson = _localStorage.readJson(userKey);

    if (token == null || userJson is! Map<String, dynamic>) {
      return;
    }

    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _currentUser = AuthUser.fromJson(userJson);
    notifyListeners();

    // Jesli jest siec, odswiezamy dane uzytkownika.
    try {
      final response = await _dio.get('/auth/me');
      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);

      _currentUser = user;
      await _localStorage.saveJson(userKey, user.toJson());
      notifyListeners();
    } on DioException catch (e) {
      // 401 znaczy, ze token zostal uniewazniony na serwerze - trzeba sie zalogowac ponownie.
      if (e.response?.statusCode == 401) {
        await _clearSession();
      }
      // Kazdy inny blad to najczesciej brak sieci - zostawiamy sesje z pamieci telefonu.
    } catch (_) {
      // Ignorujemy, sesja odtworzona lokalnie zostaje.
    }
  }

  Future<Either<String, AuthUser>> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'login': login, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (token == null || userJson == null) {
        return const Left('Nieprawidlowa odpowiedz serwera podczas logowania.');
      }

      _token = token;
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final user = AuthUser.fromJson(userJson);
      _currentUser = user;

      await _localStorage.saveString(tokenKey, token);
      await _localStorage.saveJson(userKey, user.toJson());

      notifyListeners();

      return Right(user);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystapil nieoczekiwany blad podczas logowania.');
    }
  }

  Future<Either<String, AuthUser>> changePassword({
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/password',
        data: {'password': password, 'password_confirmation': password},
      );

      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);
      _currentUser = user;

      await _localStorage.saveJson(userKey, user.toJson());

      notifyListeners();

      return Right(user);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystapil nieoczekiwany blad podczas zmiany hasla.');
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await _dio.post('/auth/logout');
      }
    } catch (_) {
      // Swallow backend errors on logout and clear client state anyway.
    } finally {
      await _clearSession();
    }
  }

  Future<Either<String, AuthUser>> fetchCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);

      _currentUser = user;
      await _localStorage.saveJson(userKey, user.toJson());

      notifyListeners();
      return Right(user);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Nie udalo sie pobrac danych uzytkownika.');
    }
  }

  Future<void> _clearSession() async {
    _token = null;
    _currentUser = null;
    _dio.options.headers.remove('Authorization');

    await _localStorage.remove(tokenKey);
    await _localStorage.remove(userKey);

    notifyListeners();
  }

  String _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Brak polaczenia z serwerem.';
    }

    return 'Wystapil blad polaczenia z API.';
  }
}