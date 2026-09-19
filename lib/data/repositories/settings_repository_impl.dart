import 'package:dartz/dartz.dart';

import '../../core/error/cache_failures.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/temperature_unit.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

/// Reads/writes [AppSettings] through a [SettingsLocalDataSource] — Hive
/// in production — translating storage errors into [Failure]s and an
/// unrecognized or missing stored value into [AppSettings.defaults]'
/// corresponding field, so a corrupt or pre-upgrade value never crashes
/// the app.
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      return Right(
        AppSettings(
          temperatureUnit: _parseTemperatureUnit(
            _localDataSource.getTemperatureUnit(),
          ),
          themeMode: _parseThemeMode(_localDataSource.getThemeMode()),
          offlineDataEnabled:
              _localDataSource.getOfflineDataEnabled() ??
              AppSettings.defaults.offlineDataEnabled,
        ),
      );
    } catch (error) {
      return Left(CacheFailure('Failed to read settings: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveTemperatureUnit(
    TemperatureUnit value,
  ) async {
    try {
      await _localDataSource.setTemperatureUnit(value.name);
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('Failed to save temperature unit: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveThemeMode(AppThemeMode value) async {
    try {
      await _localDataSource.setThemeMode(value.name);
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('Failed to save theme mode: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveOfflineDataEnabled(bool value) async {
    try {
      await _localDataSource.setOfflineDataEnabled(value);
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('Failed to save offline data setting: $error'));
    }
  }

  TemperatureUnit _parseTemperatureUnit(String? raw) {
    return TemperatureUnit.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => AppSettings.defaults.temperatureUnit,
    );
  }

  AppThemeMode _parseThemeMode(String? raw) {
    return AppThemeMode.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => AppSettings.defaults.themeMode,
    );
  }
}
