/// Common contract for anything that can supply raw current-weather and
/// forecast JSON, implemented by both [WeatherApiService] (the real network
/// source) and [WeatherMockDataSource] (static bundled JSON). Letting
/// `weatherRepositoryProvider` depend on this instead of the concrete
/// [WeatherApiService] type is what lets mock mode swap in
/// [WeatherMockDataSource] without changing [WeatherRepositoryImpl] or its
/// tests.
abstract class WeatherDataSource {
  Future<Map<String, dynamic>> getCurrentWeather({
    required double latitude,
    required double longitude,
  });

  Future<Map<String, dynamic>> getForecast({
    required double latitude,
    required double longitude,
  });
}
