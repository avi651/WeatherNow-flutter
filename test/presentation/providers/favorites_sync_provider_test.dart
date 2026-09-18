import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/cached_current_weather.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/favorites_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_cache_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/presentation/providers/favorite_cached_weather_provider.dart';
import 'package:weather_now_flutter/presentation/providers/favorite_provider.dart';
import 'package:weather_now_flutter/presentation/providers/favorites_sync_provider.dart';

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockWeatherCacheRepository extends Mock implements WeatherCacheRepository {}

void main() {
  late MockFavoritesRepository mockFavoritesRepository;
  late MockWeatherRepository mockWeatherRepository;
  late MockWeatherCacheRepository mockWeatherCacheRepository;

  const pune = CitySuggestion(
    name: 'Pune',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 18.5213738,
    longitude: 73.8545071,
  );

  const mumbai = CitySuggestion(
    name: 'Mumbai',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 19.0760,
    longitude: 72.8777,
  );

  final weather = CurrentWeather(
    temperatureCelsius: 28,
    feelsLikeCelsius: 30,
    humidityPercent: 55,
    pressureHpa: 1010,
    windSpeedMetersPerSecond: 2,
    condition: WeatherCondition.clear,
    description: 'clear sky',
    observedAt: DateTime.utc(2026, 9, 18),
  );

  setUpAll(() {
    registerFallbackValue(pune);
    registerFallbackValue(weather);
  });

  setUp(() {
    mockFavoritesRepository = MockFavoritesRepository();
    mockWeatherRepository = MockWeatherRepository();
    mockWeatherCacheRepository = MockWeatherCacheRepository();
    when(
      () => mockWeatherCacheRepository.saveCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        weather: any(named: 'weather'),
        fetchedAt: any(named: 'fetchedAt'),
        cityName: any(named: 'cityName'),
        country: any(named: 'country'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => mockWeatherCacheRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(null));
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        favoritesRepositoryProvider.overrideWithValue(mockFavoritesRepository),
        weatherRepositoryProvider.overrideWithValue(mockWeatherRepository),
        weatherCacheRepositoryProvider.overrideWithValue(mockWeatherCacheRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('does nothing when there are no favorites', () async {
    when(() => mockFavoritesRepository.getFavorites()).thenAnswer((_) async => const Right([]));

    final container = buildContainer();
    await container.read(favoritesProvider.future);
    await container.read(favoritesSyncProvider.notifier).sync();

    expect(container.read(favoritesSyncProvider).hasError, isFalse);
    verifyNever(
      () => mockWeatherRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    );
  });

  test('fetches and caches fresh weather for every favorite', () async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune, mumbai]));
    when(
      () => mockWeatherRepository.getCurrentWeather(
        latitude: pune.latitude,
        longitude: pune.longitude,
      ),
    ).thenAnswer((_) async => Right(weather));
    when(
      () => mockWeatherRepository.getCurrentWeather(
        latitude: mumbai.latitude,
        longitude: mumbai.longitude,
      ),
    ).thenAnswer((_) async => Right(weather));

    final container = buildContainer();
    await container.read(favoritesProvider.future);
    await container.read(favoritesSyncProvider.notifier).sync();

    expect(container.read(favoritesSyncProvider).hasError, isFalse);
    verify(
      () => mockWeatherCacheRepository.saveCurrentWeather(
        latitude: pune.latitude,
        longitude: pune.longitude,
        weather: weather,
        fetchedAt: any(named: 'fetchedAt'),
        cityName: pune.name,
        country: pune.country,
      ),
    ).called(1);
    verify(
      () => mockWeatherCacheRepository.saveCurrentWeather(
        latitude: mumbai.latitude,
        longitude: mumbai.longitude,
        weather: weather,
        fetchedAt: any(named: 'fetchedAt'),
        cityName: mumbai.name,
        country: mumbai.country,
      ),
    ).called(1);
  });

  test('reports loading while syncing is in progress', () async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune]));
    when(
      () => mockWeatherRepository.getCurrentWeather(
        latitude: pune.latitude,
        longitude: pune.longitude,
      ),
    ).thenAnswer((_) async => Right(weather));

    final container = buildContainer();
    await container.read(favoritesProvider.future);

    final syncFuture = container.read(favoritesSyncProvider.notifier).sync();
    expect(container.read(favoritesSyncProvider), isA<AsyncLoading<void>>());

    await syncFuture;
  });

  test(
    'skips a favorite whose fetch fails but still succeeds and caches the '
    'rest',
    () async {
      when(
        () => mockFavoritesRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([pune, mumbai]));
      when(
        () => mockWeatherRepository.getCurrentWeather(
          latitude: pune.latitude,
          longitude: pune.longitude,
        ),
      ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));
      when(
        () => mockWeatherRepository.getCurrentWeather(
          latitude: mumbai.latitude,
          longitude: mumbai.longitude,
        ),
      ).thenAnswer((_) async => Right(weather));

      final container = buildContainer();
      await container.read(favoritesProvider.future);
      await container.read(favoritesSyncProvider.notifier).sync();

      expect(container.read(favoritesSyncProvider).hasError, isFalse);
      verifyNever(
        () => mockWeatherCacheRepository.saveCurrentWeather(
          latitude: pune.latitude,
          longitude: pune.longitude,
          weather: any(named: 'weather'),
          fetchedAt: any(named: 'fetchedAt'),
          cityName: any(named: 'cityName'),
          country: any(named: 'country'),
        ),
      );
      verify(
        () => mockWeatherCacheRepository.saveCurrentWeather(
          latitude: mumbai.latitude,
          longitude: mumbai.longitude,
          weather: weather,
          fetchedAt: any(named: 'fetchedAt'),
          cityName: mumbai.name,
          country: mumbai.country,
        ),
      ).called(1);
    },
  );

  test('reports an error when every favorite fails to sync', () async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune, mumbai]));
    when(
      () => mockWeatherRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));

    final container = buildContainer();
    await container.read(favoritesProvider.future);
    await container.read(favoritesSyncProvider.notifier).sync();

    expect(container.read(favoritesSyncProvider).hasError, isTrue);
    verifyNever(
      () => mockWeatherCacheRepository.saveCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        weather: any(named: 'weather'),
        fetchedAt: any(named: 'fetchedAt'),
        cityName: any(named: 'cityName'),
        country: any(named: 'country'),
      ),
    );
  });

  test('invalidates cached favorite weather reads after syncing', () async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune]));
    when(
      () => mockWeatherRepository.getCurrentWeather(
        latitude: pune.latitude,
        longitude: pune.longitude,
      ),
    ).thenAnswer((_) async => Right(weather));

    final container = buildContainer();
    await container.read(favoritesProvider.future);

    // Read once so the family provider has a cached (stale, null) result.
    await container.read(favoriteCachedWeatherProvider(pune).future);

    // Simulate the cache now actually holding what the sync just saved.
    when(
      () => mockWeatherCacheRepository.getCurrentWeather(
        latitude: pune.latitude,
        longitude: pune.longitude,
      ),
    ).thenAnswer(
      (_) async => Right(CachedCurrentWeather(weather: weather, fetchedAt: DateTime.now())),
    );

    await container.read(favoritesSyncProvider.notifier).sync();

    final refreshed = await container.read(favoriteCachedWeatherProvider(pune).future);
    expect(refreshed, isNotNull);
    expect(refreshed!.weather, weather);
  });
}
