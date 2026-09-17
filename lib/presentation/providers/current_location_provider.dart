import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/device_location.dart';
import '../../di/providers.dart';
import 'home_weather_exception.dart';

/// Resolves the device's current location once and shares the result
/// with anything that watches it (both [HomeWeatherNotifier] and
/// [HomeForecastNotifier] depend on this, so the device is only asked
/// for its location once, not twice).
///
/// Throws [HomeWeatherFailureException] on failure — same convention as
/// the weather/forecast notifiers — so a location failure surfaces
/// through the same `AsyncValue.error` path as an API failure would.
///
/// `retry: null` opts out of Riverpod's default exponential-backoff
/// auto-retry: a denied/disabled-location failure is not transient, and
/// [HomeWeatherNotifier.retry]/[HomeForecastNotifier.retry] already give
/// the user an explicit way to try again. Without this, Riverpod silently
/// re-invokes [LocationService.getCurrentLocation] in the background for
/// up to ~38 seconds before letting the error through.
final currentLocationProvider = FutureProvider<DeviceLocation>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  final result = await locationService.getCurrentLocation();

  return result.fold(
    (failure) => throw HomeWeatherFailureException(failure.message),
    (location) => location,
  );
}, retry: (retryCount, error) => null);
