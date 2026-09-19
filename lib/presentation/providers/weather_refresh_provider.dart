import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'current_location_provider.dart';
import 'home_forecast_provider.dart';
import 'home_weather_provider.dart';

/// Re-fetches Home's current weather and forecast from the API (which
/// re-caches them when Offline Data is on). Used when connectivity comes
/// back and when the app resumes while online.
///
/// Invalidates each provider exactly once, so every fetch happens once —
/// calling both notifiers' `retry()` would invalidate the device location
/// twice and make the first fetch restart. Data already on screen stays
/// visible while the refresh runs.
final refreshWeatherProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(currentLocationProvider);
    ref.invalidate(homeWeatherProvider);
    ref.invalidate(homeForecastProvider);

    try {
      await Future.wait([
        ref.read(homeWeatherProvider.future),
        ref.read(homeForecastProvider.future),
      ]);
    } catch (_) {
      // Failures surface through the providers' own error state.
    }
  };
});
