import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/city_suggestion.dart';

/// The city explicitly chosen via search, overriding the device's current
/// location for weather/forecast lookups. Starts as the last searched city
/// saved by an earlier session, if any, so that city's weather is fetched
/// fresh without asking the device for a location. With nothing saved
/// (first launch) it starts as `null`, which means nothing is selected: the
/// device's current location is used.
class SelectedCityNotifier extends Notifier<CitySuggestion?> {
  @override
  CitySuggestion? build() => ref.read(lastSearchedCityStoreProvider).read();

  /// Selects [city]. Only cities the user typed a search for should be
  /// [remember]ed for the next launch; picking a favorite, say, is
  /// navigation, not a search, and must not replace the last searched city.
  void select(CitySuggestion city, {bool remember = false}) {
    state = city;
    if (remember) ref.read(lastSearchedCityStoreProvider).write(city);
  }

  void useDeviceLocation() => state = null;
}

final selectedCityProvider =
    NotifierProvider<SelectedCityNotifier, CitySuggestion?>(
      SelectedCityNotifier.new,
    );
