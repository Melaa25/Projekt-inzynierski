import 'local_storage.dart';

/// Przechowuje kopie danych pobranych z API, zeby aplikacja dzialala bez internetu.
/// Zapisujemy surowy JSON z serwera - dzieki temu przy odczycie uzywamy
/// dokladnie tych samych klas fromJson co przy pobieraniu z sieci.
class ApiCache {
  static const String batchesKey = 'cache_batches';
  static const String locationsKey = 'cache_locations';
  static const String materialTypesKey = 'cache_material_types';
  static const String lastSyncKey = 'cache_last_sync';

  final LocalStorage localStorage;

  ApiCache(this.localStorage);

  /// Zapis danych swiezo pobranych z serwera - odswieza znacznik synchronizacji.
  Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    await localStorage.saveJson(key, items);
    await localStorage.saveString(lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Nadpisanie kopii lokalnej zmiana wykonana offline.
  /// Nie ruszamy znacznika synchronizacji, bo te dane nie pochodza z serwera.
  Future<void> replaceList(String key, List<Map<String, dynamic>> items) async {
    await localStorage.saveJson(key, items);
  }

  List<Map<String, dynamic>> readList(String key) {
    final raw = localStorage.readJson(key);

    if (raw is! List) {
      return const [];
    }

    return raw.whereType<Map<String, dynamic>>().toList();
  }

  bool hasData(String key) {
    return readList(key).isNotEmpty;
  }

  /// Kiedy ostatnio udalo sie pobrac dane z serwera.
  DateTime? get lastSyncAt {
    final raw = localStorage.readString(lastSyncKey);

    if (raw == null) {
      return null;
    }

    return DateTime.tryParse(raw);
  }
}