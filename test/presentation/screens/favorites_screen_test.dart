import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/cache_failures.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/cached_current_weather.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/favorites_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_cache_repository.dart';
import 'package:weather_now_flutter/presentation/screens/favorites_screen.dart';

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

class MockWeatherCacheRepository extends Mock implements WeatherCacheRepository {}

void main() {
  late MockFavoritesRepository mockFavoritesRepository;
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

  setUpAll(() {
    registerFallbackValue(pune);
  });

  setUp(() {
    mockFavoritesRepository = MockFavoritesRepository();
    mockWeatherCacheRepository = MockWeatherCacheRepository();
    when(
      () => mockWeatherCacheRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(null));
  });

  Widget buildSubject({ValueChanged<CitySuggestion>? onCitySelected}) {
    return ProviderScope(
      overrides: [
        favoritesRepositoryProvider.overrideWithValue(mockFavoritesRepository),
        weatherCacheRepositoryProvider.overrideWithValue(mockWeatherCacheRepository),
      ],
      child: MaterialApp(home: FavoritesScreen(onCitySelected: onCitySelected)),
    );
  }

  testWidgets('shows a loading indicator, then the saved favorites',
      (tester) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune, mumbai]));

    await tester.pumpWidget(buildSubject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text(pune.displayLabel), findsOneWidget);
    expect(find.text(mumbai.displayLabel), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no favorites',
      (tester) async {
    when(() => mockFavoritesRepository.getFavorites()).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('No favorite cities yet'), findsOneWidget);
  });

  testWidgets('shows an error view with retry when favorites fail to load',
      (tester) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Left(CacheFailure('disk error')));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Failed to load favorites.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping remove deletes the favorite from the list',
      (tester) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune, mumbai]));
    when(
      () => mockFavoritesRepository.removeFavorite(pune),
    ).thenAnswer((_) async => const Right(unit));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('removeFavorite_${pune.name}_${pune.country}')));
    await tester.pump();

    expect(find.text(pune.displayLabel), findsNothing);
    expect(find.text(mumbai.displayLabel), findsOneWidget);
    verify(() => mockFavoritesRepository.removeFavorite(pune)).called(1);
  });

  testWidgets('shows the cached weather for a favorite when available',
      (tester) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune]));
    when(
      () => mockWeatherCacheRepository.getCurrentWeather(
        latitude: pune.latitude,
        longitude: pune.longitude,
      ),
    ).thenAnswer(
      (_) async => Right(
        CachedCurrentWeather(
          weather: CurrentWeather(
            temperatureCelsius: 28,
            feelsLikeCelsius: 30,
            humidityPercent: 55,
            pressureHpa: 1010,
            windSpeedMetersPerSecond: 2,
            condition: WeatherCondition.clear,
            description: 'clear sky',
            observedAt: DateTime.utc(2026, 9, 18),
          ),
          fetchedAt: DateTime(2026, 9, 18, 9, 0),
        ),
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('28°'), findsOneWidget);
    expect(find.textContaining('cached'), findsOneWidget);
  });

  testWidgets('shows a placeholder when a favorite has no cached weather',
      (tester) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune]));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('No cached weather yet'), findsOneWidget);
  });

  testWidgets('tapping a favorite invokes onCitySelected with that city',
      (tester) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune]));

    CitySuggestion? selected;
    await tester.pumpWidget(buildSubject(onCitySelected: (city) => selected = city));
    await tester.pumpAndSettle();

    await tester.tap(find.text(pune.displayLabel));

    expect(selected, pune);
  });
}
