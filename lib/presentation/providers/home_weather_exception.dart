/// Wraps a domain `Failure`'s message so [HomeWeatherNotifier] can throw it
/// and have Riverpod capture it as `AsyncValue.error`, with the UI able to
/// pull out a user-facing [message] rather than a generic error string.
class HomeWeatherFailureException implements Exception {
  const HomeWeatherFailureException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown by `currentLocationProvider` while a searched city is selected:
/// the device location isn't needed then, so it must not be requested (no
/// permission prompt, no GPS wait) just because something watches it.
/// Consumers that watch it for UI state treat this as "not locating".
class LocationNotNeededException extends HomeWeatherFailureException {
  const LocationNotNeededException()
    : super('A city is selected; device location is not needed.');
}
