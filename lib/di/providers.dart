import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_now_flutter/core/config/app_environment.dart';
import 'package:weather_now_flutter/core/location/geolocator_location_service.dart';
import '../core/location/location_service.dart';
import '../core/network/api_client.dart';
import '../core/network/dio_client_config.dart';
import '../core/network/dio_exception_mapper.dart';
import '../data/datasources/geocoding_api_service.dart';
import '../data/datasources/geocoding_data_source.dart';
import '../data/datasources/geocoding_mock_data_source.dart';
import '../data/datasources/weather_api_service.dart';
import '../data/datasources/weather_data_source.dart';
import '../data/datasources/weather_mock_data_source.dart';
import '../data/repositories/geocoding_repository_impl.dart';
import '../data/repositories/weather_repository_impl.dart';
import '../domain/repositories/geocoding_repository.dart';
import '../domain/repositories/weather_repository.dart';
import '../domain/usecases/get_current_weather.dart';
import '../domain/usecases/get_forecast.dart';
import '../domain/usecases/reverse_geocode.dart';
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
final isMockEnvironmentProvider = Provider<bool>((ref) => AppEnvironment.isMock);

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
  return GeocodingRepositoryImpl(dataSource: ref.watch(geocodingDataSourceProvider));
});

final searchCitiesProvider = Provider<SearchCities>((ref) {
  return SearchCities(ref.watch(geocodingRepositoryProvider));
});

final reverseGeocodeProvider = Provider<ReverseGeocode>((ref) {
  return ReverseGeocode(ref.watch(geocodingRepositoryProvider));
});
