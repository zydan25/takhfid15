import 'local_cache_io.dart'
    if (dart.library.html) 'local_cache_web.dart' as impl;

class LocalCache {
  final impl.LocalCacheImpl _impl = impl.LocalCacheImpl();

  Future<void> writeJson(String key, Object value) => _impl.writeJson(key, value);
  Future<dynamic> readJson(String key) => _impl.readJson(key);
  Future<void> delete(String key) => _impl.delete(key);
  Future<void> saveString(String key, String value) => _impl.saveString(key, value);
  Future<String?> readString(String key) => _impl.readString(key);
}
