import 'package:geolocator/geolocator.dart';

import 'device_location.dart';

/// The slice of the `geolocator` plugin that [GeolocatorLocationService]
/// needs, as an injectable interface.
///
/// `Geolocator`'s API is a set of static methods backed by platform
/// channels, so it can't be replaced in a unit test. Putting this seam in
/// front of it lets the service's own logic — permission flow, timeout,
/// failure mapping — be tested with a fake instead of device hardware.
abstract interface class GeolocatorClient {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  /// Resolves the current position, asking the platform to give up after
  /// [timeLimit] (which surfaces as a `TimeoutException`).
  Future<DeviceLocation> getCurrentLocation({required Duration timeLimit});

  Future<void> openLocationSettings();

  Future<void> openAppSettings();
}

/// The production [GeolocatorClient]: a pass-through to `Geolocator`.
class PlatformGeolocatorClient implements GeolocatorClient {
  const PlatformGeolocatorClient();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<DeviceLocation> getCurrentLocation({
    required Duration timeLimit,
  }) async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeLimit,
      ),
    );
    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
