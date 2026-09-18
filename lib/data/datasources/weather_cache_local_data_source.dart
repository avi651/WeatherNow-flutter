/// Common contract for on-device weather/forecast cache storage,
/// implemented by [HiveWeatherCacheDataSource]. Kept as its own interface
/// so [WeatherCacheRepositoryImpl] doesn't depend on Hive directly and can
/// be tested with a fake.
abstract class WeatherCacheLocalDataSource {
  Map<String, dynamic>? getCurrentWeather(String key);

  Future<void> putCurrentWeather(String key, Map<String, dynamic> value);

  Map<String, dynamic>? getForecast(String key);

  Future<void> putForecast(String key, Map<String, dynamic> value);
}
