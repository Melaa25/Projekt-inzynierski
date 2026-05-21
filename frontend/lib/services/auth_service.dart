import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';

class AuthService extends ChangeNotifier {
  final Dio _dio;

  String? _token;
  AuthUser? _currentUser;

  AuthService(this._dio);

  AuthUser? get currentUser => _currentUser;

  bool get isAuthenticated => _token != null;

  bool get isAdmin => _currentUser?.role == 'admin';

  Future<Either<String, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
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
      notifyListeners();

      return Right(user);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystapil nieoczekiwany blad podczas logowania.');
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
      _token = null;
      _currentUser = null;
      _dio.options.headers.remove('Authorization');
      notifyListeners();
    }
  }

  Future<Either<String, AuthUser>> fetchCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);
      _currentUser = user;
      notifyListeners();
      return Right(user);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Nie udalo sie pobrac danych uzytkownika.');
    }
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
