import 'forecast.dart';

/// A [Forecast] snapshot as it was last persisted locally, along with the
/// metadata needed to show it as a stand-in for a live fetch: the city it
/// was fetched for, and when.
class CachedForecast {
  const CachedForecast({
    required this.forecast,
    required this.fetchedAt,
    this.cityName,
    this.country,
  });

  final Forecast forecast;
  final DateTime fetchedAt;
  final String? cityName;
  final String? country;
}
