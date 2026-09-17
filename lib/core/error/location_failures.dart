import 'failures.dart';

/// The device's location services (GPS) are turned off entirely.
class LocationServiceDisabledFailure extends Failure {
  const LocationServiceDisabledFailure(super.message);
}

/// The user denied the location permission request (but can still be
/// asked again).
class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure(super.message);
}

/// The user permanently denied the location permission ("don't ask
/// again"); it can only be re-enabled from system settings.
class LocationPermissionDeniedForeverFailure extends Failure {
  const LocationPermissionDeniedForeverFailure(super.message);
}

/// Permission and service checks passed, but a position still couldn't
/// be obtained (e.g. no GPS fix, or a platform error).
class LocationUnavailableFailure extends Failure {
  const LocationUnavailableFailure(super.message);
}
