import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/offline/api_cache.dart';
import '../core/offline/connectivity_service.dart';
import '../core/offline/offline_queue.dart';
import '../core/offline/pending_operation.dart';
import 'auth_service.dart';
import 'material_batch_remote_data_source.dart';

/// Wysyla na serwer operacje wykonane bez internetu.
class SyncService extends ChangeNotifier {
  final Dio dio;
  final OfflineQueue queue;
  final ApiCache cache;
  final ConnectivityService connectivity;
  final AuthService authService;
  final MaterialBatchRemoteDataSource batchRemoteDataSource;

  bool _isSyncing = false;
  String? _lastResultMessage;

  SyncService(
    this.dio,
    this.queue,
    this.cache,
    this.connectivity,
    this.authService,
    this.batchRemoteDataSource,
  );

  bool get isSyncing => _isSyncing;

  int get pendingCount => queue.pendingCount;

  int get failedCount => queue.failedCount;

  String? get lastResultMessage => _lastResultMessage;

  List<PendingOperation> get operations => queue.readAll();

  /// Wysyla kolejke po kolei. Kolejnosc jest wazna, wiec przy braku sieci
  /// przerywamy i probujemy ponownie pozniej.
  Future<void> syncNow() async {
    if (_isSyncing) {
      return;
    }

    if (!authService.isAuthenticated) {
      return;
    }

    final operations = queue.readAll().where((operation) => !operation.isFailed).toList();

    if (operations.isEmpty) {
      return;
    }

    final isOnline = await connectivity.checkNow();

    if (!isOnline) {
      return;
    }

    _isSyncing = true;
    _lastResultMessage = null;
    notifyListeners();

    var sentCount = 0;
    var failedCount = 0;

    for (final operation in operations) {
      try {
        await dio.post(operation.endpoint, data: operation.payload);
        await queue.remove(operation.id);
        sentCount++;
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          // Siec padla w trakcie - reszta kolejki poczeka na nastepna probe.
          connectivity.reportFailure();
          break;
        }

        // Serwer odrzucil operacje (np. ktos w miedzyczasie wydal ten material).
        await queue.markFailed(operation.id, _mapDioError(e));
        failedCount++;
      } catch (_) {
        await queue.markFailed(operation.id, 'Nieoczekiwany błąd podczas wysyłania.');
        failedCount++;
      }
    }

    // Po wyslaniu pobieramy aktualny stan z serwera, zeby kopia lokalna
    // miala prawdziwe numery partii zamiast tymczasowych kodow OFF-.
    if (sentCount > 0) {
      try {
        final raw = await batchRemoteDataSource.getBatchesRaw();
        await cache.saveList(ApiCache.batchesKey, raw);
      } catch (_) {
        // Odswiezenie sie nie udalo - dane pobiora sie przy nastepnym wejsciu na liste.
      }
    }

    _isSyncing = false;

    if (sentCount > 0 && failedCount == 0) {
      _lastResultMessage = 'Zsynchronizowano $sentCount operacji.';
    } else if (failedCount > 0) {
      _lastResultMessage = 'Zsynchronizowano $sentCount, odrzucono $failedCount.';
    }

    notifyListeners();
  }

  /// Ponawia operacje odrzucona wczesniej przez serwer.
  Future<void> retryOperation(String id) async {
    await queue.retry(id);
    notifyListeners();
    await syncNow();
  }

  /// Usuwa operacje z kolejki bez wysylania (uzytkownik rezygnuje).
  Future<void> discardOperation(String id) async {
    await queue.remove(id);
    notifyListeners();
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.unknown;
  }

  String _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    return 'Serwer odrzucił operację (kod ${e.response?.statusCode ?? '?'}).';
  }
}