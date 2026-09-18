import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/data/models/cached_current_weather_model.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

void main() {
  final weather = CurrentWeather(
    temperatureCelsius: 21.5,
    feelsLikeCelsius: 20.0,
    humidityPercent: 60,
    pressureHpa: 1013,
    windSpeedMetersPerSecond: 3.2,
    condition: WeatherCondition.rain,
    description: 'light rain',
    observedAt: DateTime.utc(2026, 9, 18, 9, 0),
  );
  final fetchedAt = DateTime.utc(2026, 9, 18, 9, 5);

  test('fromEntity -> toJson -> fromJson -> toEntity round-trips the weather', () {
    final model = CachedCurrentWeatherModel.fromEntity(
      weather: weather,
      fetchedAt: fetchedAt,
      cityName: 'Pune',
      country: 'IN',
    );

    final restored = CachedCurrentWeatherModel.fromJson(model.toJson());
    final entity = restored.toEntity();

    expect(entity.weather, weather);
    expect(entity.fetchedAt, fetchedAt);
    expect(entity.cityName, 'Pune');
    expect(entity.country, 'IN');
  });

  test('toJson stores the condition as its enum name', () {
    final model = CachedCurrentWeatherModel.fromEntity(weather: weather, fetchedAt: fetchedAt);

    expect(model.toJson()['condition'], 'rain');
  });

  test('cityName and country are optional', () {
    final model = CachedCurrentWeatherModel.fromEntity(weather: weather, fetchedAt: fetchedAt);

    final restored = CachedCurrentWeatherModel.fromJson(model.toJson()).toEntity();

    expect(restored.cityName, isNull);
    expect(restored.country, isNull);
  });
}
