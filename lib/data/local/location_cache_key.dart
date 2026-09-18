/// Builds the key local storage uses to identify a location, shared by the
/// favorites box and the weather-cache boxes so a favorite and its cached
/// weather always agree on how to find each other.
class LocationCacheKey {
  const LocationCacheKey._();

  /// Rounds coordinates to 4 decimal places (~11m of precision) so weather
  /// fetched for "essentially the same" location — e.g. tiny GPS jitter
  /// between two fetches — lands in the same cache entry instead of
  /// fragmenting into near-duplicate keys.
  static String of({required double latitude, required double longitude}) {
    return '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
  }
}
