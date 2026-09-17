import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/city_suggestion.dart';

/// The city explicitly chosen via search, overriding the device's current
/// location for weather/forecast lookups. `null` means "use the device's
/// current location" — the app's default, and what "use my location"
/// resets back to.
class SelectedCityNotifier extends Notifier<CitySuggestion?> {
  @override
  CitySuggestion? build() => null;

  void select(CitySuggestion city) => state = city;

  void useDeviceLocation() => state = null;
}

final selectedCityProvider =
    NotifierProvider<SelectedCityNotifier, CitySuggestion?>(
  SelectedCityNotifier.new,
);
