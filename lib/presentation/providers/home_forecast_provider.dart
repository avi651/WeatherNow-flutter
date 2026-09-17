import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/forecast.dart';
import 'active_location_provider.dart';
import 'current_location_provider.dart';
import 'home_weather_exception.dart';

/// Fetches the forecast for [activeLocationProvider] — a searched city if
/// one is selected, otherwise the device's current location — through the
/// existing `GetForecast` use case. Mirrors [HomeWeatherNotifier]'s shape.
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
      (failure) => throw HomeWeatherFailureException(failure.message),
      (forecast) => forecast,
    );
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
