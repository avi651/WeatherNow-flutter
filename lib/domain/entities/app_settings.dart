import 'app_theme_mode.dart';
import 'temperature_unit.dart';

/// The user's persisted app-wide preferences, set from the Settings
/// screen and read anywhere in the app that needs to respect them (e.g.
/// temperature displays, the app's `ThemeMode`, whether a failed live
/// weather fetch may fall back to cache).
class AppSettings {
  const AppSettings({
    required this.temperatureUnit,
    required this.themeMode,
    required this.offlineDataEnabled,
  });

  /// What a fresh install starts with, and what's used if a stored value
  /// is ever missing or unreadable.
  static const defaults = AppSettings(
    temperatureUnit: TemperatureUnit.celsius,
    themeMode: AppThemeMode.system,
    offlineDataEnabled: true,
  );

  final TemperatureUnit temperatureUnit;
  final AppThemeMode themeMode;

  /// Whether a live weather fetch may cache its result, and whether a
  /// failed fetch may fall back to a previous cache — off means the app
  /// never stores or reuses weather data for offline access.
  final bool offlineDataEnabled;

  AppSettings copyWith({
    TemperatureUnit? temperatureUnit,
    AppThemeMode? themeMode,
    bool? offlineDataEnabled,
  }) {
    return AppSettings(
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      themeMode: themeMode ?? this.themeMode,
      offlineDataEnabled: offlineDataEnabled ?? this.offlineDataEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.temperatureUnit == temperatureUnit &&
        other.themeMode == themeMode &&
        other.offlineDataEnabled == offlineDataEnabled;
  }

  @override
  int get hashCode => Object.hash(
        temperatureUnit,
        themeMode,
        offlineDataEnabled,
      );

  @override
  String toString() => 'AppSettings('
      'temperatureUnit: $temperatureUnit, '
      'themeMode: $themeMode, '
      'offlineDataEnabled: $offlineDataEnabled)';
}
