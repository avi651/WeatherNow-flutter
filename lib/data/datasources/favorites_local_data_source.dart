/// Common contract for on-device favorite-city storage, implemented by
/// [HiveFavoritesDataSource]. Kept as its own interface — mirroring
/// [WeatherDataSource]/[GeocodingDataSource] — so [FavoritesRepositoryImpl]
/// doesn't depend on Hive directly and can be tested with a fake.
abstract class FavoritesLocalDataSource {
  /// All saved favorites, as raw JSON maps keyed the same way
  /// [FavoritesLocalDataSource.put] stored them.
  List<Map<String, dynamic>> getAll();

  Future<void> put(String key, Map<String, dynamic> value);

  Future<void> delete(String key);
}
