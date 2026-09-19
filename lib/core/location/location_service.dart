import 'package:dartz/dartz.dart';

import '../error/failures.dart';
import 'device_location.dart';
import 'location_permission_status.dart';

/// Resolves the device's current location.
///
/// Abstracted behind an interface (rather than calling `Geolocator`'s
/// static methods directly from consumers) so it can be swapped for a
/// test double — `geolocator`'s API is static/platform-channel-based and
/// can't be mocked directly with mocktail the way an injected object can.
abstract class LocationService {
  Future<Either<Failure, DeviceLocation>> getCurrentLocation();

  /// Checks the current permission/service state without requesting
  /// anything or fetching a position — for UI that only needs to show
  /// current status (e.g. the Settings screen).
  Future<LocationPermissionStatus> checkPermissionStatus();

  /// Requests the permission, prompting the user if it hasn't been
  /// decided yet, without fetching a position. Returns the resulting
  /// status; on a platform where the user already permanently denied it,
  /// this resolves immediately without prompting again.
  Future<LocationPermissionStatus> requestPermission();

  /// Opens the OS's location-services settings screen.
  Future<void> openLocationSettings();

  /// Opens this app's page in the OS settings — the only way to grant a
  /// permanently-denied permission from within the app.
  Future<void> openAppSettings();
}
