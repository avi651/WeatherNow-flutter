class WeatherApiParams {
  const WeatherApiParams._();

  static Map<String, dynamic> coordinates({
    required double latitude,
    required double longitude,
    required String apiKey,
  }) {
    return {
      'lat': latitude,
      'lon': longitude,
      'appid': apiKey,
      'units': 'metric',
    };
  }
}
