import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/city_suggestion.dart';
import 'cached_city_provider.dart';
import 'current_location_city_provider.dart';
import 'selected_city_provider.dart';

/// The city to display in the search bar and weather card: the explicitly
/// [selectedCityProvider] city if one was chosen via search, otherwise the
/// device's reverse-geocoded [currentLocationCityProvider] city, and — when
/// that is unavailable, e.g. offline — the [cachedCityProvider] city stored
/// with the cached weather being shown.
///
/// `null` means there's nothing display-ready yet — no city was searched,
/// and the device's location either hasn't resolved yet or failed to
/// reverse-geocode — in which case callers fall back to a generic label
/// (e.g. "Current Location") while the weather itself is still fetched by
/// coordinates through [activeLocationProvider], independently of this.
final activeCityProvider = Provider<CitySuggestion?>((ref) {
  final selectedCity = ref.watch(selectedCityProvider);
  if (selectedCity != null) return selectedCity;

  return ref.watch(currentLocationCityProvider).value ??
      ref.watch(cachedCityProvider);
});

/// Like [activeCityProvider], but waits for the device-location city to
/// finish reverse geocoding instead of reading whatever has resolved so
/// far. Weather and reverse geocoding start in parallel, so a plain read at
/// cache-save time often sees `null` and would persist the snapshot with no
/// city name — leaving nothing to show later when offline.
Future<CitySuggestion?> resolveActiveCity(Ref ref) async {
  final selectedCity = ref.read(selectedCityProvider);
  if (selectedCity != null) return selectedCity;

  try {
    return await ref.read(currentLocationCityProvider.future);
  } catch (_) {
    return null;
  }
}
