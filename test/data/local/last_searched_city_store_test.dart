import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:weather_now_flutter/data/local/hive_boxes.dart';
import 'package:weather_now_flutter/data/local/last_searched_city_store.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';

/// Exercises [LastSearchedCityStore] against a real (test-only) Hive box —
/// plain `test()`, not `testWidgets()`, because real box writes never
/// resolve under fake async (see `flutter_test_config.dart`).
void main() {
  const pune = CitySuggestion(
    name: 'Pune',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 18.5213738,
    longitude: 73.8545071,
  );

  late Box<dynamic> box;
  late LastSearchedCityStore store;

  setUp(() {
    box = Hive.box(HiveBoxes.settings);
    store = LastSearchedCityStore(box: box);
  });

  test('reads null when nothing was saved', () {
    expect(store.read(), isNull);
  });

  test('write then read returns the saved city', () async {
    await store.write(pune);

    expect(store.read(), pune);
  });

  test('a saved city survives a fresh store over the same box', () async {
    await store.write(pune);

    expect(
      LastSearchedCityStore(box: Hive.box(HiveBoxes.settings)).read(),
      pune,
    );
  });

  test('clear forgets the saved city', () async {
    await store.write(pune);

    await store.clear();

    expect(store.read(), isNull);
  });

  test('clear on an empty store is a no-op', () async {
    await store.clear();

    expect(store.read(), isNull);
  });

  test('a corrupt entry reads as no saved city instead of throwing', () async {
    await box.put('lastSearchedCity', 'not a map');

    expect(store.read(), isNull);
  });

  test('does not touch other settings stored in the same box', () async {
    await box.put('unrelated', 'kept');
    await store.write(pune);

    await store.clear();

    expect(box.get('unrelated'), 'kept');
  });
}
