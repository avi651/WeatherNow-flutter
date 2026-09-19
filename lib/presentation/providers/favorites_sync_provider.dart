import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import 'favorite_cached_weather_provider.dart';
import 'favorite_provider.dart';
import 'settings_provider.dart';

/// Re-fetches live weather for every saved favorite and re-caches it, for
/// the Favorites screen's "Sync Now" button — reusing the same
/// `GetCurrentWeather` use case and `WeatherCacheRepository` the Home
/// screen already fetches/caches through, so this adds no new data-layer
/// code, just an explicit "do it for every favorite" pass.
///
/// A city whose fetch fails is skipped rather than aborting the whole
/// sync, so one bad city (or a fetch failing partway through) doesn't
/// prevent the others from updating. The sync as a whole only reports
/// failure — surfaced as [AsyncError] — when *every* favorite failed
/// (e.g. the device is offline), since that's the case the UI actually
/// needs to tell the user about.
class FavoritesSyncNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sync() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_syncAll);
  }

  Future<void> _syncAll() async {
    final settings = await ref.read(settingsProvider.future);
    if (!settings.offlineDataEnabled) {
      throw StateError('Offline data is turned off in Settings.');
    }

    final favorites = ref.read(favoritesProvider).value ?? const [];
    if (favorites.isEmpty) return;

    final getCurrentWeather = ref.read(getCurrentWeatherProvider);
    final cacheRepository = ref.read(weatherCacheRepositoryProvider);
    var failureCount = 0;

    for (final city in favorites) {
      final result = await getCurrentWeather(
        latitude: city.latitude,
        longitude: city.longitude,
      );
      await result.fold(
        (failure) async => failureCount++,
        (weather) => cacheRepository.saveCurrentWeather(
          latitude: city.latitude,
          longitude: city.longitude,
          weather: weather,
          fetchedAt: DateTime.now(),
          cityName: city.name,
          country: city.country,
        ),
      );
    }

    // Tiles read cached weather through `favoriteCachedWeatherProvider`,
    // which has no way to know a fresh write just happened for its city —
    // invalidate the whole family so every tile re-reads its (possibly
    // just-updated) cache.
    ref.invalidate(favoriteCachedWeatherProvider);

    if (failureCount == favorites.length) {
      throw StateError('Could not sync favorites — check your connection.');
    }
  }
}

final favoritesSyncProvider = AsyncNotifierProvider<FavoritesSyncNotifier, void>(
  FavoritesSyncNotifier.new,
);
