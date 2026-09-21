import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalCacheImpl {
  Future<Directory> get _directory async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(root.path + '/takhfid_cache');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> _file(String key) async {
    return File((await _directory).path + '/' + key + '.json');
  }

  Future<void> writeJson(String key, Object value) async {
    try {
      final file = await _file(key);
      final temp = File(file.path + '.tmp');
      await temp.writeAsString(jsonEncode(value), flush: true);
      if (file.existsSync()) await file.delete();
      await temp.rename(file.path);
    } catch (_) {}
  }

  Future<dynamic> readJson(String key) async {
    try {
      final file = await _file(key);
      if (!file.existsSync()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      final file = await _file(key);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  Future<void> saveString(String key, String value) => writeJson(key, value);

  Future<String?> readString(String key) async {
    final value = await readJson(key);
    return value is String ? value : null;
  }
}
