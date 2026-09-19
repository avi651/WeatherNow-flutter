import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/cache_failures.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/app_settings.dart';
import 'package:weather_now_flutter/domain/entities/app_theme_mode.dart';
import 'package:weather_now_flutter/domain/entities/temperature_unit.dart';
import 'package:weather_now_flutter/domain/repositories/settings_repository.dart';
import 'package:weather_now_flutter/presentation/providers/offline_data_enabled_provider.dart';
import 'package:weather_now_flutter/presentation/providers/settings_provider.dart';
import 'package:weather_now_flutter/presentation/providers/temperature_unit_provider.dart';
import 'package:weather_now_flutter/presentation/providers/theme_mode_provider.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(TemperatureUnit.celsius);
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    when(
      () => mockRepository.saveTemperatureUnit(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => mockRepository.saveThemeMode(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => mockRepository.saveOfflineDataEnabled(any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('loads the saved settings on first read', () async {
    const saved = AppSettings(
      temperatureUnit: TemperatureUnit.fahrenheit,
      themeMode: AppThemeMode.dark,
      offlineDataEnabled: false,
    );
    when(
      () => mockRepository.getSettings(),
    ).thenAnswer((_) async => const Right(saved));

    final container = buildContainer();

    expect(await container.read(settingsProvider.future), saved);
  });

  test('falls back to defaults when loading fails, rather than surfacing '
      'an error', () async {
    when(
      () => mockRepository.getSettings(),
    ).thenAnswer((_) async => const Left(CacheFailure('disk error')));

    final container = buildContainer();

    expect(await container.read(settingsProvider.future), AppSettings.defaults);
    expect(container.read(settingsProvider).hasError, isFalse);
  });

  test(
    'setTemperatureUnit updates state optimistically and persists it',
    () async {
      when(
        () => mockRepository.getSettings(),
      ).thenAnswer((_) async => const Right(AppSettings.defaults));

      final container = buildContainer();
      await container.read(settingsProvider.future);

      await container
          .read(settingsProvider.notifier)
          .setTemperatureUnit(TemperatureUnit.fahrenheit);

      expect(
        container.read(settingsProvider).value!.temperatureUnit,
        TemperatureUnit.fahrenheit,
      );
      verify(
        () => mockRepository.saveTemperatureUnit(TemperatureUnit.fahrenheit),
      ).called(1);
    },
  );

  test('setTemperatureUnit rolls back when persisting fails', () async {
    when(
      () => mockRepository.getSettings(),
    ).thenAnswer((_) async => const Right(AppSettings.defaults));
    when(
      () => mockRepository.saveTemperatureUnit(TemperatureUnit.fahrenheit),
    ).thenAnswer((_) async => const Left(CacheFailure('disk full')));

    final container = buildContainer();
    await container.read(settingsProvider.future);

    await container
        .read(settingsProvider.notifier)
        .setTemperatureUnit(TemperatureUnit.fahrenheit);

    expect(
      container.read(settingsProvider).value!.temperatureUnit,
      AppSettings.defaults.temperatureUnit,
    );
  });

  test('setThemeMode updates state and persists it', () async {
    when(
      () => mockRepository.getSettings(),
    ).thenAnswer((_) async => const Right(AppSettings.defaults));

    final container = buildContainer();
    await container.read(settingsProvider.future);

    await container
        .read(settingsProvider.notifier)
        .setThemeMode(AppThemeMode.dark);

    expect(
      container.read(settingsProvider).value!.themeMode,
      AppThemeMode.dark,
    );
    verify(() => mockRepository.saveThemeMode(AppThemeMode.dark)).called(1);
  });

  test('setOfflineDataEnabled updates state and persists it', () async {
    when(
      () => mockRepository.getSettings(),
    ).thenAnswer((_) async => const Right(AppSettings.defaults));

    final container = buildContainer();
    await container.read(settingsProvider.future);

    await container
        .read(settingsProvider.notifier)
        .setOfflineDataEnabled(false);

    expect(container.read(settingsProvider).value!.offlineDataEnabled, isFalse);
    verify(() => mockRepository.saveOfflineDataEnabled(false)).called(1);
  });

  test('temperatureUnitProvider mirrors the loaded setting', () async {
    const saved = AppSettings(
      temperatureUnit: TemperatureUnit.fahrenheit,
      themeMode: AppThemeMode.system,
      offlineDataEnabled: true,
    );
    when(
      () => mockRepository.getSettings(),
    ).thenAnswer((_) async => const Right(saved));

    final container = buildContainer();
    await container.read(settingsProvider.future);

    expect(container.read(temperatureUnitProvider), TemperatureUnit.fahrenheit);
  });

  test('offlineDataEnabledProvider mirrors the loaded setting', () async {
    const saved = AppSettings(
      temperatureUnit: TemperatureUnit.celsius,
      themeMode: AppThemeMode.system,
      offlineDataEnabled: false,
    );
    when(
      () => mockRepository.getSettings(),
    ).thenAnswer((_) async => const Right(saved));

    final container = buildContainer();
    await container.read(settingsProvider.future);

    expect(container.read(offlineDataEnabledProvider), isFalse);
  });

  test(
    'themeModeProvider maps each AppThemeMode onto Flutter\'s ThemeMode',
    () async {
      for (final entry in {
        AppThemeMode.system: ThemeMode.system,
        AppThemeMode.light: ThemeMode.light,
        AppThemeMode.dark: ThemeMode.dark,
      }.entries) {
        when(() => mockRepository.getSettings()).thenAnswer(
          (_) async =>
              Right(AppSettings.defaults.copyWith(themeMode: entry.key)),
        );

        final container = buildContainer();
        await container.read(settingsProvider.future);

        expect(container.read(themeModeProvider), entry.value);
      }
    },
  );
}
