import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/forecast.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

void main() {
  ForecastEntry buildEntry({
    DateTime? forecastFor,
    double temperatureCelsius = 18.0,
  }) {
    return ForecastEntry(
      forecastFor: forecastFor ?? DateTime.utc(2026, 9, 16, 15),
      temperatureCelsius: temperatureCelsius,
      feelsLikeCelsius: temperatureCelsius - 1,
      humidityPercent: 55,
      condition: WeatherCondition.clouds,
      description: 'scattered clouds',
      precipitationProbability: 0.2,
    );
  }

  group('Forecast', () {
    test('exposes the entries it was built with, in order', () {
      final first = buildEntry(forecastFor: DateTime.utc(2026, 9, 16, 15));
      final second = buildEntry(forecastFor: DateTime.utc(2026, 9, 16, 18));

      final forecast = Forecast(entries: [first, second]);

      expect(forecast.entries, [first, second]);
    });

    test('entries list cannot be mutated externally', () {
      final forecast = Forecast(entries: [buildEntry()]);

      expect(() => forecast.entries.add(buildEntry()), throwsUnsupportedError);
    });

    test('isEmpty and isNotEmpty reflect the entry count', () {
      expect(Forecast(entries: const []).isEmpty, isTrue);
      expect(Forecast(entries: [buildEntry()]).isNotEmpty, isTrue);
    });

    test('two forecasts with equal entries in the same order are equal', () {
      final entry = buildEntry();

      expect(Forecast(entries: [entry]), equals(Forecast(entries: [entry])));
    });

    test('forecasts with entries in a different order are not equal', () {
      final a = buildEntry(forecastFor: DateTime.utc(2026, 9, 16, 15));
      final b = buildEntry(forecastFor: DateTime.utc(2026, 9, 16, 18));

      expect(
        Forecast(entries: [a, b]),
        isNot(equals(Forecast(entries: [b, a]))),
      );
    });
  });
}
