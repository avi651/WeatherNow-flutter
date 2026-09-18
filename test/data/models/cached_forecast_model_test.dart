import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/data/models/cached_forecast_model.dart';
import 'package:weather_now_flutter/domain/entities/forecast.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

void main() {
  final forecast = Forecast(
    entries: [
      ForecastEntry(
        forecastFor: DateTime.utc(2026, 9, 18, 12),
        temperatureCelsius: 28,
        feelsLikeCelsius: 30,
        humidityPercent: 55,
        condition: WeatherCondition.clouds,
        description: 'scattered clouds',
        precipitationProbability: 0.2,
      ),
      ForecastEntry(
        forecastFor: DateTime.utc(2026, 9, 18, 15),
        temperatureCelsius: 26,
        feelsLikeCelsius: 27,
        humidityPercent: 60,
        condition: WeatherCondition.rain,
        description: 'light rain',
        precipitationProbability: 0.6,
      ),
    ],
  );
  final fetchedAt = DateTime.utc(2026, 9, 18, 10);

  test('fromEntity -> toJson -> fromJson -> toEntity round-trips every entry', () {
    final model = CachedForecastModel.fromEntity(
      forecast: forecast,
      fetchedAt: fetchedAt,
      cityName: 'Pune',
      country: 'IN',
    );

    final restored = CachedForecastModel.fromJson(model.toJson()).toEntity();

    expect(restored.forecast, forecast);
    expect(restored.fetchedAt, fetchedAt);
    expect(restored.cityName, 'Pune');
    expect(restored.country, 'IN');
  });

  test('round-trips an empty forecast', () {
    final model = CachedForecastModel.fromEntity(
      forecast: Forecast(entries: const []),
      fetchedAt: fetchedAt,
    );

    final restored = CachedForecastModel.fromJson(model.toJson()).toEntity();

    expect(restored.forecast.isEmpty, isTrue);
  });
}
