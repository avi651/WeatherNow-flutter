import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/presentation/utils/daily_forecast_aggregator.dart';

void main() {
  ForecastEntry entry({
    required DateTime forecastFor,
    required double temperatureCelsius,
    WeatherCondition condition = WeatherCondition.clear,
  }) {
    return ForecastEntry(
      forecastFor: forecastFor,
      temperatureCelsius: temperatureCelsius,
      feelsLikeCelsius: temperatureCelsius,
      humidityPercent: 50,
      condition: condition,
      description: 'test',
      precipitationProbability: 0,
    );
  }

  test('returns an empty list for no entries', () {
    expect(DailyForecastAggregator.aggregate([]), isEmpty);
  });

  test('groups same-day entries into one summary with correct min/max', () {
    final entries = [
      entry(forecastFor: DateTime.utc(2026, 9, 16, 6), temperatureCelsius: 18),
      entry(forecastFor: DateTime.utc(2026, 9, 16, 12), temperatureCelsius: 25),
      entry(forecastFor: DateTime.utc(2026, 9, 16, 18), temperatureCelsius: 20),
    ];

    final result = DailyForecastAggregator.aggregate(entries);

    expect(result, hasLength(1));
    expect(result.single.minTemperatureCelsius, 18);
    expect(result.single.maxTemperatureCelsius, 25);
    expect(result.single.date, DateTime.utc(2026, 9, 16));
  });

  test('splits entries spanning multiple days, sorted chronologically', () {
    final entries = [
      entry(forecastFor: DateTime.utc(2026, 9, 17, 12), temperatureCelsius: 22),
      entry(forecastFor: DateTime.utc(2026, 9, 16, 12), temperatureCelsius: 18),
    ];

    final result = DailyForecastAggregator.aggregate(entries);

    expect(result, hasLength(2));
    expect(result[0].date, DateTime.utc(2026, 9, 16));
    expect(result[1].date, DateTime.utc(2026, 9, 17));
  });

  test('picks the entry closest to midday as the representative condition',
      () {
    final entries = [
      entry(
        forecastFor: DateTime.utc(2026, 9, 16, 3),
        temperatureCelsius: 15,
        condition: WeatherCondition.rain,
      ),
      entry(
        forecastFor: DateTime.utc(2026, 9, 16, 13),
        temperatureCelsius: 24,
        condition: WeatherCondition.clear,
      ),
      entry(
        forecastFor: DateTime.utc(2026, 9, 16, 21),
        temperatureCelsius: 17,
        condition: WeatherCondition.clouds,
      ),
    ];

    final result = DailyForecastAggregator.aggregate(entries);

    expect(result.single.condition, WeatherCondition.clear);
  });
}
