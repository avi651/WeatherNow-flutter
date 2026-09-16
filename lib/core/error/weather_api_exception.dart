/// Thrown by [WeatherApiService] when a request to the weather provider
/// fails — whether from a network error, a non-2xx response, or a response
/// body that isn't valid JSON.
///
/// This stays a plain exception rather than a domain `Failure`: the data
/// layer throws, and it's the repository's job (later) to catch this and
/// translate it into whatever error representation the domain layer uses.
class WeatherApiException implements Exception {
  WeatherApiException(this.message, {this.statusCode});

  final String message;

  /// The HTTP status code that caused this, when applicable.
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'WeatherApiException: $message'
      : 'WeatherApiException: $message (status: $statusCode)';
}
