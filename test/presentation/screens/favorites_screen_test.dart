import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/cache_failures.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/location/location_permission_status.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/app_settings.dart';
import 'package:weather_now_flutter/domain/repositories/settings_repository.dart';
import 'package:weather_now_flutter/domain/entities/cached_current_weather.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/favorites_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_cache_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/presentation/screens/favorites_screen.dart';

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

class MockWeatherCacheRepository extends Mock
    implements WeatherCacheRepository {}

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockFavoritesRepository mockFavoritesRepository;
  late MockWeatherCacheRepository mockWeatherCacheRepository;
  late MockWeatherRepository mockWeatherRepository;

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

  final puneWeather = CurrentWeather(
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
    registerFallbackValue(puneWeather);
  });

  setUp(() {
    mockFavoritesRepository = MockFavoritesRepository();
    mockWeatherCacheRepository = MockWeatherCacheRepository();
    mockWeatherRepository = MockWeatherRepository();
    when(
      () => mockWeatherCacheRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(null));
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
  });

  Widget buildSubject({ValueChanged<CitySuggestion>? onCitySelected}) {
    return ProviderScope(
      overrides: [
        favoritesRepositoryProvider.overrideWithValue(mockFavoritesRepository),
        weatherCacheRepositoryProvider.overrideWithValue(
          mockWeatherCacheRepository,
        ),
        weatherRepositoryProvider.overrideWithValue(mockWeatherRepository),
      ],
      child: MaterialApp(home: FavoritesScreen(onCitySelected: onCitySelected)),
    );
  }

  testWidgets('shows a loading indicator, then the saved favorites', (
    tester,
  ) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune, mumbai]));

    await tester.pumpWidget(buildSubject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Pune'), findsOneWidget);
    expect(find.text('Mumbai'), findsOneWidget);
    // Both share the same state, shown once per card as the subtitle.
    expect(find.text('Maharashtra'), findsNWidgets(2));
  });

  testWidgets('shows an empty state when there are no favorites', (
    tester,
  ) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('No favorite cities yet'), findsOneWidget);
  });

  testWidgets('shows an error view with retry when favorites fail to load', (
    tester,
  ) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Left(CacheFailure('disk error')));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Failed to load favorites.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping the yellow star removes the favorite from the list', (
    tester,
  ) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune, mumbai]));
    when(
      () => mockFavoritesRepository.removeFavorite(pune),
    ).thenAnswer((_) async => const Right(unit));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final starIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(Key('removeFavorite_${pune.name}_${pune.country}')),
        matching: find.byType(Icon),
      ),
    );
    expect(starIcon.icon, Icons.star);

    final starButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(Key('removeFavorite_${pune.name}_${pune.country}')),
        matching: find.byType(IconButton),
      ),
    );
    expect(starButton.color, Colors.amber);

    await tester.tap(
      find.byKey(Key('removeFavorite_${pune.name}_${pune.country}')),
    );
    await tester.pump();

    expect(find.text('Pune'), findsNothing);
    expect(find.text('Mumbai'), findsOneWidget);
    verify(() => mockFavoritesRepository.removeFavorite(pune)).called(1);
  });

  testWidgets(
    'the three-dot menu offers to set as Home and remove from favorites',
    (tester) async {
      when(
        () => mockFavoritesRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([pune]));
      when(
        () => mockFavoritesRepository.removeFavorite(pune),
      ).thenAnswer((_) async => const Right(unit));

      CitySuggestion? selected;
      await tester.pumpWidget(
        buildSubject(onCitySelected: (city) => selected = city),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(Key('favoriteMenu_${pune.name}_${pune.country}')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set as Home location'), findsOneWidget);
      expect(find.text('Remove from Favorites'), findsOneWidget);

      await tester.tap(find.text('Set as Home location'));
      await tester.pumpAndSettle();
      expect(selected, pune);

      await tester.tap(
        find.byKey(Key('favoriteMenu_${pune.name}_${pune.country}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Favorites'));
      await tester.pump();

      verify(() => mockFavoritesRepository.removeFavorite(pune)).called(1);
    },
  );

  testWidgets('the three-dot menu offers only Remove from Favorites when no '
      'onCitySelected is given, since there is nowhere to "set as Home" to', (
    tester,
  ) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune]));
    when(
      () => mockFavoritesRepository.removeFavorite(pune),
    ).thenAnswer((_) async => const Right(unit));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(Key('favoriteMenu_${pune.name}_${pune.country}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set as Home location'), findsNothing);
    expect(find.text('Remove from Favorites'), findsOneWidget);

    await tester.tap(find.text('Remove from Favorites'));
    await tester.pump();

    verify(() => mockFavoritesRepository.removeFavorite(pune)).called(1);
  });

  testWidgets('shows the cached weather for a favorite when available', (
    tester,
  ) async {
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
          weather: puneWeather,
          fetchedAt: DateTime(2026, 9, 18, 9, 0),
        ),
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('28°'), findsOneWidget);
    expect(find.textContaining('cached'), findsOneWidget);
  });

  testWidgets('shows a placeholder when a favorite has no cached weather', (
    tester,
  ) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune]));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('No cached weather yet'), findsOneWidget);
  });

  testWidgets('tapping a favorite invokes onCitySelected with that city', (
    tester,
  ) async {
    when(
      () => mockFavoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune]));

    CitySuggestion? selected;
    await tester.pumpWidget(
      buildSubject(onCitySelected: (city) => selected = city),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pune'));

    expect(selected, pune);
  });

  group('Offline Access section', () {
    testWidgets('shows a generic message when nothing has been cached yet', (
      tester,
    ) async {
      when(
        () => mockFavoritesRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([pune]));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('offlineAccessSection')), findsOneWidget);
      expect(find.byKey(const Key('syncFavoritesButton')), findsOneWidget);
      expect(
        find.text('Your favorites will be cached here for offline access.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the most recent cache time across all favorites', (
      tester,
    ) async {
      when(
        () => mockFavoritesRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([pune, mumbai]));
      when(
        () => mockWeatherCacheRepository.getCurrentWeather(
          latitude: pune.latitude,
          longitude: pune.longitude,
        ),
      ).thenAnswer(
        (_) async => Right(
          CachedCurrentWeather(
            weather: puneWeather,
            fetchedAt: DateTime(2026, 9, 18, 8, 0),
          ),
        ),
      );
      when(
        () => mockWeatherCacheRepository.getCurrentWeather(
          latitude: mumbai.latitude,
          longitude: mumbai.longitude,
        ),
      ).thenAnswer(
        (_) async => Right(
          CachedCurrentWeather(
            weather: puneWeather,
            fetchedAt: DateTime(2026, 9, 18, 10, 0),
          ),
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('Last updated'), findsOneWidget);
    });

    testWidgets(
      'tapping Sync Now re-fetches and re-caches weather for every favorite',
      (tester) async {
        when(
          () => mockFavoritesRepository.getFavorites(),
        ).thenAnswer((_) async => const Right([pune, mumbai]));
        when(
          () => mockWeatherRepository.getCurrentWeather(
            latitude: pune.latitude,
            longitude: pune.longitude,
          ),
        ).thenAnswer((_) async => Right(puneWeather));
        when(
          () => mockWeatherRepository.getCurrentWeather(
            latitude: mumbai.latitude,
            longitude: mumbai.longitude,
          ),
        ).thenAnswer((_) async => Right(puneWeather));
        // A real cache would return what was just saved; the mock's default
        // `setUp` stub always answers `null`, so fake a minimal in-memory
        // store here to let the "Last updated" read reflect the sync's
        // writes.
        final cacheStore = <String, CachedCurrentWeather>{};
        String keyFor(double lat, double lng) => '$lat,$lng';
        when(
          () => mockWeatherCacheRepository.getCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((invocation) async {
          final lat = invocation.namedArguments[#latitude] as double;
          final lng = invocation.namedArguments[#longitude] as double;
          return Right(cacheStore[keyFor(lat, lng)]);
        });
        when(
          () => mockWeatherCacheRepository.saveCurrentWeather(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            weather: any(named: 'weather'),
            fetchedAt: any(named: 'fetchedAt'),
            cityName: any(named: 'cityName'),
            country: any(named: 'country'),
          ),
        ).thenAnswer((invocation) async {
          final lat = invocation.namedArguments[#latitude] as double;
          final lng = invocation.namedArguments[#longitude] as double;
          final weather = invocation.namedArguments[#weather] as CurrentWeather;
          final fetchedAt = invocation.namedArguments[#fetchedAt] as DateTime;
          cacheStore[keyFor(lat, lng)] = CachedCurrentWeather(
            weather: weather,
            fetchedAt: fetchedAt,
          );
          return const Right(unit);
        });

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('syncFavoritesButton')));
        await tester.pumpAndSettle();

        verify(
          () => mockWeatherCacheRepository.saveCurrentWeather(
            latitude: pune.latitude,
            longitude: pune.longitude,
            weather: puneWeather,
            fetchedAt: any(named: 'fetchedAt'),
            cityName: pune.name,
            country: pune.country,
          ),
        ).called(1);
        verify(
          () => mockWeatherCacheRepository.saveCurrentWeather(
            latitude: mumbai.latitude,
            longitude: mumbai.longitude,
            weather: puneWeather,
            fetchedAt: any(named: 'fetchedAt'),
            cityName: mumbai.name,
            country: mumbai.country,
          ),
        ).called(1);
        expect(find.textContaining('Last updated'), findsOneWidget);
      },
    );

    testWidgets(
      'shows a loading indicator on the sync button while syncing and '
      'disables it',
      (tester) async {
        when(
          () => mockFavoritesRepository.getFavorites(),
        ).thenAnswer((_) async => const Right([pune]));
        final completer =
            Completer<Either<RemoteDataFailure, CurrentWeather>>();
        when(
          () => mockWeatherRepository.getCurrentWeather(
            latitude: pune.latitude,
            longitude: pune.longitude,
          ),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('syncFavoritesButton')));
        await tester.pump();

        expect(find.text('Syncing…'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );

        completer.complete(Right(puneWeather));
        await tester.pumpAndSettle();

        expect(find.text('Sync Now'), findsOneWidget);
      },
    );

    testWidgets('shows offline feedback when every favorite fails to sync', (
      tester,
    ) async {
      when(
        () => mockFavoritesRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([pune]));
      when(
        () => mockWeatherRepository.getCurrentWeather(
          latitude: pune.latitude,
          longitude: pune.longitude,
        ),
      ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('syncFavoritesButton')));
      await tester.pumpAndSettle();

      expect(
        find.text("You're offline — showing your last saved weather."),
        findsOneWidget,
      );
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
  });

  group('bottom navigation', () {
    testWidgets('shows the bottom nav bar with Favorites selected', (
      tester,
    ) async {
      when(
        () => mockFavoritesRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // "Favorites" also appears once as the AppBar title, so this counts
      // both rather than assuming a single instance.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Favorites'), findsNWidgets(2));
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('has no back button and navigates between tabs', (
      tester,
    ) async {
      when(
        () => mockFavoritesRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([]));
      final mockSettingsRepository = MockSettingsRepository();
      final mockLocationService = MockLocationService();
      when(
        () => mockSettingsRepository.getSettings(),
      ).thenAnswer((_) async => const Right(AppSettings.defaults));
      when(
        () => mockLocationService.checkPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.granted);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesRepositoryProvider.overrideWithValue(
              mockFavoritesRepository,
            ),
            weatherCacheRepositoryProvider.overrideWithValue(
              mockWeatherCacheRepository,
            ),
            weatherRepositoryProvider.overrideWithValue(mockWeatherRepository),
            settingsRepositoryProvider.overrideWithValue(
              mockSettingsRepository,
            ),
            locationServiceProvider.overrideWithValue(mockLocationService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
                child: const Text('placeholder-home'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('placeholder-home'));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Units'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      // Home from Settings goes straight to the root, not back to Favorites.
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('placeholder-home'), findsOneWidget);
    });

    testWidgets('tapping Home in the bottom nav pops back', (tester) async {
      when(
        () => mockFavoritesRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesRepositoryProvider.overrideWithValue(
              mockFavoritesRepository,
            ),
            weatherCacheRepositoryProvider.overrideWithValue(
              mockWeatherCacheRepository,
            ),
            weatherRepositoryProvider.overrideWithValue(mockWeatherRepository),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    ),
                    child: const Text('placeholder-home'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('placeholder-home'));
      await tester.pumpAndSettle();
      expect(find.text('Favorites'), findsWidgets);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('placeholder-home'), findsOneWidget);
    });
  });

  group('responsive layout', () {
    testWidgets('lays out without overflow on a small phone width', (
      tester,
    ) async {
      when(
        () => mockFavoritesRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([pune, mumbai]));

      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('caps content width on a tablet-width screen', (tester) async {
      when(
        () => mockFavoritesRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([pune, mumbai]));

      await tester.binding.setSurfaceSize(const Size(1024, 900));
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.byKey(const Key('favoritesContentConstraint')),
      );
      expect(constrainedBox.constraints.maxWidth, lessThan(1024));

      await tester.binding.setSurfaceSize(null);
    });
  });
}
