import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

import '../error/failures.dart';
import '../error/location_failures.dart';
import 'device_location.dart';
import 'location_service.dart';

/// Resolves the device's current location via the `geolocator` plugin,
/// handling the service-enabled and permission checks it requires.
///
/// Not unit tested directly: `Geolocator`'s API is a set of static
/// methods backed by platform channels, so there's no injectable client
/// to mock the way `Dio` or `ApiClient` can be. Instead, this class is
/// kept as a thin, easily-read pass-through, and everything that
/// *consumes* [LocationService] is tested against the abstraction with a
/// mock — the same way this codebase never unit-tested that `Dio`
/// performs real HTTP requests either.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<Either<Failure, DeviceLocation>> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const Left(
        LocationServiceDisabledFailure(
          'Location services are turned off. Please enable them to see weather for your location.',
        ),
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const Left(
          LocationPermissionDeniedFailure(
            'Location permission was denied.',
          ),
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const Left(
        LocationPermissionDeniedForeverFailure(
          'Location permission is permanently denied. Enable it from system settings.',
        ),
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return Right(
        DeviceLocation(latitude: position.latitude, longitude: position.longitude),
      );
    } catch (error) {
      return Left(
        LocationUnavailableFailure('Could not determine current location: $error'),
      );
    }
  }
}
