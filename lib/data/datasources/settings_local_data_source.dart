/// Raw local storage for the user's app-wide preferences — implemented by
/// [HiveSettingsDataSource]. Kept as its own interface, storing plain
/// primitives rather than [AppSettings] itself, so [SettingsRepositoryImpl]
/// owns the only place that knows how a domain enum maps to what's
/// actually persisted.
abstract class SettingsLocalDataSource {
  /// The stored [TemperatureUnit.name], or `null` if never saved.
  String? getTemperatureUnit();

  Future<void> setTemperatureUnit(String value);

  /// The stored [AppThemeMode.name], or `null` if never saved.
  String? getThemeMode();

  Future<void> setThemeMode(String value);

  bool? getOfflineDataEnabled();

  Future<void> setOfflineDataEnabled(bool value);
}
