import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/app_settings.dart';
import 'package:weather_now_flutter/domain/entities/app_theme_mode.dart';
import 'package:weather_now_flutter/domain/entities/cached_current_weather.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/temperature_unit.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/domain/repositories/settings_repository.dart';
import 'package:weather_now_flutter/domain/repositories/weather_cache_repository.dart';
import 'package:weather_now_flutter/presentation/providers/favorite_cached_weather_provider.dart';
import 'package:weather_now_flutter/presentation/providers/settings_provider.dart';

class _MockCacheRepository extends Mock implements WeatherCacheRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  const city = CitySuggestion(
    name: 'Pune',
    country: 'IN',
    latitude: 18.52,
    longitude: 73.85,
  );
  final cached = CachedCurrentWeather(
    weather: CurrentWeather(
      temperatureCelsius: 30,
      feelsLikeCelsius: 31,
      humidityPercent: 50,
      pressureHpa: 1010,
      windSpeedMetersPerSecond: 2,
      condition: WeatherCondition.clear,
      description: 'clear sky',
      observedAt: DateTime.utc(2026, 9, 16),
    ),
    fetchedAt: DateTime.utc(2026, 9, 17),
  );

  late _MockCacheRepository cache;
  late _MockSettingsRepository settings;

  ProviderContainer build(bool enabled) {
    when(() => settings.getSettings()).thenAnswer(
      (_) async => Right(
        AppSettings(
          temperatureUnit: TemperatureUnit.celsius,
          themeMode: AppThemeMode.system,
          offlineDataEnabled: enabled,
        ),
      ),
    );
    when(
      () => settings.saveOfflineDataEnabled(any()),
    ).thenAnswer((_) async => const Right(unit));
    final container = ProviderContainer(
      overrides: [
        weatherCacheRepositoryProvider.overrideWithValue(cache),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    cache = _MockCacheRepository();
    settings = _MockSettingsRepository();
    when(
      () => cache.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => Right(cached));
  });

  test('reads the cache when Offline Data is on', () async {
    final container = build(true);
    await container.read(settingsProvider.future);

    expect(
      await container.read(favoriteCachedWeatherProvider(city).future),
      cached,
    );
  });

  test('never touches the cache when Offline Data is off', () async {
    final container = build(false);
    await container.read(settingsProvider.future);

    expect(
      await container.read(favoriteCachedWeatherProvider(city).future),
      isNull,
    );
    verifyNever(
      () => cache.getCurrentWeather(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    );
  });

  test('toggling the setting applies to tiles immediately', () async {
    final container = build(true);
    await container.read(settingsProvider.future);
    container.listen(favoriteCachedWeatherProvider(city), (_, _) {});
    expect(
      await container.read(favoriteCachedWeatherProvider(city).future),
      cached,
    );

    await container
        .read(settingsProvider.notifier)
        .setOfflineDataEnabled(false);

    expect(
      await container.read(favoriteCachedWeatherProvider(city).future),
      isNull,
    );
  });
}
