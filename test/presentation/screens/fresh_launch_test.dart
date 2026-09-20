import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/core/network/connectivity_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/forecast.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/favorites_repository.dart';
import 'package:weather_now_flutter/domain/repositories/geocoding_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_cache_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_repository.dart';
import 'package:weather_now_flutter/presentation/screens/home_screen.dart';

import '../utils/location_test_overrides.dart';

class _MockWeatherRepository extends Mock implements WeatherRepository {}

class _MockLocationService extends Mock implements LocationService {}

class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

class _MockCacheRepository extends Mock implements WeatherCacheRepository {}

class _OnlineConnectivity implements ConnectivityService {
  @override
  Future<bool> checkOnline() async => true;

  @override
  Stream<bool> get onlineChanges => const Stream.empty();
}

/// Fresh install (nothing saved) launching the Home screen, with only the
/// network/platform edges faked. Uses coordinates and a city that appear
/// nowhere else in the app, so any static fallback would fail the test.
void main() {
  const device = DeviceLocation(latitude: -33.8688, longitude: 151.2093);
  const detected = CitySuggestion(
    name: 'Sydney',
    country: 'AU',
    latitude: -33.8688,
    longitude: 151.2093,
  );

  late _MockWeatherRepository weatherRepository;
  late _MockLocationService locationService;
  late _MockGeocodingRepository geocoding;

  final weather = CurrentWeather(
    temperatureCelsius: 19,
    feelsLikeCelsius: 18,
    humidityPercent: 60,
    pressureHpa: 1015,
    windSpeedMetersPerSecond: 3,
    condition: WeatherCondition.clear,
    description: 'Sunny Spells',
    observedAt: DateTime.utc(2026, 9, 20),
  );
  final forecast = Forecast(
    entries: [
      ForecastEntry(
        forecastFor: DateTime.utc(2026, 9, 20, 12),
        temperatureCelsius: 20,
        feelsLikeCelsius: 19,
        humidityPercent: 55,
        condition: WeatherCondition.clear,
        description: 'clear sky',
        precipitationProbability: 0,
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(weather);
    registerFallbackValue(forecast);
  });

  setUp(() {
    weatherRepository = _MockWeatherRepository();
    locationService = _MockLocationService();
    geocoding = _MockGeocodingRepository();
    when(
      () => locationService.getCurrentLocation(),
    ).thenAnswer((_) async => const Right(device));
    when(
      () => geocoding.reverseGeocode(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(detected));
  });

  Widget buildSubject() {
    final favorites = _MockFavoritesRepository();
    when(
      () => favorites.getFavorites(),
    ).thenAnswer((_) async => const Right([]));
    final cache = _MockCacheRepository();
    when(
      () => cache.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => cache.getForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(null));

    when(
      () => cache.saveCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        weather: any(named: 'weather'),
        fetchedAt: any(named: 'fetchedAt'),
        cityName: any(named: 'cityName'),
        country: any(named: 'country'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => cache.saveForecast(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        forecast: any(named: 'forecast'),
        fetchedAt: any(named: 'fetchedAt'),
        cityName: any(named: 'cityName'),
        country: any(named: 'country'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    return ProviderScope(
      overrides: [
        ...locationTestOverrides(),
        weatherRepositoryProvider.overrideWithValue(weatherRepository),
        locationServiceProvider.overrideWithValue(locationService),
        geocodingRepositoryProvider.overrideWithValue(geocoding),
        favoritesRepositoryProvider.overrideWithValue(favorites),
        weatherCacheRepositoryProvider.overrideWithValue(cache),
        connectivityServiceProvider.overrideWithValue(_OnlineConnectivity()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  testWidgets(
    'fresh launch: GPS -> reverse geocode -> search bar -> weather + forecast, '
    'each for the same device coordinates and requested once',
    (tester) async {
      when(
        () => weatherRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(weather));
      when(
        () => weatherRepository.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(forecast));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      verify(() => locationService.getCurrentLocation()).called(1);
      verify(
        () => geocoding.reverseGeocode(
          latitude: device.latitude,
          longitude: device.longitude,
        ),
      ).called(1);
      verify(
        () => weatherRepository.getCurrentWeather(
          latitude: device.latitude,
          longitude: device.longitude,
        ),
      ).called(1);
      verify(
        () => weatherRepository.getForecast(
          latitude: device.latitude,
          longitude: device.longitude,
        ),
      ).called(1);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Sydney');
      expect(find.text('Sunny Spells'), findsOneWidget);
    },
  );

  testWidgets(
    'fresh launch with a rejected API key: location is still detected, the '
    'invalid-key error is shown (not a location error) and nothing is faked',
    (tester) async {
      const unauthorized = RemoteDataFailure(
        AppStrings.invalidApiKey,
        statusCode: 401,
      );
      when(
        () => weatherRepository.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(unauthorized));
      when(
        () => weatherRepository.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(unauthorized));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      verify(() => locationService.getCurrentLocation()).called(1);
      verify(
        () => weatherRepository.getCurrentWeather(
          latitude: device.latitude,
          longitude: device.longitude,
        ),
      ).called(1);
      expect(find.text(AppStrings.invalidApiKey), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.location_off_outlined), findsNothing);
      expect(find.text('Sunny Spells'), findsNothing);
      // The search bar stays usable, with the detected city in it.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Sydney',
      );
    },
  );
}
