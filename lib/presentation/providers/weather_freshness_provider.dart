import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Metadata about the currently displayed weather/forecast: whether it
/// came from the local cache (because the live fetch failed — e.g. the
/// device is offline) or was just fetched, and when that data was
/// actually retrieved.
///
/// Kept as a small side channel set by [HomeWeatherNotifier] and
/// [HomeForecastNotifier] rather than folded into `CurrentWeather`/
/// `Forecast` themselves: those are pure domain entities and shouldn't
/// carry infrastructure concerns like "was this cached."
class WeatherFreshness {
  const WeatherFreshness({required this.isFromCache, required this.fetchedAt});

  final bool isFromCache;
  final DateTime fetchedAt;
}

class WeatherFreshnessNotifier extends Notifier<WeatherFreshness?> {
  @override
  WeatherFreshness? build() => null;

  void report(WeatherFreshness freshness) => state = freshness;
}

/// `null` until the first fetch (fresh or cached) resolves.
final weatherFreshnessProvider =
    NotifierProvider<WeatherFreshnessNotifier, WeatherFreshness?>(
  WeatherFreshnessNotifier.new,
);
