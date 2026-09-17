import '../../../core/config/app_environment.dart';

/// OpenWeatherMap's Geocoding API lives under a different path root
/// (`geo/1.0`) than the weather/forecast endpoints (`data/2.5`, configured
/// as [AppEnvironment.baseUrl]) — so this is a full absolute URL rather
/// than a path appended to [ApiClient]'s configured base URL. [ApiClient]
/// forwards it to `Dio` as-is: `Dio` uses a path unchanged whenever it's
/// already an absolute URL, ignoring `baseUrl` for that one request.

class GeocodingApiEndpoints {
  const GeocodingApiEndpoints._();

  static String get directGeocoding =>
      '${AppEnvironment.geocodingBaseUrl}/direct';

  static String get reverseGeocoding =>
      '${AppEnvironment.geocodingBaseUrl}/reverse';
}
