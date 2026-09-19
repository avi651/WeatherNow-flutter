import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:weather_now_flutter/core/config/app_environment.dart';
import 'package:weather_now_flutter/core/location/geolocator_location_service.dart';
import '../core/location/location_service.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/network/dio_client_config.dart';
import '../core/network/dio_exception_mapper.dart';
import '../data/datasources/favorites_hive_data_source.dart';
import '../data/datasources/favorites_local_data_source.dart';
import '../data/datasources/geocoding_api_service.dart';
import '../data/datasources/geocoding_data_source.dart';
import '../data/datasources/geocoding_mock_data_source.dart';
import '../data/datasources/settings_hive_data_source.dart';
import '../data/datasources/settings_local_data_source.dart';
import '../data/datasources/weather_api_service.dart';
import '../data/datasources/weather_cache_hive_data_source.dart';
import '../data/datasources/weather_cache_local_data_source.dart';
import '../data/datasources/weather_data_source.dart';
import '../data/datasources/weather_mock_data_source.dart';
import '../data/local/hive_boxes.dart';
import '../data/local/last_searched_city_store.dart';
import '../data/repositories/favorites_repository_impl.dart';
import '../data/repositories/geocoding_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/weather_cache_repository_impl.dart';
import '../data/repositories/weather_repository_impl.dart';
import '../domain/repositories/favorites_repository.dart';
import '../domain/repositories/geocoding_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/weather_cache_repository.dart';
import '../domain/repositories/weather_repository.dart';
import '../domain/usecases/add_favorite.dart';
import '../domain/usecases/get_current_weather.dart';
import '../domain/usecases/get_favorites.dart';
import '../domain/usecases/get_forecast.dart';
import '../domain/usecases/get_settings.dart';
import '../domain/usecases/remove_favorite.dart';
import '../domain/usecases/reverse_geocode.dart';
import '../domain/usecases/save_offline_data_enabled.dart';
import '../domain/usecases/save_temperature_unit.dart';
import '../domain/usecases/save_theme_mode.dart';
import '../domain/usecases/search_cities.dart';

final dioProvider = Provider<Dio>((ref) {
  return DioClientConfig(baseUrl: AppEnvironment.baseUrl).createDio();
});

final dioExceptionMapperProvider = Provider<DioExceptionMapper>((ref) {
  return const DioExceptionMapper();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    dio: ref.watch(dioProvider),
    exceptionMapper: ref.watch(dioExceptionMapperProvider),
  );
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return const ConnectivityPlusService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return const GeolocatorLocationService();
});

final weatherApiServiceProvider = Provider<WeatherApiService>((ref) {
  return WeatherApiService(
    apiClient: ref.watch(apiClientProvider),
    apiKey: AppEnvironment.apiKey,
  );
});

/// Exposed as its own overridable provider — rather than reading
/// [AppEnvironment.isMock] directly inside [weatherDataSourceProvider] — so
/// tests can force either branch without needing a matching compile-time
/// `--dart-define=ENV=...` for the test process itself.
final isMockEnvironmentProvider = Provider<bool>(
  (ref) => AppEnvironment.isMock,
);

/// The actual mock/real switch: reads bundled mock JSON when
/// [isMockEnvironmentProvider] is true, otherwise talks to the real API
/// through [weatherApiServiceProvider].
final weatherDataSourceProvider = Provider<WeatherDataSource>((ref) {
  if (ref.watch(isMockEnvironmentProvider)) {
    return const WeatherMockDataSource();
  }

  return ref.watch(weatherApiServiceProvider);
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepositoryImpl(
    dataSource: ref.watch(weatherDataSourceProvider),
  );
});

final getCurrentWeatherProvider = Provider<GetCurrentWeather>((ref) {
  return GetCurrentWeather(ref.watch(weatherRepositoryProvider));
});

final getForecastProvider = Provider<GetForecast>((ref) {
  return GetForecast(ref.watch(weatherRepositoryProvider));
});

final geocodingApiServiceProvider = Provider<GeocodingApiService>((ref) {
  return GeocodingApiService(
    apiClient: ref.watch(apiClientProvider),
    apiKey: AppEnvironment.apiKey,
  );
});

