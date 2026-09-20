import 'package:flutter/foundation.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';

/// Outcome of a device integrity check.
enum DeviceIntegrityStatus {
  /// No jailbreak/root indicators were found.
  trusted,

  /// Jailbreak (iOS) or root (Android) indicators were found.
  compromised,

  /// The check could not run or failed (unsupported platform, plugin
  /// error, timeout). Not evidence of either state.
  unknown,
}

/// Detects jailbroken (iOS) / rooted (Android) devices.
///
/// Advisory only: detection is bypassable and never blocks the app.
abstract class DeviceIntegrityChecker {
  Future<DeviceIntegrityStatus> check();
}

/// [DeviceIntegrityChecker] backed by `jailbreak_root_detection`
/// (RootBeer on Android, IOSSecuritySuite on iOS).
///
/// Deliberately uses `isJailBroken` and NOT the package's `isNotTrust`:
/// `isNotTrust` also reports emulators/simulators and Android apps on
/// external storage, and returns true when its own check errors — all
/// false positives for this purpose.
class PluginDeviceIntegrityChecker implements DeviceIntegrityChecker {
  PluginDeviceIntegrityChecker({
    Future<bool> Function()? isJailBroken,
    bool Function()? isSupportedPlatform,
    this.timeout = const Duration(seconds: 5),
  }) : _isJailBroken =
           isJailBroken ?? (() => JailbreakRootDetection.instance.isJailBroken),
       _isSupportedPlatform = isSupportedPlatform ?? _defaultSupported;

  final Future<bool> Function() _isJailBroken;
  final bool Function() _isSupportedPlatform;
  final Duration timeout;

  static bool _defaultSupported() =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<DeviceIntegrityStatus> check() async {
    if (!_isSupportedPlatform()) return DeviceIntegrityStatus.unknown;
    try {
      final compromised = await _isJailBroken().timeout(timeout);
      return compromised
          ? DeviceIntegrityStatus.compromised
          : DeviceIntegrityStatus.trusted;
    } catch (_) {
      return DeviceIntegrityStatus.unknown;
    }
  }
}
