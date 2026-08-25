import 'local_storage.dart';
import 'pending_operation.dart';

/// Kolejka operacji wykonanych bez internetu, czekajacych na wyslanie.
/// Kolejnosc ma znaczenie - wydanie z partii utworzonej offline
/// musi trafic na serwer po jej przyjeciu.
class OfflineQueue {
  static const String queueKey = 'offline_queue';

  final LocalStorage localStorage;

  OfflineQueue(this.localStorage);

  List<PendingOperation> readAll() {
    final raw = localStorage.readJson(queueKey);

    if (raw is! List) {
      return [];
    }

    final operations = <PendingOperation>[];

    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        operations.add(PendingOperation.fromJson(item));
      }
    }

    return operations;
  }

  int get pendingCount {
    return readAll().where((operation) => !operation.isFailed).length;
  }

  int get failedCount {
    return readAll().where((operation) => operation.isFailed).length;
  }

  Future<void> add(PendingOperation operation) async {
    final operations = readAll();
    operations.add(operation);
    await _save(operations);
  }

  Future<void> remove(String id) async {
    final operations = readAll();
    operations.removeWhere((operation) => operation.id == id);
    await _save(operations);
  }

  Future<void> markFailed(String id, String message) async {
    final operations = readAll();

    for (var i = 0; i < operations.length; i++) {
      if (operations[i].id == id) {
        operations[i] = operations[i].copyWithFailure(message);
      }
    }

    await _save(operations);
  }

  Future<void> retry(String id) async {
    final operations = readAll();

    for (var i = 0; i < operations.length; i++) {
      if (operations[i].id == id) {
        operations[i] = operations[i].copyWithRetry();
      }
    }

    await _save(operations);
  }

  Future<void> _save(List<PendingOperation> operations) async {
    await localStorage.saveJson(
      queueKey,
      operations.map((operation) => operation.toJson()).toList(),
    );
  }
}