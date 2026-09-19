import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/city_suggestion.dart';

class CachedCityNotifier extends Notifier<CitySuggestion?> {
  @override
  CitySuggestion? build() => null;

  void set(CitySuggestion? city) => state = city;
}

/// The city name persisted alongside a cached weather snapshot, published by
/// [HomeWeatherNotifier] only while it is serving that snapshot as a
/// fallback for a failed live fetch (e.g. the device is offline).
///
/// Reverse geocoding needs the network, so offline the device-location flow
/// has no city of its own; [activeCityProvider] uses this as a last resort
/// so the Home screen shows the real cached city (e.g. "Pune") rather than
/// a generic "Current Location" label. `null` whenever data is live or the
/// snapshot never recorded a city.
final cachedCityProvider =
    NotifierProvider<CachedCityNotifier, CitySuggestion?>(
      CachedCityNotifier.new,
    );
