import 'package:dartz/dartz.dart';

import '../error/failures.dart';
import 'device_location.dart';

/// Resolves the device's current location.
///
/// Abstracted behind an interface (rather than calling `Geolocator`'s
/// static methods directly from consumers) so it can be swapped for a
/// test double — `geolocator`'s API is static/platform-channel-based and
/// can't be mocked directly with mocktail the way an injected object can.
abstract class LocationService {
  Future<Either<Failure, DeviceLocation>> getCurrentLocation();
}
