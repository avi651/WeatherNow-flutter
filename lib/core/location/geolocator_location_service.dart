import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../error/failures.dart';
import '../error/location_failures.dart';
import 'device_location.dart';
import 'location_permission_status.dart';
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

  static const positionTimeout = Duration(seconds: 15);

  @override
  Future<Either<Failure, DeviceLocation>> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const Left(
        LocationServiceDisabledFailure(AppStrings.locationServicesDisabled),
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const Left(
          LocationPermissionDeniedFailure(AppStrings.locationPermissionDenied),
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const Left(
        LocationPermissionDeniedForeverFailure(
          AppStrings.locationPermissionDeniedForever,
        ),
      );
    }

    try {
      // Both limits matter: `timeLimit` is honored by the platform
      // plugins, while `.timeout` guarantees we stop waiting even when a
      // platform never reports (e.g. iOS Simulator with no location set).
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: positionTimeout,
        ),
      ).timeout(positionTimeout);
      return Right(
        DeviceLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on TimeoutException {
      return const Left(
        LocationUnavailableFailure(AppStrings.locationTimedOut),
      );
    } catch (error) {
      return Left(
        LocationUnavailableFailure(
          'Could not determine current location: $error',
        ),
      );
    }
  }

  @override
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    final permission = await Geolocator.checkPermission();
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionStatus.granted,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
    };
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionStatus.granted,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
    };
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
