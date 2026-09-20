import 'package:hive_flutter/hive_flutter.dart';

/// Names and lifecycle of every Hive box the app persists data in, kept in
/// one place so production startup ([openAll]) and tests' global setup
/// agree on exactly what needs to be open.
///
/// Every box stores plain `Map<String, dynamic>` values — no generated
/// [TypeAdapter]s — so entries are simple to inspect, migrate, and test.
class HiveBoxes {
  const HiveBoxes._();

  static const favorites = 'favorites';
  static const currentWeatherCache = 'current_weather_cache';
  static const forecastCache = 'forecast_cache';
  static const settings = 'settings';

  static const _all = [favorites, currentWeatherCache, forecastCache, settings];

  /// Every box name, for code that must treat all boxes uniformly (e.g. the
  /// encryption migration in `SecureHiveInitializer`).
  static List<String> get names => _all;

  /// Opens every box the app needs. Safe to call once at startup — Hive
  /// itself (`Hive.init`/`Hive.initFlutter`) must already have run.
  ///
  /// Opened untyped (`Box<dynamic>`) rather than e.g. `Box<Map>` — Hive
  /// requires every subsequent `Hive.box(name)` lookup to request the
  /// exact same type parameter the box was opened with, and callers here
  /// (DI providers, tests) all fetch boxes untyped.
  static Future<void> openAll() async {
    for (final name in _all) {
      await Hive.openBox<dynamic>(name);
    }
  }

  /// Empties every box without closing them. Used by tests to isolate
  /// each test from data left behind by a previous one.
  static Future<void> clearAll() async {
    for (final name in _all) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).clear();
      }
    }
  }
}
