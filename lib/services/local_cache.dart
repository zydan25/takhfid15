import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalCache {
  String _key(String key) => 'takhfid_cache_$key';

  Future<void> writeJson(String key, Object value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(key), jsonEncode(value));
    } catch (_) {}
  }

  Future<dynamic> readJson(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(key));
      if (raw == null || raw.trim().isEmpty) return null;
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(key));
    } catch (_) {}
  }

  Future<void> saveString(String key, String value) => writeJson(key, value);

  Future<String?> readString(String key) async {
    final value = await readJson(key);
    return value is String ? value : null;
  }
}
