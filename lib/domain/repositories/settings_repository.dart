import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/app_settings.dart';
import '../entities/app_theme_mode.dart';
import '../entities/temperature_unit.dart';

/// Persists the user's app-wide preferences — Hive in production — so
/// they survive a restart. Each setting is saved through its own method
/// (rather than one `save(AppSettings)`) so a single toggle is a single,
/// independent write, matching how the Settings screen changes them one
/// at a time.
abstract class SettingsRepository {
  /// The current settings, or [AppSettings.defaults] for anything never
  /// saved before (a fresh install, or a value some future version adds).
  Future<Either<Failure, AppSettings>> getSettings();

  Future<Either<Failure, Unit>> saveTemperatureUnit(TemperatureUnit unit);

  Future<Either<Failure, Unit>> saveThemeMode(AppThemeMode mode);

  Future<Either<Failure, Unit>> saveOfflineDataEnabled(bool enabled);
}
