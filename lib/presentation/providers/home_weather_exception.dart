/// Wraps a domain `Failure`'s message so [HomeWeatherNotifier] can throw it
/// and have Riverpod capture it as `AsyncValue.error`, with the UI able to
/// pull out a user-facing [message] rather than a generic error string.
class HomeWeatherFailureException implements Exception {
  const HomeWeatherFailureException(this.message);

  final String message;

  @override
  String toString() => message;
}
