import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/city_suggestion.dart';
import 'current_location_provider.dart';

/// Reverse-geocodes [currentLocationProvider]'s coordinates into a
/// display-ready [CitySuggestion], so the "use my location" flow can show
/// the device's actual city (e.g. "Pune") instead of a generic label.
///
/// Resolves to `null` — rather than throwing — when reverse geocoding
/// itself fails or finds nothing: the weather card and search bar fall
/// back to a generic "Current Location" label in that case, but the
/// weather/forecast fetch (driven by [activeLocationProvider], which only
/// needs coordinates) still succeeds independently of this provider.
///
/// `retry: null` for the same reason as [currentLocationProvider]: a
/// failure here isn't transient, and there's no user-facing retry
/// specifically for reverse geocoding — retrying the weather fetch already
/// re-resolves the device location this depends on.
final currentLocationCityProvider = FutureProvider<CitySuggestion?>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  final reverseGeocode = ref.watch(reverseGeocodeProvider);
  final result = await reverseGeocode(
    latitude: location.latitude,
    longitude: location.longitude,
  );

  return result.fold((failure) => null, (city) => city);
}, retry: (retryCount, error) => null);
