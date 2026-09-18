import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:weather_now_flutter/data/datasources/weather_cache_hive_data_source.dart';
import 'package:weather_now_flutter/data/local/hive_boxes.dart';

/// Exercises [HiveWeatherCacheDataSource] against real (test-only) Hive
/// boxes — see `favorites_hive_data_source_test.dart` for why this is a
/// plain `test()`, not `testWidgets()`.
void main() {
  late HiveWeatherCacheDataSource dataSource;

  setUp(() {
    dataSource = HiveWeatherCacheDataSource(
      currentWeatherBox: Hive.box(HiveBoxes.currentWeatherCache),
      forecastBox: Hive.box(HiveBoxes.forecastCache),
    );
  });

  test('getCurrentWeather is null for a fresh box', () {
    expect(dataSource.getCurrentWeather('key1'), isNull);
  });

  test('putCurrentWeather then getCurrentWeather round-trips the value', () async {
    await dataSource.putCurrentWeather('key1', {'temperatureCelsius': 21.5});

    expect(dataSource.getCurrentWeather('key1')!['temperatureCelsius'], 21.5);
  });

  test('getForecast is null for a fresh box', () {
    expect(dataSource.getForecast('key1'), isNull);
  });

  test('putForecast then getForecast round-trips the value', () async {
    await dataSource.putForecast('key1', {
      'entries': [
        {'temperatureCelsius': 25.0},
      ],
    });

    expect(dataSource.getForecast('key1')!['entries'], hasLength(1));
  });

  test('current weather and forecast are stored independently', () async {
    await dataSource.putCurrentWeather('key1', {'temperatureCelsius': 21.5});

    expect(dataSource.getForecast('key1'), isNull);
  });

  test('a cached value survives a fresh data source over the same boxes', () async {
    await dataSource.putCurrentWeather('key1', {'temperatureCelsius': 21.5});

    final restarted = HiveWeatherCacheDataSource(
      currentWeatherBox: Hive.box(HiveBoxes.currentWeatherCache),
      forecastBox: Hive.box(HiveBoxes.forecastCache),
    );

    expect(restarted.getCurrentWeather('key1')!['temperatureCelsius'], 21.5);
  });
}
