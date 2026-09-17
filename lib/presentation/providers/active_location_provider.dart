import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/device_location.dart';
import 'current_location_provider.dart';
import 'selected_city_provider.dart';

/// The coordinates to fetch weather for: the explicitly [selectedCityProvider]
/// city if one was chosen via search, otherwise [currentLocationProvider]'s
/// device location.
///
/// [HomeWeatherNotifier] and [HomeForecastNotifier] watch this instead of
/// [currentLocationProvider] directly, so selecting a search result
/// transparently redirects both without either needing to know about city
/// search at all.
///
/// `retry: null` opts out of Riverpod's default exponential-backoff
/// auto-retry, same as [currentLocationProvider] — without it, a location
/// failure would be silently retried by Riverpod for up to ~38 seconds
/// before surfacing, even though [currentLocationProvider] itself already
/// opted out.
final activeLocationProvider = FutureProvider<DeviceLocation>((ref) async {
  final selectedCity = ref.watch(selectedCityProvider);

  if (selectedCity != null) {
    return DeviceLocation(
      latitude: selectedCity.latitude,
      longitude: selectedCity.longitude,
    );
  }

  return ref.watch(currentLocationProvider.future);
}, retry: (retryCount, error) => null);
