import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/error/cache_failures.dart';
import 'package:weather_now_flutter/data/datasources/weather_cache_local_data_source.dart';
import 'package:weather_now_flutter/data/repositories/weather_cache_repository_impl.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/forecast.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

/// An in-memory stand-in for [WeatherCacheLocalDataSource] — keeps
/// [WeatherCacheRepositoryImpl]'s tests fast and independent of Hive, which
/// [HiveWeatherCacheDataSource] (tested separately) is responsible for.
class FakeWeatherCacheLocalDataSource implements WeatherCacheLocalDataSource {
  final Map<String, Map<String, dynamic>> currentWeather = {};
  final Map<String, Map<String, dynamic>> forecast = {};

  Object? failWith;

  @override
  Map<String, dynamic>? getCurrentWeather(String key) {
    if (failWith != null) throw failWith!;
    return currentWeather[key];
  }

  @override
  Future<void> putCurrentWeather(String key, Map<String, dynamic> value) async {
    if (failWith != null) throw failWith!;
    currentWeather[key] = value;
  }

  @override
  Map<String, dynamic>? getForecast(String key) {
    if (failWith != null) throw failWith!;
    return forecast[key];
  }

  @override
  Future<void> putForecast(String key, Map<String, dynamic> value) async {
    if (failWith != null) throw failWith!;
    forecast[key] = value;
  }
}

void main() {
  late FakeWeatherCacheLocalDataSource dataSource;
  late WeatherCacheRepositoryImpl repository;

  const latitude = 18.5213738;
  const longitude = 73.8545071;
  final fetchedAt = DateTime.utc(2026, 9, 18, 10, 30);

  final weather = CurrentWeather(
    temperatureCelsius: 28.5,
    feelsLikeCelsius: 30.0,
    humidityPercent: 55,
    pressureHpa: 1010,
    windSpeedMetersPerSecond: 2.5,
    condition: WeatherCondition.clear,
    description: 'clear sky',
    observedAt: DateTime.utc(2026, 9, 18, 10, 0),
  );

  final forecast = Forecast(
    entries: [
      ForecastEntry(
        forecastFor: DateTime.utc(2026, 9, 18, 12),
        temperatureCelsius: 30,
        feelsLikeCelsius: 32,
        humidityPercent: 50,
        condition: WeatherCondition.clouds,
        description: 'scattered clouds',
        precipitationProbability: 0.2,
      ),
    ],
  );

  setUp(() {
    dataSource = FakeWeatherCacheLocalDataSource();
    repository = WeatherCacheRepositoryImpl(localDataSource: dataSource);
  });

  group('current weather', () {
    test('getCurrentWeather returns null when nothing is cached', () async {
      final result = await repository.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );

      result.fold(
        (_) => fail('expected Right'),
        (cached) => expect(cached, isNull),
      );
    });

    test(
      'saveCurrentWeather then getCurrentWeather round-trips the snapshot',
      () async {
        await repository.saveCurrentWeather(
          latitude: latitude,
          longitude: longitude,
          weather: weather,
          fetchedAt: fetchedAt,
          cityName: 'Pune',
          country: 'IN',
        );

        final result = await repository.getCurrentWeather(
          latitude: latitude,
          longitude: longitude,
        );

        result.fold((_) => fail('expected Right'), (cached) {
          expect(cached, isNotNull);
          expect(cached!.weather, weather);
          expect(cached.fetchedAt, fetchedAt);
          expect(cached.cityName, 'Pune');
          expect(cached.country, 'IN');
        });
      },
    );

    test(
      'a later failed save does not touch what was already cached',
      () async {
        await repository.saveCurrentWeather(
          latitude: latitude,
          longitude: longitude,
          weather: weather,
          fetchedAt: fetchedAt,
        );

        dataSource.failWith = Exception('disk full');
        final saveResult = await repository.saveCurrentWeather(
          latitude: latitude,
          longitude: longitude,
          weather: weather,
          fetchedAt: DateTime.now(),
        );
        expect(saveResult.isLeft(), isTrue);

        dataSource.failWith = null;
        final result = await repository.getCurrentWeather(
          latitude: latitude,
          longitude: longitude,
        );
        result.fold(
          (_) => fail('expected Right'),
          (cached) => expect(cached!.weather, weather),
        );
      },
    );

    test(
      'getCurrentWeather returns a CacheFailure when the data source throws',
      () async {
        dataSource.failWith = Exception('corrupted entry');

        final result = await repository.getCurrentWeather(
          latitude: latitude,
          longitude: longitude,
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('expected Left'),
        );
      },
    );
  });

  group('forecast', () {
    test('getForecast returns null when nothing is cached', () async {
      final result = await repository.getForecast(
        latitude: latitude,
        longitude: longitude,
      );

      result.fold(
        (_) => fail('expected Right'),
        (cached) => expect(cached, isNull),
      );
    });

    test('saveForecast then getForecast round-trips the snapshot', () async {
      await repository.saveForecast(
        latitude: latitude,
        longitude: longitude,
        forecast: forecast,
        fetchedAt: fetchedAt,
        cityName: 'Pune',
        country: 'IN',
      );

      final result = await repository.getForecast(
        latitude: latitude,
        longitude: longitude,
      );

      result.fold((_) => fail('expected Right'), (cached) {
        expect(cached, isNotNull);
        expect(cached!.forecast, forecast);
        expect(cached.fetchedAt, fetchedAt);
      });
    });

    test(
      'getForecast returns a CacheFailure when the data source throws',
      () async {
        dataSource.failWith = Exception('corrupted entry');

        final result = await repository.getForecast(
          latitude: latitude,
          longitude: longitude,
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('expected Left'),
        );
      },
    );
  });

  test('different locations are cached independently', () async {
    await repository.saveCurrentWeather(
      latitude: latitude,
      longitude: longitude,
      weather: weather,
      fetchedAt: fetchedAt,
    );

    final result = await repository.getCurrentWeather(
      latitude: 51.5072,
      longitude: -0.1276,
    );

    result.fold(
      (_) => fail('expected Right'),
      (cached) => expect(cached, isNull),
    );
  });
}
