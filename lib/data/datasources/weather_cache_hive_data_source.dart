import 'package:hive_flutter/hive_flutter.dart';

import 'weather_cache_local_data_source.dart';

/// Stores cached current-weather and forecast JSON in two Hive [Box]es —
/// separate boxes because [WeatherCacheRepositoryImpl] reads and writes
/// them independently (`HomeWeatherNotifier` and `HomeForecastNotifier`
/// fetch on their own schedules) — each entry keyed by [LocationCacheKey].
class HiveWeatherCacheDataSource implements WeatherCacheLocalDataSource {
  const HiveWeatherCacheDataSource({
    required Box<dynamic> currentWeatherBox,
    required Box<dynamic> forecastBox,
  }) : _currentWeatherBox = currentWeatherBox,
       _forecastBox = forecastBox;

  final Box<dynamic> _currentWeatherBox;
  final Box<dynamic> _forecastBox;

  @override
  Map<String, dynamic>? getCurrentWeather(String key) {
    final raw = _currentWeatherBox.get(key);
    return raw == null ? null : Map<String, dynamic>.from(raw as Map);
  }

  @override
  Future<void> putCurrentWeather(String key, Map<String, dynamic> value) {
    return _currentWeatherBox.put(key, value);
  }

  @override
  Map<String, dynamic>? getForecast(String key) {
    final raw = _forecastBox.get(key);
    return raw == null ? null : Map<String, dynamic>.from(raw as Map);
  }

  @override
  Future<void> putForecast(String key, Map<String, dynamic> value) {
    return _forecastBox.put(key, value);
  }
}
