import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

void main() {
  final forecastFor = DateTime.utc(2026, 9, 16, 15);

  ForecastEntry buildEntry({
    DateTime? forecastForOverride,
    double temperatureCelsius = 18.0,
    double feelsLikeCelsius = 17.0,
    int humidityPercent = 55,
    WeatherCondition condition = WeatherCondition.clouds,
    String description = 'scattered clouds',
    double precipitationProbability = 0.2,
  }) {
    return ForecastEntry(
      forecastFor: forecastForOverride ?? forecastFor,
      temperatureCelsius: temperatureCelsius,
      feelsLikeCelsius: feelsLikeCelsius,
      humidityPercent: humidityPercent,
      condition: condition,
      description: description,
      precipitationProbability: precipitationProbability,
    );
  }

  group('ForecastEntry', () {
    test('stores all provided values', () {
      final entry = buildEntry();

      expect(entry.forecastFor, forecastFor);
      expect(entry.temperatureCelsius, 18.0);
      expect(entry.feelsLikeCelsius, 17.0);
      expect(entry.humidityPercent, 55);
      expect(entry.condition, WeatherCondition.clouds);
      expect(entry.description, 'scattered clouds');
      expect(entry.precipitationProbability, 0.2);
    });

    test('throws when humidity is below 0', () {
      expect(() => buildEntry(humidityPercent: -1), throwsArgumentError);
    });

    test('throws when humidity is above 100', () {
      expect(() => buildEntry(humidityPercent: 101), throwsArgumentError);
    });

    test('throws when precipitation probability is below 0.0', () {
      expect(
        () => buildEntry(precipitationProbability: -0.01),
        throwsArgumentError,
      );
    });

    test('throws when precipitation probability is above 1.0', () {
      expect(
        () => buildEntry(precipitationProbability: 1.01),
        throwsArgumentError,
      );
    });

    test('accepts humidity at the lower boundary (0)', () {
      expect(buildEntry(humidityPercent: 0).humidityPercent, 0);
    });

    test('accepts humidity at the upper boundary (100)', () {
      expect(buildEntry(humidityPercent: 100).humidityPercent, 100);
    });

    test('accepts precipitation probability at the lower boundary (0.0)', () {
      expect(
        buildEntry(precipitationProbability: 0.0).precipitationProbability,
        0.0,
      );
    });

    test('accepts precipitation probability at the upper boundary (1.0)', () {
      expect(
        buildEntry(precipitationProbability: 1.0).precipitationProbability,
        1.0,
      );
    });

    test('two instances with identical values are equal', () {
      expect(buildEntry(), equals(buildEntry()));
    });

    test('two instances differing only by condition are not equal', () {
      expect(
        buildEntry(condition: WeatherCondition.clouds),
        isNot(equals(buildEntry(condition: WeatherCondition.rain))),
      );
    });

    test('two instances with different values are not equal', () {
      expect(
        buildEntry(temperatureCelsius: 18.0),
        isNot(equals(buildEntry(temperatureCelsius: 19.5))),
      );
    });

    test('equal instances share the same hashCode', () {
      expect(buildEntry().hashCode, buildEntry().hashCode);
    });
  });
}
