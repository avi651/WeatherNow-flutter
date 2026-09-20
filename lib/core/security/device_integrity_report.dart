import '../error/error_logger.dart';
import 'device_integrity_checker.dart';

/// Runs [checker] and logs the result. Never throws and never affects app
/// flow, so it is safe to fire-and-forget from `main()`.
Future<DeviceIntegrityStatus> reportDeviceIntegrity(
  DeviceIntegrityChecker checker,
) async {
  try {
    final status = await checker.check();
    if (status == DeviceIntegrityStatus.compromised) {
      logError(
        'Device integrity',
        'Jailbreak/root indicators detected; local data protection is weakened.',
      );
    }
    return status;
  } catch (_) {
    return DeviceIntegrityStatus.unknown;
  }
}