/// Reads bundled sample cities in mock mode, otherwise talks to the real
/// geocoding API — mirrors [weatherDataSourceProvider]'s mock/real switch.
final geocodingDataSourceProvider = Provider<GeocodingDataSource>((ref) {
  if (ref.watch(isMockEnvironmentProvider)) {
    return const GeocodingMockDataSource();
  }

  return ref.watch(geocodingApiServiceProvider);
});

final geocodingRepositoryProvider = Provider<GeocodingRepository>((ref) {
  return GeocodingRepositoryImpl(
    dataSource: ref.watch(geocodingDataSourceProvider),
  );
});

final searchCitiesProvider = Provider<SearchCities>((ref) {
  return SearchCities(ref.watch(geocodingRepositoryProvider));
});

final reverseGeocodeProvider = Provider<ReverseGeocode>((ref) {
  return ReverseGeocode(ref.watch(geocodingRepositoryProvider));
});

/// The already-open Hive box favorites are stored in — opened once at
/// startup by [HiveBoxes.openAll] (or by tests' global setup), so it's
/// always safe to read synchronously here.
final favoritesBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box(HiveBoxes.favorites);
});

final favoritesLocalDataSourceProvider = Provider<FavoritesLocalDataSource>((
  ref,
) {
  return HiveFavoritesDataSource(box: ref.watch(favoritesBoxProvider));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(
    localDataSource: ref.watch(favoritesLocalDataSourceProvider),
  );
});

final getFavoritesProvider = Provider<GetFavorites>((ref) {
  return GetFavorites(ref.watch(favoritesRepositoryProvider));
});

final addFavoriteProvider = Provider<AddFavorite>((ref) {
  return AddFavorite(ref.watch(favoritesRepositoryProvider));
});

final removeFavoriteProvider = Provider<RemoveFavorite>((ref) {
  return RemoveFavorite(ref.watch(favoritesRepositoryProvider));
});

final currentWeatherCacheBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box(HiveBoxes.currentWeatherCache);
});

final forecastCacheBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box(HiveBoxes.forecastCache);
});

final weatherCacheLocalDataSourceProvider =
    Provider<WeatherCacheLocalDataSource>((ref) {
      return HiveWeatherCacheDataSource(
        currentWeatherBox: ref.watch(currentWeatherCacheBoxProvider),
        forecastBox: ref.watch(forecastCacheBoxProvider),
      );
    });

final weatherCacheRepositoryProvider = Provider<WeatherCacheRepository>((ref) {
  return WeatherCacheRepositoryImpl(
    localDataSource: ref.watch(weatherCacheLocalDataSourceProvider),
  );
});

/// The already-open Hive box settings are stored in — opened once at
/// startup by [HiveBoxes.openAll] (or by tests' global setup), so it's
/// always safe to read synchronously here.
final settingsBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box(HiveBoxes.settings);
});

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((
  ref,
) {
  return HiveSettingsDataSource(box: ref.watch(settingsBoxProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    localDataSource: ref.watch(settingsLocalDataSourceProvider),
  );
});

final getSettingsProvider = Provider<GetSettings>((ref) {
  return GetSettings(ref.watch(settingsRepositoryProvider));
});

final saveTemperatureUnitProvider = Provider<SaveTemperatureUnit>((ref) {
  return SaveTemperatureUnit(ref.watch(settingsRepositoryProvider));
});

final saveThemeModeProvider = Provider<SaveThemeMode>((ref) {
  return SaveThemeMode(ref.watch(settingsRepositoryProvider));
});

final saveOfflineDataEnabledProvider = Provider<SaveOfflineDataEnabled>((ref) {
  return SaveOfflineDataEnabled(ref.watch(settingsRepositoryProvider));
});

/// Persists the last searched city so startup can restore it (see
/// [SelectedCityNotifier]).
final lastSearchedCityStoreProvider = Provider<LastSearchedCityStore>((ref) {
  return LastSearchedCityStore(box: ref.watch(settingsBoxProvider));
});
