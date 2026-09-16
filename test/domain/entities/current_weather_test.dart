import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

void main() {
  final observedAt = DateTime.utc(2026, 9, 16, 12);

  CurrentWeather buildWeather({
    double temperatureCelsius = 21.5,
    double feelsLikeCelsius = 20.0,
    int humidityPercent = 60,
    int pressureHpa = 1013,
    double windSpeedMetersPerSecond = 3.2,
    WeatherCondition condition = WeatherCondition.clear,
    String description = 'clear sky',
    DateTime? observedAtOverride,
  }) {
    return CurrentWeather(
      temperatureCelsius: temperatureCelsius,
      feelsLikeCelsius: feelsLikeCelsius,
      humidityPercent: humidityPercent,
      pressureHpa: pressureHpa,
      windSpeedMetersPerSecond: windSpeedMetersPerSecond,
      condition: condition,
      description: description,
      observedAt: observedAtOverride ?? observedAt,
    );
  }

  group('CurrentWeather', () {
    test('stores all provided values', () {
      final weather = buildWeather();

      expect(weather.temperatureCelsius, 21.5);
      expect(weather.feelsLikeCelsius, 20.0);
      expect(weather.humidityPercent, 60);
      expect(weather.pressureHpa, 1013);
      expect(weather.windSpeedMetersPerSecond, 3.2);
      expect(weather.condition, WeatherCondition.clear);
      expect(weather.description, 'clear sky');
      expect(weather.observedAt, observedAt);
    });

    test('throws when humidity is below 0', () {
      expect(() => buildWeather(humidityPercent: -1), throwsArgumentError);
    });

    test('throws when humidity is above 100', () {
      expect(() => buildWeather(humidityPercent: 101), throwsArgumentError);
    });

    test('throws when wind speed is negative', () {
      expect(
        () => buildWeather(windSpeedMetersPerSecond: -0.1),
        throwsArgumentError,
      );
    });

    test('accepts humidity at the lower boundary (0)', () {
      expect(buildWeather(humidityPercent: 0).humidityPercent, 0);
    });

    test('accepts humidity at the upper boundary (100)', () {
      expect(buildWeather(humidityPercent: 100).humidityPercent, 100);
    });

    test('accepts zero wind speed', () {
      expect(
        buildWeather(windSpeedMetersPerSecond: 0).windSpeedMetersPerSecond,
        0,
      );
    });

    test('two instances with identical values are equal', () {
      expect(buildWeather(), equals(buildWeather()));
    });

    test('two instances differing only by condition are not equal', () {
      expect(
        buildWeather(condition: WeatherCondition.clear),
        isNot(equals(buildWeather(condition: WeatherCondition.clouds))),
      );
    });

    test('two instances with different values are not equal', () {
      expect(
        buildWeather(temperatureCelsius: 21.5),
        isNot(equals(buildWeather(temperatureCelsius: 22.0))),
      );
    });

    test('equal instances share the same hashCode', () {
      expect(buildWeather().hashCode, buildWeather().hashCode);
    });
  });
}
