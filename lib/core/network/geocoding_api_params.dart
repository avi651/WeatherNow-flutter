class GeocodingApiParams {
  const GeocodingApiParams._();

  static Map<String, dynamic> search({
    required String query,
    required String apiKey,
    int limit = 5,
  }) {
    return {'q': query, 'limit': limit, 'appid': apiKey};
  }

  static Map<String, dynamic> reverse({
    required double latitude,
    required double longitude,
    required String apiKey,
    int limit = 1,
  }) {
    return {'lat': latitude, 'lon': longitude, 'limit': limit, 'appid': apiKey};
  }
}
