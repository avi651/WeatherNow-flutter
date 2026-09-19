import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failures.dart';
import '../../core/location/device_location.dart';
import '../../di/providers.dart';
import '../../domain/entities/forecast.dart';
import 'active_city_provider.dart';
import 'active_location_provider.dart';
import 'current_location_provider.dart';
import 'home_weather_exception.dart';
import 'settings_provider.dart';
import 'weather_freshness_provider.dart';

/// Fetches the forecast for [activeLocationProvider] — a searched city if
/// one is selected, otherwise the device's current location — through the
/// existing `GetForecast` use case. Mirrors [HomeWeatherNotifier]'s shape,
/// including caching a successful fetch and falling back to that cache
/// (rather than failing outright) when the live fetch fails but a cached
/// forecast exists for this location.
class HomeForecastNotifier extends AsyncNotifier<Forecast> {
  @override
  Future<Forecast> build() => _fetch();

  Future<Forecast> _fetch() async {
    final location = await ref.watch(activeLocationProvider.future);
    final getForecast = ref.watch(getForecastProvider);
    final result = await getForecast(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return result.fold(
      (failure) => _fallbackToCache(location, failure),
      (forecast) => _cacheAndReport(location, forecast),
    );
  }

  Future<Forecast> _cacheAndReport(
    DeviceLocation location,
    Forecast forecast,
  ) async {
    final fetchedAt = DateTime.now();
    final activeCity = ref.read(activeCityProvider);
    final settings = await ref.read(settingsProvider.future);

    if (settings.offlineDataEnabled) {
      await ref.read(weatherCacheRepositoryProvider).saveForecast(
            latitude: location.latitude,
            longitude: location.longitude,
            forecast: forecast,
            fetchedAt: fetchedAt,
            cityName: activeCity?.name,
            country: activeCity?.country,
          );
    }

    ref
        .read(forecastFreshnessProvider.notifier)
        .report(WeatherFreshness(isFromCache: false, fetchedAt: fetchedAt));

    return forecast;
  }

  /// Mirrors [HomeWeatherNotifier._fallbackToCache]: falls back to the last
  /// cached forecast for [location], or re-throws the original [failure]
  /// when there's nothing usable cached — or when offline data is off,
  /// without even reading the cache.
  Future<Forecast> _fallbackToCache(
    DeviceLocation location,
    Failure failure,
  ) async {
    final settings = await ref.read(settingsProvider.future);
    if (!settings.offlineDataEnabled) {
      throw HomeWeatherFailureException(failure.message);
    }

    final cached = await ref.read(weatherCacheRepositoryProvider).getForecast(
          latitude: location.latitude,
          longitude: location.longitude,
        );

    final snapshot = cached.fold((_) => null, (snapshot) => snapshot);
    if (snapshot == null) {
      throw HomeWeatherFailureException(failure.message);
    }

    ref.read(forecastFreshnessProvider.notifier).report(
          WeatherFreshness(isFromCache: true, fetchedAt: snapshot.fetchedAt),
        );

    return snapshot.forecast;
  }

  /// Re-runs the fetch, mirroring [HomeWeatherNotifier.retry] — including
  /// invalidating [currentLocationProvider] first.
  Future<void> retry() async {
    ref.invalidate(currentLocationProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// `retry: null` opts out of Riverpod's default exponential-backoff
/// auto-retry — see `currentLocationProvider` for why: [retry] above is
/// this app's deliberate, user-triggered retry path.
final homeForecastProvider = AsyncNotifierProvider<HomeForecastNotifier, Forecast>(
  HomeForecastNotifier.new,
  retry: (retryCount, error) => null,
);
