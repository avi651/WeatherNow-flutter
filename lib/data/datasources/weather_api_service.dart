import '../../core/error/network_failures.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/weather_api_endpoints.dart';
import '../../core/error/weather_api_exception.dart';
import '../../core/network/weather_api_params.dart';
import 'weather_data_source.dart';

class WeatherApiService implements WeatherDataSource {
  const WeatherApiService({
    required ApiClient apiClient,
    required String apiKey,
  }) : _apiClient = apiClient,
       _apiKey = apiKey;

  final ApiClient _apiClient;
  final String _apiKey;

  @override
  Future<Map<String, dynamic>> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) {
    return _fetch(WeatherApiEndpoints.currentWeather, latitude, longitude);
  }

  @override
  Future<Map<String, dynamic>> getForecast({
    required double latitude,
    required double longitude,
  }) {
    return _fetch(WeatherApiEndpoints.forecast, latitude, longitude);
  }

  Future<Map<String, dynamic>> _fetch(
    String url,
    double latitude,
    double longitude,
  ) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      url,
      queryParameters: WeatherApiParams.coordinates(
        latitude: latitude,
        longitude: longitude,
        apiKey: _apiKey,
      ),
    );

    return result.fold((failure) => throw _mapFailure(failure), (response) {
      final data = response.data;

      if (data == null) {
        throw WeatherApiException('Empty response from weather service');
      }

      return data;
    });
  }

  WeatherApiException _mapFailure(Failure failure) {
    if (failure is ServerFailure) {
      return WeatherApiException(
        failure.message,
        statusCode: failure.statusCode,
      );
    }

    return WeatherApiException(failure.message);
  }
}
