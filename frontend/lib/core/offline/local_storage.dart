import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

/// Prosta pamiec lokalna na urzadzeniu (klucz -> wartosc tekstowa).
/// Na Androidzie zapisuje do prywatnego katalogu aplikacji,
/// w przegladarce do IndexedDB. Wszystko trzymamy jako JSON.
class LocalStorage {
  static const String boxName = 'wms_offline';

  late Box<String> _box;

  /// Musi zostac wywolane raz, przy starcie aplikacji.
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(boxName);
  }

  Future<void> saveString(String key, String value) async {
    await _box.put(key, value);
  }

  String? readString(String key) {
    return _box.get(key);
  }

  /// Zapisuje mape lub liste jako tekst JSON.
  Future<void> saveJson(String key, Object value) async {
    await _box.put(key, jsonEncode(value));
  }

  /// Odczytuje wczesniej zapisany JSON. Zwraca null, gdy klucza nie ma
  /// albo gdy zapisane dane sa uszkodzone.
  dynamic readJson(String key) {
    final raw = _box.get(key);

    if (raw == null) {
      return null;
    }

    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  bool contains(String key) {
    return _box.containsKey(key);
  }

  /// Czysci cala pamiec lokalna (np. przy wylogowaniu).
  Future<void> clearAll() async {
    await _box.clear();
  }
}