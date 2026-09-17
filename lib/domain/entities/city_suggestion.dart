/// A city (or town) returned by a geocoding search, with the coordinates
/// needed to fetch weather for it.
///
/// [state] is nullable — not every country's geocoding result includes an
/// administrative region (e.g. city-states like Singapore).
class CitySuggestion {
  const CitySuggestion({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.state,
  });

  final String name;
  final String? state;
  final String country;
  final double latitude;
  final double longitude;

  /// A human-readable label for display, e.g. "Mumbai, Maharashtra, IN"
  /// or "Singapore, SG" when there's no state to show.
  String get displayLabel {
    final parts = [
      name,
      if (state != null && state!.isNotEmpty) state!,
      country,
    ];
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CitySuggestion &&
        other.name == name &&
        other.state == state &&
        other.country == country &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(name, state, country, latitude, longitude);

  @override
  String toString() => 'CitySuggestion(displayLabel: $displayLabel, '
      'latitude: $latitude, longitude: $longitude)';
}
