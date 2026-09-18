import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Metadata about a currently displayed piece of weather data: whether it
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

/// [HomeWeatherNotifier] and [HomeForecastNotifier] fetch independently and
/// can each succeed or fall back to cache on their own — one being stale
/// says nothing about the other. Kept as two separate providers (rather
/// than one shared one) so a live current-weather fetch can't silently
/// overwrite a stale, cached-fallback forecast's freshness, or vice versa.
///
/// `null` until the first fetch (fresh or cached) resolves.
final currentWeatherFreshnessProvider =
    NotifierProvider<WeatherFreshnessNotifier, WeatherFreshness?>(
  WeatherFreshnessNotifier.new,
);

/// See [currentWeatherFreshnessProvider] — the forecast's counterpart.
final forecastFreshnessProvider =
    NotifierProvider<WeatherFreshnessNotifier, WeatherFreshness?>(
  WeatherFreshnessNotifier.new,
);
