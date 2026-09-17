import '../../core/constants/geocoding_api_endpoints.dart';
import '../../core/error/failures.dart';
import '../../core/error/geocoding_api_exception.dart';
import '../../core/error/network_failures.dart';
import '../../core/network/api_client.dart';
import '../../core/network/geocoding_api_params.dart';
import 'geocoding_data_source.dart';

class GeocodingApiService implements GeocodingDataSource {
  const GeocodingApiService({
    required ApiClient apiClient,
    required String apiKey,
  }) : _apiClient = apiClient,
       _apiKey = apiKey;

  final ApiClient _apiClient;
  final String _apiKey;

  @override
  Future<List<Map<String, dynamic>>> searchCities({
    required String query,
  }) async {
    final result = await _apiClient.get<List<dynamic>>(
      GeocodingApiEndpoints.directGeocoding,
      queryParameters: GeocodingApiParams.search(query: query, apiKey: _apiKey),
    );

    return result.fold((failure) => throw _mapFailure(failure), (response) {
      final data = response.data;

      if (data == null) return const [];

      return data.cast<Map<String, dynamic>>();
    });
  }

  @override
  Future<List<Map<String, dynamic>>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final result = await _apiClient.get<List<dynamic>>(
      GeocodingApiEndpoints.reverseGeocoding,
      queryParameters: GeocodingApiParams.reverse(
        latitude: latitude,
        longitude: longitude,
        apiKey: _apiKey,
      ),
    );

    return result.fold((failure) => throw _mapFailure(failure), (response) {
      final data = response.data;

      if (data == null) return const [];

      return data.cast<Map<String, dynamic>>();
    });
  }

  GeocodingApiException _mapFailure(Failure failure) {
    if (failure is ServerFailure) {
      return GeocodingApiException(
        failure.message,
        statusCode: failure.statusCode,
      );
    }

    return GeocodingApiException(failure.message);
  }
}
