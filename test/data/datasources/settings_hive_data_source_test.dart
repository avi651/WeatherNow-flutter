import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:weather_now_flutter/data/datasources/settings_hive_data_source.dart';
import 'package:weather_now_flutter/data/local/hive_boxes.dart';

/// Exercises [HiveSettingsDataSource] against a real (test-only) Hive box
/// — see `favorites_hive_data_source_test.dart` for why this uses plain
/// `test()`, not `testWidgets()`.
void main() {
  late Box<dynamic> box;
  late HiveSettingsDataSource dataSource;

  setUp(() {
    box = Hive.box(HiveBoxes.settings);
    dataSource = HiveSettingsDataSource(box: box);
  });

  test('every getter is null for a fresh box', () {
    expect(dataSource.getTemperatureUnit(), isNull);
    expect(dataSource.getThemeMode(), isNull);
    expect(dataSource.getOfflineDataEnabled(), isNull);
  });

  test('setTemperatureUnit then getTemperatureUnit returns the saved value',
      () async {
    await dataSource.setTemperatureUnit('fahrenheit');

    expect(dataSource.getTemperatureUnit(), 'fahrenheit');
  });

  test('setThemeMode then getThemeMode returns the saved value', () async {
    await dataSource.setThemeMode('dark');

    expect(dataSource.getThemeMode(), 'dark');
  });

  test('setOfflineDataEnabled then getOfflineDataEnabled returns the saved value',
      () async {
    await dataSource.setOfflineDataEnabled(false);

    expect(dataSource.getOfflineDataEnabled(), isFalse);
  });

  test('each setting is stored independently under its own key', () async {
    await dataSource.setTemperatureUnit('fahrenheit');
    await dataSource.setThemeMode('dark');
    await dataSource.setOfflineDataEnabled(false);

    expect(dataSource.getTemperatureUnit(), 'fahrenheit');
    expect(dataSource.getThemeMode(), 'dark');
    expect(dataSource.getOfflineDataEnabled(), isFalse);
  });

  test('a saved value survives a fresh data source over the same box',
      () async {
    await dataSource.setTemperatureUnit('fahrenheit');

    final restarted = HiveSettingsDataSource(box: Hive.box(HiveBoxes.settings));

    expect(restarted.getTemperatureUnit(), 'fahrenheit');
  });
}
