import 'package:hive_flutter/hive_flutter.dart';

import 'favorites_local_data_source.dart';

/// Stores favorite cities in a Hive [Box], one entry per city keyed by its
/// [LocationCacheKey] so a favorite and its cached weather share a key.
class HiveFavoritesDataSource implements FavoritesLocalDataSource {
  const HiveFavoritesDataSource({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;

  @override
  List<Map<String, dynamic>> getAll() {
    return _box.values
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
  }

  @override
  Future<void> put(String key, Map<String, dynamic> value) {
    return _box.put(key, value);
  }

  @override
  Future<void> delete(String key) {
    return _box.delete(key);
  }
}
