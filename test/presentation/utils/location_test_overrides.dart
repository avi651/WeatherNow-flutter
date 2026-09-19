import 'package:flutter_riverpod/misc.dart';
import 'package:weather_now_flutter/data/local/last_searched_city_store.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';

/// In-memory stand-in for [LastSearchedCityStore]: a real Hive write never
/// resolves under `testWidgets`' fake-async clock.
class FakeLastSearchedCityStore implements LastSearchedCityStore {
  FakeLastSearchedCityStore([this.city]);

  CitySuggestion? city;

  @override
  CitySuggestion? read() => city;

  @override
  Future<void> write(CitySuggestion value) async => city = value;
}

/// Startup-related overrides: an in-memory last-searched-city store,
/// optionally pre-filled with [lastSearchedCity].
List<Override> locationTestOverrides({
  CitySuggestion? lastSearchedCity,
  LastSearchedCityStore? store,
}) {
  return [
    lastSearchedCityStoreProvider.overrideWithValue(
      store ?? FakeLastSearchedCityStore(lastSearchedCity),
    ),
  ];
}
