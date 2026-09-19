/// A resolved device location. Deliberately minimal — just what the
/// weather API needs — so callers don't need to depend on `geolocator`'s
/// own `Position` type (which carries altitude, speed, heading, etc.
/// that nothing here uses).
class DeviceLocation {
  const DeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceLocation &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() =>
      'DeviceLocation(latitude: $latitude, longitude: $longitude)';
}
