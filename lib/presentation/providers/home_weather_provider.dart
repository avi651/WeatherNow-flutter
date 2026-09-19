import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failures.dart';
import '../../core/location/device_location.dart';
import '../../di/providers.dart';
import '../../domain/entities/city_suggestion.dart';
import '../../domain/entities/current_weather.dart';
import 'active_city_provider.dart';
import 'active_location_provider.dart';
import 'cached_city_provider.dart';
import 'current_location_provider.dart';
import 'favorite_cached_weather_provider.dart';
import 'home_weather_exception.dart';
import 'offline_data_enabled_provider.dart';
import 'settings_provider.dart';
import 'weather_freshness_provider.dart';

/// Fetches the current weather for [activeLocationProvider] — a searched
/// city if one is selected, otherwise the device's current location —
/// through the existing `GetCurrentWeather` use case.
///
/// Built on [AsyncNotifier] rather than a hand-rolled loading/success/error
/// state: `AsyncValue` already models exactly those three states, and the
/// UI gets `.when(loading:, data:, error:)` for free.
///
/// A successful fetch is cached locally (see [weatherCacheRepositoryProvider])
/// so it can stand in for a live fetch later; a failed fetch falls back to
/// that cache instead of failing outright when one exists for this
/// location — [currentWeatherFreshnessProvider] records which happened so
/// the UI can show a "showing cached data" indicator. The cache itself is
/// never touched on failure, so a bad response can't clobber good cached
/// data.
class HomeWeatherNotifier extends AsyncNotifier<CurrentWeather> {
  @override
  Future<CurrentWeather> build() {
    // Turning Offline Data on while live data is already on screen stores
    // it right away instead of waiting for the next fetch. Turning it off
    // needs no reaction: every cache read/write re-checks the setting.
    ref.listen(offlineDataEnabledProvider, (previous, enabled) {
      if (previous == false && enabled) _persistLiveData();
    });
    return _fetch();
  }

  Future<CurrentWeather> _fetch() async {
    final location = await ref.watch(activeLocationProvider.future);
    final getCurrentWeather = ref.watch(getCurrentWeatherProvider);
    final result = await getCurrentWeather(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return result.fold(
      (failure) => _fallbackToCache(location, failure),
      (weather) => _cacheAndReport(location, weather),
    );
  }

  Future<CurrentWeather> _cacheAndReport(
    DeviceLocation location,
    CurrentWeather weather,
  ) async {
    final fetchedAt = DateTime.now();
    await _saveToCache(location, weather, fetchedAt);

    ref.read(cachedCityProvider.notifier).set(null);
    ref
        .read(currentWeatherFreshnessProvider.notifier)
        .report(WeatherFreshness(isFromCache: false, fetchedAt: fetchedAt));

    return weather;
  }

  /// Writes [weather] to the cache if — and only if — Offline Data is on.
  Future<void> _saveToCache(
    DeviceLocation location,
    CurrentWeather weather,
    DateTime fetchedAt,
  ) async {
    final settings = await ref.read(settingsProvider.future);
    if (!settings.offlineDataEnabled) return;

    final activeCity = await resolveActiveCity(ref);
    await ref
        .read(weatherCacheRepositoryProvider)
        .saveCurrentWeather(
          latitude: location.latitude,
          longitude: location.longitude,
          weather: weather,
          fetchedAt: fetchedAt,
          cityName: activeCity?.name,
          country: activeCity?.country,
        );
    // Favorites tiles read this cache; tell them it just changed.
    ref.invalidate(favoriteCachedWeatherProvider);
  }

  /// Stores the live weather already on screen (never a cached snapshot —
  /// that would re-stamp old data as fresh) after Offline Data is switched
  /// on, without refetching.
  Future<void> _persistLiveData() async {
    final weather = state.value;
    final freshness = ref.read(currentWeatherFreshnessProvider);
    if (weather == null || freshness == null || freshness.isFromCache) return;

    final location = await ref.read(activeLocationProvider.future);
    await _saveToCache(location, weather, freshness.fetchedAt);
  }

  /// Falls back to the last cached current weather for [location] when the
  /// live fetch fails. Re-throws the original [failure] — not a cache
  /// error — when there's nothing usable cached, so "never fetched before
  /// and offline" still surfaces as the normal error view. Skips the
  /// cache read entirely (surfacing [failure] the same way) when the user
  /// has turned offline data off — falling back to a stored snapshot
  /// would defeat that setting the same way writing one would.
  Future<CurrentWeather> _fallbackToCache(
    DeviceLocation location,
    Failure failure,
  ) async {
    final settings = await ref.read(settingsProvider.future);
    if (!settings.offlineDataEnabled) {
      throw HomeWeatherFailureException(failure.message);
    }

    final cached = await ref
        .read(weatherCacheRepositoryProvider)
        .getCurrentWeather(
          latitude: location.latitude,
          longitude: location.longitude,
        );

    final snapshot = cached.fold((_) => null, (snapshot) => snapshot);
    if (snapshot == null) {
      throw HomeWeatherFailureException(failure.message);
    }

    final cachedCityName = snapshot.cityName;
    ref
        .read(cachedCityProvider.notifier)
        .set(
          cachedCityName == null || cachedCityName.isEmpty
              ? null
              : CitySuggestion(
                  name: cachedCityName,
                  country: snapshot.country ?? '',
                  latitude: location.latitude,
                  longitude: location.longitude,
                ),
        );
    ref
        .read(currentWeatherFreshnessProvider.notifier)
        .report(
          WeatherFreshness(isFromCache: true, fetchedAt: snapshot.fetchedAt),
        );

    return snapshot.weather;
  }

  /// Re-runs the fetch, surfacing the same loading/data/error states as the
  /// initial load so the UI's existing `.when` handles retry for free.
  ///
  /// Also invalidates [currentLocationProvider] first: if the previous
  /// attempt failed because of a permission denial or disabled GPS, retry
  /// should re-attempt location resolution too, not just re-fetch weather
  /// for a location that never resolved. This only affects the device-GPS
  /// path — it's a no-op when a searched city is selected, since
  /// [activeLocationProvider] doesn't consult [currentLocationProvider] in
  /// that case.
  Future<void> retry() async {
    ref.invalidate(currentLocationProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// `retry: null` opts out of Riverpod's default exponential-backoff
/// auto-retry — see [currentLocationProvider] for why: [retry] above is
/// this app's deliberate, user-triggered retry path.
final homeWeatherProvider =
    AsyncNotifierProvider<HomeWeatherNotifier, CurrentWeather>(
      HomeWeatherNotifier.new,
      retry: (retryCount, error) => null,
    );
