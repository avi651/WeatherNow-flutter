import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

/// Rebuild-count regression guard, added after a DevTools-style rebuild
/// review found the search field is already isolated from the weather
/// content; this keeps it that way.
class _MockWeatherRepository extends Mock implements WeatherRepository {}

class _MockLocationService extends Mock implements LocationService {}

class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

class _MockWeatherCacheRepository extends Mock
    implements WeatherCacheRepository {}

class _FakeConnectivity implements ConnectivityService {
  final c = StreamController<bool>.broadcast();
  @override
  Future<bool> checkOnline() async => true;
  @override
  Stream<bool> get onlineChanges => c.stream;
}

void main() {
  testWidgets(
    'typing in the search field does not rebuild the weather content',
    (tester) async {
      final w = _MockWeatherRepository(),
          l = _MockLocationService(),
          g = _MockGeocodingRepository(),
          f = _MockFavoritesRepository(),
          c = _MockWeatherCacheRepository();
      final fc = _FakeConnectivity();
      const city = CitySuggestion(
        name: 'Bengaluru',
        state: 'K',
        country: 'IN',
        latitude: 12.9,
        longitude: 77.5,
      );
      final weather = CurrentWeather(
        temperatureCelsius: 27.6,
        feelsLikeCelsius: 31,
        humidityPercent: 68,
        pressureHpa: 1013,
        windSpeedMetersPerSecond: 3.4,
        condition: WeatherCondition.clouds,
        description: 'Partly Cloudy',
        observedAt: DateTime.utc(2026, 9, 16),
      );
      final forecast = Forecast(
        entries: [
          for (var i = 0; i < 40; i++)
            ForecastEntry(
              forecastFor: DateTime.utc(
                2026,
                9,
                16,
              ).add(Duration(hours: 3 * i)),
              temperatureCelsius: 20.0 + i % 7,
              feelsLikeCelsius: 21,
              humidityPercent: 60,
              condition: WeatherCondition.clear,
              description: 'clear',
              precipitationProbability: 0.1,
            ),
        ],
      );
      when(() => l.getCurrentLocation()).thenAnswer(
        (_) async =>
            const Right(DeviceLocation(latitude: 12.9, longitude: 77.5)),
      );
      when(
        () => g.reverseGeocode(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Right(city));
      when(
        () => g.searchCities(query: any(named: 'query')),
      ).thenAnswer((_) async => const Right([city]));
      when(() => f.getFavorites()).thenAnswer((_) async => const Right([]));
      when(
        () => c.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => c.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => c.saveCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          weather: weather,
          fetchedAt: any(named: 'fetchedAt'),
          cityName: any(named: 'cityName'),
          country: any(named: 'country'),
        ),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => c.saveForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          forecast: forecast,
          fetchedAt: any(named: 'fetchedAt'),
          cityName: any(named: 'cityName'),
          country: any(named: 'country'),
        ),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => w.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(weather));
      when(
        () => w.getForecast(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => Right(forecast));

      final container = ProviderContainer(
        overrides: [
          ...locationTestOverrides(),
          weatherRepositoryProvider.overrideWithValue(w),
          locationServiceProvider.overrideWithValue(l),
          geocodingRepositoryProvider.overrideWithValue(g),
          favoritesRepositoryProvider.overrideWithValue(f),
          weatherCacheRepositoryProvider.overrideWithValue(c),
          connectivityServiceProvider.overrideWithValue(fc),
        ],
      );
      addTearDown(container.dispose);

      final counts = <String, int>{};
      debugOnRebuildDirtyWidget = (e, builtOnce) {
        final n = e.widget.runtimeType.toString();
        counts[n] = (counts[n] ?? 0) + 1;
      };
      addTearDown(() => debugOnRebuildDirtyWidget = null);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      counts.clear();

      await tester.enterText(find.byType(TextField), 'lond');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'londo');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'london');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(counts['HomeScreen'], isNull);
      expect(counts['CurrentWeatherHeroCard'], isNull);
      expect(counts['DailyForecastStrip'], isNull);
      expect(counts['WeatherStatsRow'], isNull);
      expect(counts['WeatherSearchBar'], isNotNull);
      counts.clear();
    },
  );
}
