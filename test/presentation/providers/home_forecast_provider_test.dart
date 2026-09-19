import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/cache_failures.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/location_failures.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/app_settings.dart';
import 'package:weather_now_flutter/domain/entities/app_theme_mode.dart';
import 'package:weather_now_flutter/domain/entities/cached_forecast.dart';
import 'package:weather_now_flutter/domain/entities/forecast.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/temperature_unit.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/settings_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_cache_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/presentation/providers/home_forecast_provider.dart';
import 'package:weather_now_flutter/presentation/providers/home_weather_exception.dart';
import 'package:weather_now_flutter/presentation/providers/weather_freshness_provider.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockLocationService extends Mock implements LocationService {}

class MockWeatherCacheRepository extends Mock implements WeatherCacheRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockWeatherRepository mockRepository;
  late MockLocationService mockLocationService;

  const location = DeviceLocation(latitude: 12.9716, longitude: 77.5946);

  final forecast = Forecast(
    entries: [
      ForecastEntry(
        forecastFor: DateTime.utc(2026, 9, 16, 12),
        temperatureCelsius: 22,
        feelsLikeCelsius: 21,
        humidityPercent: 55,
        condition: WeatherCondition.clear,
        description: 'clear sky',
        precipitationProbability: 0.1,
      ),
    ],
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

  Future<void> ignoreProviderError(Future<Forecast> future) async {
    try {
      await future;
    } catch (_) {
      // Expected error for failure test cases.
    }
  }

  setUpAll(() {
    registerFallbackValue(forecast);
  });

  setUp(() {
    mockRepository = MockWeatherRepository();
    mockLocationService = MockLocationService();
  });

  test('resolves to the forecast on success', () async {
    stubLocationSuccess();

    when(
      () => mockRepository.getForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Right(forecast));

    final container = buildContainer();

    expect(container.read(homeForecastProvider), isA<AsyncLoading<Forecast>>());

    await container.read(homeForecastProvider.future);

    expect(container.read(homeForecastProvider).value, forecast);

    verify(() => mockLocationService.getCurrentLocation()).called(1);

    verify(
      () => mockRepository.getForecast(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    ).called(1);
  });

  test('resolves to an error carrying the failure message', () async {
    stubLocationSuccess();

    when(
      () => mockRepository.getForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));

    final container = buildContainer();

    await ignoreProviderError(container.read(homeForecastProvider.future));

    final state = container.read(homeForecastProvider);

    expect(state.hasError, isTrue);

    expect(
      (state.error as HomeWeatherFailureException).message,
      'No connection',
    );
  });

  test('resolves to an error when location resolution fails', () async {
    when(() => mockLocationService.getCurrentLocation()).thenAnswer(
      (_) async => const Left(
        LocationServiceDisabledFailure('Location services are turned off.'),
      ),
    );

    final container = buildContainer();

    await ignoreProviderError(container.read(homeForecastProvider.future));

    final state = container.read(homeForecastProvider);

    expect(state.hasError, isTrue);

    expect(
      (state.error as HomeWeatherFailureException).message,
      'Location services are turned off.',
    );

    verifyNever(
      () => mockRepository.getForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    );
  });

  test('retry re-invokes location resolution and repository', () async {
    stubLocationSuccess();

    when(
      () => mockRepository.getForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Right(forecast));

    final container = buildContainer();

    await container.read(homeForecastProvider.future);

    await container.read(homeForecastProvider.notifier).retry();

    verify(() => mockLocationService.getCurrentLocation()).called(2);

    verify(
      () => mockRepository.getForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).called(2);
  });

  group('offline caching', () {
    late MockWeatherCacheRepository mockCacheRepository;

    ProviderContainer buildContainerWithCache() {
      final container = ProviderContainer(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
          weatherCacheRepositoryProvider.overrideWithValue(mockCacheRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    setUp(() {
      mockCacheRepository = MockWeatherCacheRepository();
    });

    test('a successful fetch is cached and reported as not from cache', () async {
      stubLocationSuccess();
      when(
        () => mockRepository.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(forecast));
      when(
        () => mockCacheRepository.saveForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          forecast: any(named: 'forecast'),
          fetchedAt: any(named: 'fetchedAt'),
          cityName: any(named: 'cityName'),
          country: any(named: 'country'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      final container = buildContainerWithCache();
      await container.read(homeForecastProvider.future);

      verify(
        () => mockCacheRepository.saveForecast(
          latitude: location.latitude,
          longitude: location.longitude,
          forecast: forecast,
          fetchedAt: any(named: 'fetchedAt'),
          cityName: any(named: 'cityName'),
          country: any(named: 'country'),
        ),
      ).called(1);

      final freshness = container.read(forecastFreshnessProvider);
      expect(freshness!.isFromCache, isFalse);
    });

    test('falls back to the cached forecast when the live fetch fails', () async {
      stubLocationSuccess();
      when(
        () => mockRepository.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));

      final cachedAt = DateTime.utc(2026, 9, 17);
      when(
        () => mockCacheRepository.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer(
        (_) async => Right(CachedForecast(forecast: forecast, fetchedAt: cachedAt)),
      );

      final container = buildContainerWithCache();
      final result = await container.read(homeForecastProvider.future);

      expect(result, forecast);
      final freshness = container.read(forecastFreshnessProvider);
      expect(freshness!.isFromCache, isTrue);
      expect(freshness.fetchedAt, cachedAt);

      verifyNever(
        () => mockCacheRepository.saveForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          forecast: any(named: 'forecast'),
          fetchedAt: any(named: 'fetchedAt'),
          cityName: any(named: 'cityName'),
          country: any(named: 'country'),
        ),
      );
    });

    test(
      'propagates the original failure — not a cache error — when nothing is cached',
      () async {
        stubLocationSuccess();
        when(
          () => mockRepository.getForecast(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));
        when(
          () => mockCacheRepository.getForecast(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => const Right(null));

        final container = buildContainerWithCache();

        await ignoreProviderError(container.read(homeForecastProvider.future));

        final state = container.read(homeForecastProvider);
        expect(state.hasError, isTrue);
        expect((state.error as HomeWeatherFailureException).message, 'No connection');
      },
    );

    test(
      'propagates the original failure when reading the cache itself fails',
      () async {
        stubLocationSuccess();
        when(
          () => mockRepository.getForecast(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));
        when(
          () => mockCacheRepository.getForecast(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => const Left(CacheFailure('corrupted')));

        final container = buildContainerWithCache();

        await ignoreProviderError(container.read(homeForecastProvider.future));

        final state = container.read(homeForecastProvider);
        expect(state.hasError, isTrue);
        expect((state.error as HomeWeatherFailureException).message, 'No connection');
      },
    );
  });

  group('offline data disabled', () {
    late MockWeatherCacheRepository mockCacheRepository;
    late MockSettingsRepository mockSettingsRepository;

    ProviderContainer buildContainerWithOfflineDataDisabled() {
      final container = ProviderContainer(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
          weatherCacheRepositoryProvider.overrideWithValue(mockCacheRepository),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    setUp(() {
      mockCacheRepository = MockWeatherCacheRepository();
      mockSettingsRepository = MockSettingsRepository();
      when(() => mockSettingsRepository.getSettings()).thenAnswer(
        (_) async => const Right(
          AppSettings(
            temperatureUnit: TemperatureUnit.celsius,
            themeMode: AppThemeMode.system,
            offlineDataEnabled: false,
          ),
        ),
      );
    });

    test('a successful fetch is not cached', () async {
      stubLocationSuccess();
      when(
        () => mockRepository.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(forecast));

      final container = buildContainerWithOfflineDataDisabled();
      await container.read(homeForecastProvider.future);

      verifyNever(
        () => mockCacheRepository.saveForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          forecast: any(named: 'forecast'),
          fetchedAt: any(named: 'fetchedAt'),
          cityName: any(named: 'cityName'),
          country: any(named: 'country'),
        ),
      );
    });

    test(
      'a failed fetch surfaces the original failure without reading the '
      'cache, even when something is cached',
      () async {
        stubLocationSuccess();
        when(
          () => mockRepository.getForecast(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));

        final container = buildContainerWithOfflineDataDisabled();

        await ignoreProviderError(container.read(homeForecastProvider.future));

        final state = container.read(homeForecastProvider);
        expect(state.hasError, isTrue);
        expect((state.error as HomeWeatherFailureException).message, 'No connection');
        verifyNever(
          () => mockCacheRepository.getForecast(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
      },
    );
  });
}
