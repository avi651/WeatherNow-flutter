import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/location_failures.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/presentation/providers/home_weather_exception.dart';
import 'package:weather_now_flutter/presentation/providers/home_weather_provider.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockWeatherRepository mockRepository;
  late MockLocationService mockLocationService;

  const location = DeviceLocation(latitude: 12.9716, longitude: 77.5946);

  final weather = CurrentWeather(
    temperatureCelsius: 21.5,
    feelsLikeCelsius: 20.0,
    humidityPercent: 60,
    pressureHpa: 1013,
    windSpeedMetersPerSecond: 3.2,
    condition: WeatherCondition.clear,
    description: 'clear sky',
    observedAt: DateTime.utc(2026, 9, 16),
  );

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        weatherRepositoryProvider.overrideWithValue(mockRepository),
        locationServiceProvider.overrideWithValue(mockLocationService),
      ],
    );

    addTearDown(container.dispose);
    return container;
  }

  void stubLocationSuccess() {
    when(
      () => mockLocationService.getCurrentLocation(),
    ).thenAnswer((_) async => const Right(location));
  }

  Future<void> ignoreProviderError(Future<CurrentWeather> future) async {
    try {
      await future;
    } catch (_) {
      // Expected error in failure test cases.
    }
  }

  setUp(() {
    mockRepository = MockWeatherRepository();
    mockLocationService = MockLocationService();
  });

  test('starts loading, then resolves to data on success', () async {
    stubLocationSuccess();

    when(
      () => mockRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Right(weather));

    final container = buildContainer();

    expect(
      container.read(homeWeatherProvider),
      isA<AsyncLoading<CurrentWeather>>(),
    );

    await container.read(homeWeatherProvider.future);

    expect(container.read(homeWeatherProvider).value, weather);

    verify(() => mockLocationService.getCurrentLocation()).called(1);

    verify(
      () => mockRepository.getCurrentWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    ).called(1);
  });

  test('resolves to an error carrying the failure message', () async {
    stubLocationSuccess();

    when(
      () => mockRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));

    final container = buildContainer();

    await ignoreProviderError(container.read(homeWeatherProvider.future));

    final state = container.read(homeWeatherProvider);

    expect(state.hasError, isTrue);

    expect(
      (state.error as HomeWeatherFailureException).message,
      'No connection',
    );
  });

  test('resolves to an error when location permission is denied', () async {
    when(() => mockLocationService.getCurrentLocation()).thenAnswer(
      (_) async => const Left(
        LocationPermissionDeniedFailure('Location permission was denied.'),
      ),
    );

    final container = buildContainer();

    await ignoreProviderError(container.read(homeWeatherProvider.future));

    final state = container.read(homeWeatherProvider);

    expect(state.hasError, isTrue);

    expect(
      (state.error as HomeWeatherFailureException).message,
      'Location permission was denied.',
    );

    verifyNever(
      () => mockRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    );
  });

  test('retry re-invokes location resolution and repository', () async {
    stubLocationSuccess();

    when(
      () => mockRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Right(weather));

    final container = buildContainer();

    await container.read(homeWeatherProvider.future);

    await container.read(homeWeatherProvider.notifier).retry();

    verify(() => mockLocationService.getCurrentLocation()).called(2);

    verify(
      () => mockRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).called(2);
  });
}
