import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/temperature_unit.dart';

/// The user's app-wide preferences — temperature unit, theme, and whether
/// offline data is enabled —
/// loaded once from `SettingsRepository` and kept in sync as each is
/// changed from the Settings screen.
///
/// Unlike [FavoritesNotifier] (which surfaces a load failure as
/// `AsyncError` so the Favorites screen can show a retry view), a
/// settings load failure here falls back to [AppSettings.defaults]
/// instead: there's no meaningful "failed to load settings" screen to
/// show — the Settings screen should just present working, editable
/// controls with sensible defaults rather than block on a retry.
///
/// Each setter updates optimistically — mirroring [FavoritesNotifier] —
/// so the UI reflects a change immediately, rolling it back if persisting
/// it fails.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final getSettings = ref.watch(getSettingsProvider);
    final result = await getSettings();

    return result.fold(
      (failure) => AppSettings.defaults,
      (settings) => settings,
    );
  }

  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    final previous = state.value ?? AppSettings.defaults;
    state = AsyncData(previous.copyWith(temperatureUnit: unit));

    final saveTemperatureUnit = ref.read(saveTemperatureUnitProvider);
    final result = await saveTemperatureUnit(unit);
    result.fold((failure) => state = AsyncData(previous), (_) {});
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final previous = state.value ?? AppSettings.defaults;
    state = AsyncData(previous.copyWith(themeMode: mode));

    final saveThemeMode = ref.read(saveThemeModeProvider);
    final result = await saveThemeMode(mode);
    result.fold((failure) => state = AsyncData(previous), (_) {});
  }

  Future<void> setOfflineDataEnabled(bool enabled) async {
    final previous = state.value ?? AppSettings.defaults;
    state = AsyncData(previous.copyWith(offlineDataEnabled: enabled));

    final saveOfflineDataEnabled = ref.read(saveOfflineDataEnabledProvider);
    final result = await saveOfflineDataEnabled(enabled);
    result.fold((failure) => state = AsyncData(previous), (_) {});
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
