import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:weather_now_flutter/data/datasources/favorites_hive_data_source.dart';
import 'package:weather_now_flutter/data/local/hive_boxes.dart';

/// Exercises [HiveFavoritesDataSource] against a real (test-only) Hive box
/// — `test/flutter_test_config.dart` opens it against a throwaway temp
/// directory and clears it before every test. Plain `test()`, not
/// `testWidgets()`: a real Hive box *write* never resolves under
/// `testWidgets`' fake-async pump clock.
void main() {
  late Box<dynamic> box;
  late HiveFavoritesDataSource dataSource;

  setUp(() {
    box = Hive.box(HiveBoxes.favorites);
    dataSource = HiveFavoritesDataSource(box: box);
  });

  test('getAll is empty for a fresh box', () {
    expect(dataSource.getAll(), isEmpty);
  });

  test('put then getAll returns the saved entry', () async {
    await dataSource.put('key1', {
      'name': 'Pune',
      'country': 'IN',
      'lat': 18.5,
      'lon': 73.8,
    });

    final all = dataSource.getAll();
    expect(all, hasLength(1));
    expect(all.single['name'], 'Pune');
  });

  test('put with the same key overwrites the previous value', () async {
    await dataSource.put('key1', {
      'name': 'Pune',
      'country': 'IN',
      'lat': 18.5,
      'lon': 73.8,
    });
    await dataSource.put('key1', {
      'name': 'Mumbai',
      'country': 'IN',
      'lat': 19.0,
      'lon': 72.8,
    });

    final all = dataSource.getAll();
    expect(all, hasLength(1));
    expect(all.single['name'], 'Mumbai');
  });

  test('delete removes the entry', () async {
    await dataSource.put('key1', {
      'name': 'Pune',
      'country': 'IN',
      'lat': 18.5,
      'lon': 73.8,
    });

    await dataSource.delete('key1');

    expect(dataSource.getAll(), isEmpty);
  });

  test(
    'a saved entry survives a fresh data source over the same box',
    () async {
      await dataSource.put('key1', {
        'name': 'Pune',
        'country': 'IN',
        'lat': 18.5,
        'lon': 73.8,
      });

      final restarted = HiveFavoritesDataSource(
        box: Hive.box(HiveBoxes.favorites),
      );

      expect(restarted.getAll(), hasLength(1));
    },
  );
}
