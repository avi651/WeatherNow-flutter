import 'package:hive_flutter/hive_flutter.dart';

import 'settings_local_data_source.dart';

/// Stores each setting under its own key in a single Hive [Box], as plain
/// primitives (`String`/`bool`) rather than a `Map` — unlike the app's
/// other boxes, there's no per-location or per-city keying here, just one
/// small, fixed set of scalar preferences.
class HiveSettingsDataSource implements SettingsLocalDataSource {
  const HiveSettingsDataSource({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;

  static const _temperatureUnitKey = 'temperatureUnit';
  static const _themeModeKey = 'themeMode';
  static const _offlineDataEnabledKey = 'offlineDataEnabled';

  @override
  String? getTemperatureUnit() => _box.get(_temperatureUnitKey) as String?;

  @override
  Future<void> setTemperatureUnit(String value) {
    return _box.put(_temperatureUnitKey, value);
  }

  @override
  String? getThemeMode() => _box.get(_themeModeKey) as String?;

  @override
  Future<void> setThemeMode(String value) {
    return _box.put(_themeModeKey, value);
  }

  @override
  bool? getOfflineDataEnabled() => _box.get(_offlineDataEnabledKey) as bool?;

  @override
  Future<void> setOfflineDataEnabled(bool value) {
    return _box.put(_offlineDataEnabledKey, value);
  }
}
