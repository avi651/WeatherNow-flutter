import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/failures.dart';
import 'package:weather_now_flutter/core/error/location_failures.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/cached_current_weather.dart';
import 'package:weather_now_flutter/domain/entities/cached_forecast.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/forecast.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/repositories/favorites_repository.dart';
import 'package:weather_now_flutter/domain/repositories/geocoding_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_cache_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/presentation/screens/home_screen.dart';
import 'package:weather_now_flutter/presentation/widgets/current_weather_hero_card.dart';
import 'package:weather_now_flutter/presentation/widgets/favorite_star_button.dart';
import 'package:weather_now_flutter/presentation/widgets/weather_error_view.dart';
import 'package:weather_now_flutter/presentation/widgets/weather_loading_view.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockLocationService extends Mock implements LocationService {}

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

class MockWeatherCacheRepository extends Mock implements WeatherCacheRepository {}

void main() {
  late MockWeatherRepository mockRepository;
  late MockLocationService mockLocationService;
  late MockGeocodingRepository mockGeocodingRepository;
  late MockFavoritesRepository mockFavoritesRepository;
  late MockWeatherCacheRepository mockWeatherCacheRepository;

  const location = DeviceLocation(latitude: 12.9716, longitude: 77.5946);

  const london = CitySuggestion(
    name: 'London',
    state: 'England',
    country: 'GB',
    latitude: 51.5072,
    longitude: -0.1276,
  );

  const bengaluru = CitySuggestion(
    name: 'Bengaluru',
    state: 'Karnataka',
    country: 'IN',
    latitude: 12.9716,
    longitude: 77.5946,
  );

  final weather = CurrentWeather(
    temperatureCelsius: 27.6,
    feelsLikeCelsius: 31.0,
    humidityPercent: 68,
    pressureHpa: 1013,
    windSpeedMetersPerSecond: 3.4,
    condition: WeatherCondition.clouds,
    description: 'Partly Cloudy',
    observedAt: DateTime.utc(2026, 9, 16),
  );

  final forecast = Forecast(entries: [
    ForecastEntry(
      forecastFor: DateTime.utc(2026, 9, 16, 12),
      temperatureCelsius: 28,
      feelsLikeCelsius: 30,
      humidityPercent: 60,
      condition: WeatherCondition.clear,
      description: 'clear sky',
      precipitationProbability: 0.1,
    ),
  ]);

  setUpAll(() {
    registerFallbackValue(weather);
    registerFallbackValue(forecast);
    registerFallbackValue(bengaluru);
  });

  setUp(() {
    mockRepository = MockWeatherRepository();
    mockLocationService = MockLocationService();
    mockGeocodingRepository = MockGeocodingRepository();
    mockFavoritesRepository = MockFavoritesRepository();
    mockWeatherCacheRepository = MockWeatherCacheRepository();
    // Default: location resolves successfully. Individual tests override
    // this when they specifically want to exercise a location failure.
    when(() => mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => const Right(location));
    // Default: reverse geocoding the device location resolves to Bengaluru.
    // Individual tests override this when they specifically want to
    // exercise a reverse-geocoding failure.
    when(
      () => mockGeocodingRepository.reverseGeocode(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(bengaluru));
    // Favorites/cache aren't under test here — a mocked, no-op-but-real
    // Either keeps this file off real Hive I/O (a real box *write* never
    // resolves under `testWidgets`' fake-async pump clock).
    when(() => mockFavoritesRepository.getFavorites())
        .thenAnswer((_) async => const Right([]));
    when(() => mockFavoritesRepository.addFavorite(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => mockFavoritesRepository.removeFavorite(any()))
        .thenAnswer((_) async => const Right(unit));
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
      () => mockWeatherCacheRepository.saveForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        forecast: any(named: 'forecast'),
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
    when(
      () => mockWeatherCacheRepository.getForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(null));
  });

  void stubWeatherSuccess() {
    when(
      () => mockRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Right(weather));
    when(
      () => mockRepository.getForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Right(forecast));
  }

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        weatherRepositoryProvider.overrideWithValue(mockRepository),
        locationServiceProvider.overrideWithValue(mockLocationService),
        geocodingRepositoryProvider.overrideWithValue(mockGeocodingRepository),
        favoritesRepositoryProvider.overrideWithValue(mockFavoritesRepository),
        weatherCacheRepositoryProvider.overrideWithValue(mockWeatherCacheRepository),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  testWidgets('shows a loading indicator, then the weather on success',
      (tester) async {
    stubWeatherSuccess();

    await tester.pumpWidget(buildSubject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Partly Cloudy'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    // The device location is reverse-geocoded into an actual city name by
    // default, rather than showing a generic "Current Location" label —
    // shown on both the hero card and, passively, the search field itself.
    expect(
      find.descendant(
        of: find.byType(CurrentWeatherHeroCard),
        matching: find.text('Bengaluru'),
      ),
      findsOneWidget,
    );
    expect(find.text('IN'), findsOneWidget);
  });

  testWidgets('shows an error view with retry when weather fetch fails',
      (tester) async {
    when(
      () => mockRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));
    when(
      () => mockRepository.getForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Right(forecast));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
    'falls back to cached weather and shows an offline banner when the '
    'live fetch fails but a cache exists',
    (tester) async {
      when(
        () => mockRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));
      when(
        () => mockRepository.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(forecast));
      final cachedAt = DateTime(2026, 9, 17, 8, 0);
      when(
        () => mockWeatherCacheRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer(
        (_) async => Right(CachedCurrentWeather(weather: weather, fetchedAt: cachedAt)),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Partly Cloudy'), findsOneWidget);
      expect(find.byKey(const Key('offlineBanner')), findsOneWidget);
      expect(find.textContaining("You're offline"), findsOneWidget);
    },
  );

  testWidgets(
    'falls back to cached forecast and shows an offline banner when only the '
    'forecast fetch fails, even though current weather succeeds live',
    (tester) async {
      when(
        () => mockRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(weather));
      when(
        () => mockRepository.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));
      final cachedAt = DateTime(2026, 9, 17, 8, 0);
      when(
        () => mockWeatherCacheRepository.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer(
        (_) async => Right(CachedForecast(forecast: forecast, fetchedAt: cachedAt)),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Current weather is live and fine, but the forecast is a stale cache
      // snapshot — the banner must still surface that, not be hidden by the
      // current weather's live (non-cached) freshness report.
      expect(find.text('Partly Cloudy'), findsOneWidget);
      expect(find.byKey(const Key('offlineBanner')), findsOneWidget);
      expect(find.textContaining("You're offline"), findsOneWidget);
    },
  );

  testWidgets('shows an error view with retry when location permission is denied',
      (tester) async {
    when(() => mockLocationService.getCurrentLocation()).thenAnswer(
      (_) async => const Left(
        LocationPermissionDeniedFailure('Location permission was denied.'),
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Location permission was denied.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping retry re-fetches and shows the weather', (tester) async {
    when(
      () => mockRepository.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));
    when(
      () => mockRepository.getForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Right(forecast));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    stubWeatherSuccess();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Partly Cloudy'), findsOneWidget);
  });

  testWidgets('tapping the favorite star toggles its icon', (tester) async {
    stubWeatherSuccess();

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Scoped to FavoriteStarButton: BottomNavBar's "Favorites" destination
    // also renders a static Icons.star_border, which `find.byIcon` alone
    // would also match.
    final favoriteStarIcon = find.descendant(
      of: find.byType(FavoriteStarButton),
      matching: find.byIcon(Icons.star_border),
    );
    expect(favoriteStarIcon, findsOneWidget);

    await tester.tap(favoriteStarIcon);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(FavoriteStarButton),
        matching: find.byIcon(Icons.star),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(FavoriteStarButton),
        matching: find.byIcon(Icons.star_border),
      ),
      findsNothing,
    );
  });

  testWidgets('caps content width on a tablet-width screen', (tester) async {
    stubWeatherSuccess();

    await tester.binding.setSurfaceSize(const Size(1024, 900));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final constrainedBox = tester.widget<ConstrainedBox>(
      find.byKey(const Key('homeContentConstraint')),
    );

    expect(
      constrainedBox.constraints.maxWidth,
      lessThan(1024),
    );

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('lays out without overflow on a small phone width',
      (tester) async {
    stubWeatherSuccess();

    await tester.binding.setSurfaceSize(const Size(320, 640));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('lays out without overflow on a large tablet width',
      (tester) async {
    stubWeatherSuccess();

    await tester.binding.setSurfaceSize(const Size(1366, 1024));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'selecting a searched city re-fetches weather for it and updates the hero card',
    (tester) async {
      stubWeatherSuccess();
      when(
        () => mockGeocodingRepository.searchCities(query: 'Lon'),
      ).thenAnswer((_) async => const Right([london]));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('citySearchTextField')));
      await tester.enterText(find.byKey(const Key('citySearchTextField')), 'Lon');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.text(london.displayLabel));
      await tester.pumpAndSettle();

      // Shown on both the hero card and, kept visible, the search field itself.
      expect(
        find.descendant(
          of: find.byType(CurrentWeatherHeroCard),
          matching: find.text('London'),
        ),
        findsOneWidget,
      );
      expect(find.text('GB'), findsOneWidget);
      final textField = tester.widget<TextField>(
        find.byKey(const Key('citySearchTextField')),
      );
      expect(textField.controller!.text, 'London');
      verify(
        () => mockRepository.getCurrentWeather(latitude: 51.5072, longitude: -0.1276),
      ).called(1);
    },
  );

  testWidgets(
    'tapping use-my-location after selecting a city reverts to the device location',
    (tester) async {
      stubWeatherSuccess();
      when(
        () => mockGeocodingRepository.searchCities(query: 'Lon'),
      ).thenAnswer((_) async => const Right([london]));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('citySearchTextField')));
      await tester.enterText(find.byKey(const Key('citySearchTextField')), 'Lon');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text(london.displayLabel));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('useMyLocationButton')));
      await tester.pumpAndSettle();

      // Reverts to the device location, reverse-geocoded to its actual
      // city name (not a generic "Current Location" label) — shown on
      // both the hero card and, passively, the search field itself.
      expect(
        find.descendant(
          of: find.byType(CurrentWeatherHeroCard),
          matching: find.text('Bengaluru'),
        ),
        findsOneWidget,
      );
      expect(find.text('London'), findsNothing);
      // Once for the initial load, once after reverting from the searched city.
      verify(
        () => mockRepository.getCurrentWeather(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      ).called(2);
    },
  );

  testWidgets(
    'tapping use-my-location re-requests the device location from the '
    'location service instead of reusing the one resolved at app launch',
    (tester) async {
      var locationCallCount = 0;
      when(() => mockLocationService.getCurrentLocation()).thenAnswer((_) async {
        locationCallCount++;
        return const Right(location);
      });
      stubWeatherSuccess();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(locationCallCount, 1);

      await tester.tap(find.byKey(const Key('useMyLocationButton')));
      await tester.pumpAndSettle();

      expect(
        locationCallCount,
        2,
        reason: 'tapping the location button must ask the location service '
            'for a fresh fix, not just reuse the one from app launch',
      );
    },
  );

  testWidgets(
    'tapping use-my-location surfaces a fresh location failure (e.g. '
    'permission revoked) as a snackbar, keeping the previous weather on '
    'screen instead of replacing it with the full-screen error view',
    (tester) async {
      var locationCallCount = 0;
      when(() => mockLocationService.getCurrentLocation()).thenAnswer((_) async {
        locationCallCount++;
        if (locationCallCount == 1) return const Right(location);
        return const Left(
          LocationPermissionDeniedFailure('Location permission was denied.'),
        );
      });
      stubWeatherSuccess();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('Partly Cloudy'), findsOneWidget);

      await tester.tap(find.byKey(const Key('useMyLocationButton')));
      await tester.pumpAndSettle();

      // The rest of the app — including the previously-loaded weather —
      // stays put; only a transient snackbar reports the failure.
      expect(find.byType(WeatherErrorView), findsNothing);
      expect(find.text('Partly Cloudy'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Location permission was denied.'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping use-my-location shows a loading indicator only on the button '
    '— never the full-screen loader — keeps the rest of the UI visible, '
    'and disables the button so a second tap does not fire a duplicate '
    'request',
    (tester) async {
      final locationCompleter = Completer<Either<Failure, DeviceLocation>>();
      var locationCallCount = 0;
      when(() => mockLocationService.getCurrentLocation()).thenAnswer((_) {
        locationCallCount++;
        if (locationCallCount == 1) {
          return Future.value(const Right(location));
        }
        return locationCompleter.future;
      });
      stubWeatherSuccess();

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('Partly Cloudy'), findsOneWidget);

      await tester.tap(find.byKey(const Key('useMyLocationButton')));
      await tester.pump();

      // Mid-flight: no full-screen loader, previous weather still shown,
      // and the button itself carries its own small indicator.
      expect(find.byType(WeatherLoadingView), findsNothing);
      expect(find.text('Partly Cloudy'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('useMyLocationButton')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      // A second tap while still loading must not issue another request.
      await tester.tap(find.byKey(const Key('useMyLocationButton')));
      await tester.pump();
      expect(locationCallCount, 2);

      locationCompleter.complete(const Right(location));
      await tester.pumpAndSettle();

      expect(find.text('Partly Cloudy'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('useMyLocationButton')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'falls back to a generic label when reverse geocoding fails, without '
    'breaking the weather fetch',
    (tester) async {
      stubWeatherSuccess();
      when(
        () => mockGeocodingRepository.reverseGeocode(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(RemoteDataFailure('No match found')));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Current Location'), findsOneWidget);
      expect(find.text('Partly Cloudy'), findsOneWidget);
    },
  );
}
