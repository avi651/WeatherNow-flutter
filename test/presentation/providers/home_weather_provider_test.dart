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
import 'package:weather_now_flutter/domain/entities/cached_current_weather.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/temperature_unit.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/settings_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_cache_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/presentation/providers/home_weather_exception.dart';
import 'package:weather_now_flutter/presentation/providers/active_city_provider.dart';
import 'package:weather_now_flutter/presentation/providers/home_weather_provider.dart';
import 'package:weather_now_flutter/presentation/providers/current_location_city_provider.dart';
import 'package:weather_now_flutter/presentation/providers/settings_provider.dart';
import 'package:weather_now_flutter/presentation/providers/weather_freshness_provider.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockLocationService extends Mock implements LocationService {}

class MockWeatherCacheRepository extends Mock
    implements WeatherCacheRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

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

  setUpAll(() {
    registerFallbackValue(weather);
  });

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

    test(
      'a successful fetch is cached and reported as not from cache',
      () async {
        stubLocationSuccess();
        when(
          () => mockRepository.getCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => Right(weather));
        when(
          () => mockCacheRepository.saveCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            weather: any(named: 'weather'),
            fetchedAt: any(named: 'fetchedAt'),
            cityName: any(named: 'cityName'),
            country: any(named: 'country'),
          ),
        ).thenAnswer((_) async => const Right(unit));

        final container = buildContainerWithCache();
        await container.read(homeWeatherProvider.future);

        verify(
          () => mockCacheRepository.saveCurrentWeather(
            latitude: location.latitude,
            longitude: location.longitude,
            weather: weather,
            fetchedAt: any(named: 'fetchedAt'),
            cityName: any(named: 'cityName'),
            country: any(named: 'country'),
          ),
        ).called(1);

        final freshness = container.read(currentWeatherFreshnessProvider);
        expect(freshness, isNotNull);
        expect(freshness!.isFromCache, isFalse);
      },
    );

    test(
      'falls back to the cached weather when the live fetch fails',
      () async {
        stubLocationSuccess();
        when(
          () => mockRepository.getCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer(
          (_) async => const Left(RemoteDataFailure('No connection')),
        );

        final cachedAt = DateTime.utc(2026, 9, 17);
        when(
          () => mockCacheRepository.getCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer(
          (_) async => Right(
            CachedCurrentWeather(weather: weather, fetchedAt: cachedAt),
          ),
        );

        final container = buildContainerWithCache();
        final result = await container.read(homeWeatherProvider.future);

        expect(result, weather);
        final freshness = container.read(currentWeatherFreshnessProvider);
        expect(freshness!.isFromCache, isTrue);
        expect(freshness.fetchedAt, cachedAt);

        // The failed response must never overwrite the cache.
        verifyNever(
          () => mockCacheRepository.saveCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            weather: any(named: 'weather'),
            fetchedAt: any(named: 'fetchedAt'),
            cityName: any(named: 'cityName'),
            country: any(named: 'country'),
          ),
        );
      },
    );

    test('exposes the cached city as the active city when offline', () async {
      stubLocationSuccess();
      when(
        () => mockRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));
      when(
        () => mockCacheRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer(
        (_) async => Right(
          CachedCurrentWeather(
            weather: weather,
            fetchedAt: DateTime.utc(2026, 9, 17),
            cityName: 'Pune',
            country: 'IN',
          ),
        ),
      );

      final container = buildContainerWithCache();
      await container.read(homeWeatherProvider.future);

      final city = container.read(activeCityProvider);
      expect(city?.name, 'Pune');
      expect(city?.country, 'IN');
    });

    test(
      'propagates the original failure — not a cache error — when nothing is cached',
      () async {
        stubLocationSuccess();
        when(
          () => mockRepository.getCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer(
          (_) async => const Left(RemoteDataFailure('No connection')),
        );
        when(
          () => mockCacheRepository.getCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => const Right(null));

        final container = buildContainerWithCache();

        await ignoreProviderError(container.read(homeWeatherProvider.future));

        final state = container.read(homeWeatherProvider);
        expect(state.hasError, isTrue);
        expect(
          (state.error as HomeWeatherFailureException).message,
          'No connection',
        );
      },
    );

    test(
      'propagates the original failure when reading the cache itself fails',
      () async {
        stubLocationSuccess();
        when(
          () => mockRepository.getCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer(
          (_) async => const Left(RemoteDataFailure('No connection')),
        );
        when(
          () => mockCacheRepository.getCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => const Left(CacheFailure('corrupted')));

        final container = buildContainerWithCache();

        await ignoreProviderError(container.read(homeWeatherProvider.future));

        final state = container.read(homeWeatherProvider);
        expect(state.hasError, isTrue);
        expect(
          (state.error as HomeWeatherFailureException).message,
          'No connection',
        );
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
        () => mockRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(weather));

      final container = buildContainerWithOfflineDataDisabled();
      await container.read(homeWeatherProvider.future);

      verifyNever(
        () => mockCacheRepository.saveCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          weather: any(named: 'weather'),
          fetchedAt: any(named: 'fetchedAt'),
          cityName: any(named: 'cityName'),
          country: any(named: 'country'),
        ),
      );
    });

    test('a failed fetch surfaces the original failure without reading the '
        'cache, even when something is cached', () async {
      stubLocationSuccess();
      when(
        () => mockRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));

      final container = buildContainerWithOfflineDataDisabled();

      await ignoreProviderError(container.read(homeWeatherProvider.future));

      final state = container.read(homeWeatherProvider);
      expect(state.hasError, isTrue);
      expect(
        (state.error as HomeWeatherFailureException).message,
        'No connection',
      );
      verifyNever(
        () => mockCacheRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      );
    });
  });

  group('offline data setting changes at runtime', () {
    late MockWeatherCacheRepository mockCacheRepository;
    late MockSettingsRepository mockSettingsRepository;

    setUp(() {
      mockCacheRepository = MockWeatherCacheRepository();
      mockSettingsRepository = MockSettingsRepository();
      when(
        () => mockSettingsRepository.getSettings(),
      ).thenAnswer((_) async => const Right(AppSettings.defaults));
      when(
        () => mockSettingsRepository.saveOfflineDataEnabled(any()),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => mockCacheRepository.saveCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          weather: any(named: 'weather'),
          fetchedAt: any(named: 'fetchedAt'),
          cityName: any(named: 'cityName'),
          country: any(named: 'country'),
        ),
      ).thenAnswer((_) async => const Right(unit));
      stubLocationSuccess();
      when(
        () => mockRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(weather));
    });

    ProviderContainer build() {
      final container = ProviderContainer(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
          weatherCacheRepositoryProvider.overrideWithValue(mockCacheRepository),
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
          // No real reverse-geocoding network call in these tests.
          currentLocationCityProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<void> pumpEvents() => Future<void>.delayed(Duration.zero);

    void verifySaves(int times) => verify(
      () => mockCacheRepository.saveCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        weather: any(named: 'weather'),
        fetchedAt: any(named: 'fetchedAt'),
        cityName: any(named: 'cityName'),
        country: any(named: 'country'),
      ),
    ).called(times);

    test(
      'turning it on stores the live data already on screen, without refetching',
      () async {
        when(() => mockSettingsRepository.getSettings()).thenAnswer(
          (_) async => const Right(
            AppSettings(
              temperatureUnit: TemperatureUnit.celsius,
              themeMode: AppThemeMode.system,
              offlineDataEnabled: false,
            ),
          ),
        );
        final container = build();
        container.listen(homeWeatherProvider, (_, _) {});
        await container.read(homeWeatherProvider.future);
        // Let the loaded (off) setting propagate before toggling it back on.
        await pumpEvents();
        verifyNever(
          () => mockCacheRepository.saveCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            weather: any(named: 'weather'),
            fetchedAt: any(named: 'fetchedAt'),
            cityName: any(named: 'cityName'),
            country: any(named: 'country'),
          ),
        );

        await container
            .read(settingsProvider.notifier)
            .setOfflineDataEnabled(true);
        await pumpEvents();
        await pumpEvents();

        verifySaves(1);
        verify(
          () => mockRepository.getCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).called(1);
      },
    );

    test(
      'turning it off stops the next successful fetch from writing',
      () async {
        final container = build();
        container.listen(homeWeatherProvider, (_, _) {});
        await container.read(homeWeatherProvider.future);
        verifySaves(1);

        await container
            .read(settingsProvider.notifier)
            .setOfflineDataEnabled(false);
        await container.read(homeWeatherProvider.notifier).retry();

        verifyNever(
          () => mockCacheRepository.saveCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            weather: any(named: 'weather'),
            fetchedAt: any(named: 'fetchedAt'),
            cityName: any(named: 'cityName'),
            country: any(named: 'country'),
          ),
        );
      },
    );

    test('turning it off stops the offline fallback immediately', () async {
      final container = build();
      container.listen(homeWeatherProvider, (_, _) {});
      await container.read(homeWeatherProvider.future);

      await container
          .read(settingsProvider.notifier)
          .setOfflineDataEnabled(false);
      when(
        () => mockRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));
      await container.read(homeWeatherProvider.notifier).retry();

      expect(container.read(homeWeatherProvider).hasError, isTrue);
      verifyNever(
        () => mockCacheRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      );
    });

    test(
      'a cached snapshot is never re-stamped as fresh when turned on',
      () async {
        when(() => mockSettingsRepository.getSettings()).thenAnswer(
          (_) async => const Right(
            AppSettings(
              temperatureUnit: TemperatureUnit.celsius,
              themeMode: AppThemeMode.system,
              offlineDataEnabled: false,
            ),
          ),
        );
        final container = build();
        container.listen(homeWeatherProvider, (_, _) {});
        await container.read(homeWeatherProvider.future);
        container
            .read(currentWeatherFreshnessProvider.notifier)
            .report(
              WeatherFreshness(
                isFromCache: true,
                fetchedAt: DateTime.utc(2026, 9, 1),
              ),
            );

        await container
            .read(settingsProvider.notifier)
            .setOfflineDataEnabled(true);
        await pumpEvents();

        verifyNever(
          () => mockCacheRepository.saveCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            weather: any(named: 'weather'),
            fetchedAt: any(named: 'fetchedAt'),
            cityName: any(named: 'cityName'),
            country: any(named: 'country'),
          ),
        );
      },
    );
  });
}
