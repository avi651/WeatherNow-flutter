import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/failures.dart';
import 'package:weather_now_flutter/domain/entities/forecast.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/domain/usecases/get_forecast.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  late MockWeatherRepository mockRepository;
  late GetForecast useCase;

  const latitude = 12.34;
  const longitude = 56.78;

  final forecast = Forecast(
    entries: [
      ForecastEntry(
        forecastFor: DateTime.utc(2026, 9, 16, 15),
        temperatureCelsius: 25.0,
        feelsLikeCelsius: 24.0,
        humidityPercent: 55,
        condition: WeatherCondition.rain,
        description: 'light rain',
        precipitationProbability: 0.4,
      ),
    ],
  );

  setUp(() {
    mockRepository = MockWeatherRepository();
    useCase = GetForecast(mockRepository);
  });

  test('returns the Forecast from the repository on success', () async {
    when(
      () => mockRepository.getForecast(
        latitude: latitude,
        longitude: longitude,
      ),
    ).thenAnswer((_) async => Right(forecast));

    final result = await useCase(latitude: latitude, longitude: longitude);

    expect(result, Right(forecast));
    verify(
      () => mockRepository.getForecast(
        latitude: latitude,
        longitude: longitude,
      ),
    ).called(1);
  });

  test('returns the Failure from the repository on error', () async {
    const failure = DataParsingFailure('Failed to parse weather response');
    when(
      () => mockRepository.getForecast(
        latitude: latitude,
        longitude: longitude,
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(latitude: latitude, longitude: longitude);

    expect(result, const Left<Failure, Forecast>(failure));
  });
}
