import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/presentation/utils/daily_forecast_aggregator.dart';
import 'package:weather_now_flutter/presentation/utils/day_period_grouper.dart';

ForecastEntry _entry(
  int hour,
  double temp, {
  int humidity = 50,
  double pop = 0,
}) {
  return ForecastEntry(
    forecastFor: DateTime.utc(2026, 9, 16, hour),
    temperatureCelsius: temp,
    feelsLikeCelsius: temp,
    humidityPercent: humidity,
    condition: WeatherCondition.clear,
    description: 'clear sky',
    precipitationProbability: pop,
  );
}

void main() {
  test('maps hours to periods, dropping overnight', () {
    expect(DayPeriod.fromHour(6), DayPeriod.morning);
    expect(DayPeriod.fromHour(12), DayPeriod.afternoon);
    expect(DayPeriod.fromHour(18), DayPeriod.evening);
    expect(DayPeriod.fromHour(0), isNull);
    expect(DayPeriod.fromHour(3), isNull);
  });

  test('groups 3-hour entries into ordered periods with aggregates', () {
    final result = DayPeriodGrouper.group([
      _entry(21, 15),
      _entry(0, 12),
      _entry(6, 14, humidity: 80, pop: 0.2),
      _entry(9, 20, humidity: 60, pop: 0.6),
      _entry(12, 26),
      _entry(18, 22),
    ]);

    expect(result.map((p) => p.period), [
      DayPeriod.morning,
      DayPeriod.afternoon,
      DayPeriod.evening,
    ]);
    final morning = result.first;
    expect(morning.minTemperatureCelsius, 14);
    expect(morning.maxTemperatureCelsius, 20);
    expect(morning.averageHumidityPercent, 70);
    expect(morning.maxPrecipitationProbability, 0.6);
    expect(result.last.entries, hasLength(2));
  });

  test('omits periods with no entries', () {
    final result = DayPeriodGrouper.group([_entry(12, 25)]);
    expect(result.single.period, DayPeriod.afternoon);
  });

  test('aggregator keeps the day\'s entries for the detail view', () {
    final summary = DailyForecastAggregator.aggregate([
      _entry(6, 14),
      _entry(12, 26),
    ]).single;
    expect(summary.entries, hasLength(2));
  });
}
