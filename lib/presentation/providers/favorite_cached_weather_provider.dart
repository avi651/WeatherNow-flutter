import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/cached_current_weather.dart';
import '../../domain/entities/city_suggestion.dart';
import 'offline_data_enabled_provider.dart';

/// The last cached current weather for [city], or `null` if nothing has
/// been cached for it yet (or Offline Data is off) — used by the favorites screen to show each
/// favorite's last-known weather without fetching it live.
final favoriteCachedWeatherProvider =
    FutureProvider.family<CachedCurrentWeather?, CitySuggestion>((ref, city) async {
  // Offline Data off means no Hive reads either; watching it also makes
  // the tiles update the moment the setting is toggled.
  if (!ref.watch(offlineDataEnabledProvider)) return null;

  final repository = ref.watch(weatherCacheRepositoryProvider);
  final result = await repository.getCurrentWeather(
    latitude: city.latitude,
    longitude: city.longitude,
  );

  return result.fold((failure) => null, (cached) => cached);
});
