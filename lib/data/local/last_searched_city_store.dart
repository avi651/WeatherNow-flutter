import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/city_suggestion.dart';
import '../models/city_suggestion_model.dart';

/// Remembers the last city the user picked so the next launch can show its
/// weather without asking the device for a location.
///
/// Lives in the settings box under its own key. Reads are synchronous
/// (Hive boxes are in memory once open) and never throw: a missing or
/// corrupt entry simply means "no last city".
class LastSearchedCityStore {
  const LastSearchedCityStore({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;

  static const _key = 'lastSearchedCity';

  CitySuggestion? read() {
    try {
      final raw = _box.get(_key);
      if (raw is! Map) return null;
      return CitySuggestionModel.fromJson(
        Map<String, dynamic>.from(raw),
      ).toEntity();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(CitySuggestion city) async {
    try {
      await _box.put(_key, CitySuggestionModel.fromEntity(city).toJson());
    } catch (_) {
      // Losing the "last city" convenience must never break selection.
    }
  }

  /// Forgets the saved city, so the next launch falls back to the device's
  /// location (see `SelectedCityNotifier.useDeviceLocation`).
  Future<void> clear() async {
    try {
      await _box.delete(_key);
    } catch (_) {
      // Same as [write]: a failed housekeeping write must not break the UI.
    }
  }
}
