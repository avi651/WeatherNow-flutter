import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import 'settings_provider.dart';

/// Whether the user has allowed the app to store and fall back to cached
/// weather data for offline access — a convenience derived from
/// [settingsProvider], read by `HomeWeatherNotifier`/`HomeForecastNotifier`
/// (whether a fetch may cache its result or a failure may fall back to
/// cache) and `FavoritesSyncNotifier` (whether a sync may write to cache
/// at all).
final offlineDataEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).value?.offlineDataEnabled ??
      AppSettings.defaults.offlineDataEnabled;
});
