import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/error/cache_failures.dart';
import 'package:weather_now_flutter/data/datasources/settings_local_data_source.dart';
import 'package:weather_now_flutter/data/repositories/settings_repository_impl.dart';
import 'package:weather_now_flutter/domain/entities/app_settings.dart';
import 'package:weather_now_flutter/domain/entities/app_theme_mode.dart';
import 'package:weather_now_flutter/domain/entities/temperature_unit.dart';

/// An in-memory stand-in for [SettingsLocalDataSource] — keeps
/// [SettingsRepositoryImpl]'s tests fast and independent of Hive, which
/// [HiveSettingsDataSource] (tested separately) is responsible for.
class FakeSettingsLocalDataSource implements SettingsLocalDataSource {
  String? temperatureUnit;
  String? themeMode;
  bool? offlineDataEnabled;

  /// When set, every method throws this instead of touching the fields
  /// above — simulates a local-storage failure.
  Object? failWith;

  @override
  String? getTemperatureUnit() {
    if (failWith != null) throw failWith!;
    return temperatureUnit;
  }

  @override
  Future<void> setTemperatureUnit(String value) async {
    if (failWith != null) throw failWith!;
    temperatureUnit = value;
  }

  @override
  String? getThemeMode() {
    if (failWith != null) throw failWith!;
    return themeMode;
  }

  @override
  Future<void> setThemeMode(String value) async {
    if (failWith != null) throw failWith!;
    themeMode = value;
  }

  @override
  bool? getOfflineDataEnabled() {
    if (failWith != null) throw failWith!;
    return offlineDataEnabled;
  }

  @override
  Future<void> setOfflineDataEnabled(bool value) async {
    if (failWith != null) throw failWith!;
    offlineDataEnabled = value;
  }
}

void main() {
  late FakeSettingsLocalDataSource dataSource;
  late SettingsRepositoryImpl repository;

  setUp(() {
    dataSource = FakeSettingsLocalDataSource();
    repository = SettingsRepositoryImpl(localDataSource: dataSource);
  });

  test(
    'getSettings returns the defaults when nothing has been saved',
    () async {
      final result = await repository.getSettings();

      result.fold(
        (_) => fail('expected Right'),
        (settings) => expect(settings, AppSettings.defaults),
      );
    },
  );

  test('getSettings falls back to the default unit for an unrecognized '
      'stored value', () async {
    dataSource.temperatureUnit = 'kelvin';

    final result = await repository.getSettings();

    result.fold(
      (_) => fail('expected Right'),
      (settings) => expect(
        settings.temperatureUnit,
        AppSettings.defaults.temperatureUnit,
      ),
    );
  });

  test(
    'saveTemperatureUnit persists the unit, then getSettings reflects it',
    () async {
      await repository.saveTemperatureUnit(TemperatureUnit.fahrenheit);

      final result = await repository.getSettings();

      result.fold(
        (_) => fail('expected Right'),
        (settings) =>
            expect(settings.temperatureUnit, TemperatureUnit.fahrenheit),
      );
    },
  );

  test(
    'saveThemeMode persists the mode, then getSettings reflects it',
    () async {
      await repository.saveThemeMode(AppThemeMode.dark);

      final result = await repository.getSettings();

      result.fold(
        (_) => fail('expected Right'),
        (settings) => expect(settings.themeMode, AppThemeMode.dark),
      );
    },
  );

  test(
    'saveOfflineDataEnabled persists the flag, then getSettings reflects it',
    () async {
      await repository.saveOfflineDataEnabled(false);

      final result = await repository.getSettings();

      result.fold(
        (_) => fail('expected Right'),
        (settings) => expect(settings.offlineDataEnabled, isFalse),
      );
    },
  );

  test(
    'getSettings returns a CacheFailure when the data source throws',
    () async {
      dataSource.failWith = Exception('disk error');

      final result = await repository.getSettings();

      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('expected Left'),
      );
    },
  );

  test(
    'saveTemperatureUnit returns a CacheFailure when the data source throws',
    () async {
      dataSource.failWith = Exception('disk full');

      final result = await repository.saveTemperatureUnit(
        TemperatureUnit.celsius,
      );

      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('expected Left'),
      );
    },
  );
}
