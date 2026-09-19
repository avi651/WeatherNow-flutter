import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/temperature_unit.dart';
import 'settings_provider.dart';

/// The user's chosen temperature display unit — a convenience derived
/// from [settingsProvider] for widgets that only care about this one
/// field, without needing to unwrap the full `AsyncValue`.
///
/// Falls back to [AppSettings.defaults]' unit while settings are still
/// loading, so temperature displays never block on this or need a
/// loading state of their own.
final temperatureUnitProvider = Provider<TemperatureUnit>((ref) {
  return ref.watch(settingsProvider).value?.temperatureUnit ??
      AppSettings.defaults.temperatureUnit;
});
