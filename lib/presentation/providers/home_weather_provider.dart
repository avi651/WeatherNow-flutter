import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/current_weather.dart';
import 'active_location_provider.dart';
import 'current_location_provider.dart';
import 'home_weather_exception.dart';

/// Fetches the current weather for [activeLocationProvider] — a searched
/// city if one is selected, otherwise the device's current location —
/// through the existing `GetCurrentWeather` use case.
///
/// Built on [AsyncNotifier] rather than a hand-rolled loading/success/error
/// state: `AsyncValue` already models exactly those three states, and the
/// UI gets `.when(loading:, data:, error:)` for free.
class HomeWeatherNotifier extends AsyncNotifier<CurrentWeather> {
  @override
  Future<CurrentWeather> build() => _fetch();

  Future<CurrentWeather> _fetch() async {
    final location = await ref.watch(activeLocationProvider.future);
    final getCurrentWeather = ref.watch(getCurrentWeatherProvider);
    final result = await getCurrentWeather(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return result.fold(
      (failure) => throw HomeWeatherFailureException(failure.message),
      (weather) => weather,
    );
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
