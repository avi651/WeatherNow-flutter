import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/failures.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/domain/usecases/get_current_weather.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  late MockWeatherRepository mockRepository;
  late GetCurrentWeather useCase;

  const latitude = 12.34;
  const longitude = 56.78;

  final weather = CurrentWeather(
    temperatureCelsius: 21.5,
    feelsLikeCelsius: 20.0,
    humidityPercent: 60,
    pressureHpa: 1013,
    windSpeedMetersPerSecond: 3.2,
    condition: WeatherCondition.clear,
    description: 'clear sky',
    observedAt: DateTime.utc(2026, 9, 16, 12),
  );

  setUp(() {
    mockRepository = MockWeatherRepository();
    useCase = GetCurrentWeather(mockRepository);
  });

  test('returns the CurrentWeather from the repository on success', () async {
    when(
      () => mockRepository.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      ),
    ).thenAnswer((_) async => Right(weather));

    final result = await useCase(latitude: latitude, longitude: longitude);

    expect(result, Right(weather));
    verify(
      () => mockRepository.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      ),
    ).called(1);
  });

  test('returns the Failure from the repository on error', () async {
    const failure = RemoteDataFailure('Server error', statusCode: 500);
    when(
      () => mockRepository.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(latitude: latitude, longitude: longitude);

    expect(result, const Left<Failure, CurrentWeather>(failure));
  });
}
