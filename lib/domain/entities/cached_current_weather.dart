import 'current_weather.dart';

/// A [CurrentWeather] snapshot as it was last persisted locally, along with
/// the metadata needed to show it as a stand-in for a live fetch: the city
/// it was fetched for, and when.
class CachedCurrentWeather {
  const CachedCurrentWeather({
    required this.weather,
    required this.fetchedAt,
    this.cityName,
    this.country,
  });

  final CurrentWeather weather;
  final DateTime fetchedAt;
  final String? cityName;
  final String? country;
}
