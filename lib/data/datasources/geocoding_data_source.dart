/// Common contract for anything that can supply raw city-search JSON,
/// implemented by both [GeocodingApiService] (the real network source)
/// and [GeocodingMockDataSource] (a small bundled city list). Letting
/// `geocodingRepositoryProvider` depend on this instead of the concrete
/// [GeocodingApiService] type is what lets mock mode swap in
/// [GeocodingMockDataSource] without changing [GeocodingRepositoryImpl]
/// or its tests — mirrors [WeatherDataSource]'s role for weather/forecast.
abstract class GeocodingDataSource {
  Future<List<Map<String, dynamic>>> searchCities({required String query});

  /// Resolves raw JSON for the place nearest to [latitude]/[longitude] —
  /// used to turn the device's GPS coordinates into a display-ready city
  /// name for the "use my location" flow.
  Future<List<Map<String, dynamic>>> reverseGeocode({
    required double latitude,
    required double longitude,
  });
}
