import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/location_permission_status.dart';
import '../../di/providers.dart';

/// The device's current location-permission status, for the Settings
/// screen to display. Re-checked from scratch on every (re)watch —
/// callers invalidate this after an action that might have changed it
/// (opening system settings, or the app resuming from the background),
/// since the OS can change this outside the app.
final locationPermissionStatusProvider =
    FutureProvider<LocationPermissionStatus>((ref) {
  return ref.watch(locationServiceProvider).checkPermissionStatus();
});
