import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/security/device_integrity_checker.dart';
import 'package:weather_now_flutter/core/security/device_integrity_report.dart';

import '../../support/captured_error_logs.dart';

PluginDeviceIntegrityChecker checker(
  Future<bool> Function() probe, {
  bool supported = true,
  Duration timeout = const Duration(seconds: 1),
}) => PluginDeviceIntegrityChecker(
  isJailBroken: probe,
  isSupportedPlatform: () => supported,
  timeout: timeout,
);

void main() {
  test('reports trusted when no indicators are found', () async {
    expect(
      await checker(() async => false).check(),
      DeviceIntegrityStatus.trusted,
    );
  });

  test('reports compromised when jailbreak/root is detected', () async {
    expect(
      await checker(() async => true).check(),
      DeviceIntegrityStatus.compromised,
    );
  });

  test('reports unknown (not compromised) when the plugin throws', () async {
    expect(
      await checker(() async => throw Exception('channel error')).check(),
      DeviceIntegrityStatus.unknown,
    );
  });

  test('reports unknown when the check times out', () async {
    final slow = checker(
      () => Completer<bool>().future,
      timeout: const Duration(milliseconds: 10),
    );
    expect(await slow.check(), DeviceIntegrityStatus.unknown);
  });

  test('does not call the plugin on unsupported platforms', () async {
    var called = false;
    final c = checker(() async {
      called = true;
      return true;
    }, supported: false);

    expect(await c.check(), DeviceIntegrityStatus.unknown);
    expect(called, isFalse);
  });

  test('reportDeviceIntegrity logs only for compromised devices', () async {
    await reportDeviceIntegrity(checker(() async => false));
    expect(capturedErrorLogs, isEmpty);

    final status = await reportDeviceIntegrity(checker(() async => true));
    expect(status, DeviceIntegrityStatus.compromised);
    expect(capturedErrorLogs, hasLength(1));
  });
}
