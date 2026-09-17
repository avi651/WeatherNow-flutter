/// Thrown by [GeocodingApiService] when a city search request fails —
/// whether from a network error, a non-2xx response, or a response body
/// that isn't valid JSON.
///
/// Mirrors [WeatherApiException]'s shape and purpose: the data layer
/// throws, and the repository's job is to catch this and translate it
/// into a domain [Failure].
class GeocodingApiException implements Exception {
  GeocodingApiException(this.message, {this.statusCode});

  final String message;

  /// The HTTP status code that caused this, when applicable.
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'GeocodingApiException: $message'
      : 'GeocodingApiException: $message (status: $statusCode)';
}
