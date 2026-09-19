import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../error/error_logger.dart';
import '../error/failures.dart';
import '../error/location_failures.dart';
import 'device_location.dart';
import 'geolocator_client.dart';
import 'location_permission_status.dart';
import 'location_service.dart';

/// Resolves the device's current location via a [GeolocatorClient],
/// handling the service-enabled and permission checks it requires.
///
/// The client defaults to the real `geolocator` plugin; tests inject a fake
/// (see `geolocator_location_service_test.dart`).
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService({
    GeolocatorClient client = const PlatformGeolocatorClient(),
  }) : _client = client;

  final GeolocatorClient _client;

  static const positionTimeout = Duration(seconds: 15);

  @override
  Future<Either<Failure, DeviceLocation>> getCurrentLocation() async {
    final serviceEnabled = await _client.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const Left(
        LocationServiceDisabledFailure(AppStrings.locationServicesDisabled),
      );
    }

    var permission = await _client.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _client.requestPermission();
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
      final location = await _client
          .getCurrentLocation(timeLimit: positionTimeout)
          .timeout(positionTimeout);
      return Right(location);
    } on TimeoutException {
      return const Left(
        LocationUnavailableFailure(AppStrings.locationTimedOut),
      );
    } catch (error) {
      logError('Could not determine current location', error);
      return const Left(
        LocationUnavailableFailure(AppStrings.locationUnavailable),
      );
    }
  }

  @override
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    final serviceEnabled = await _client.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    final permission = await _client.checkPermission();
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
    final serviceEnabled = await _client.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    var permission = await _client.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _client.requestPermission();
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
    await _client.openLocationSettings();
  }

  @override
  Future<void> openAppSettings() async {
    await _client.openAppSettings();
  }
}
