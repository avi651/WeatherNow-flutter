import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/network/connectivity_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/presentation/providers/connectivity_provider.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService({this.online = true});

  final bool online;
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> checkOnline() async => online;

  @override
  Stream<bool> get onlineChanges => controller.stream;
}

void main() {
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  ProviderContainer build(_FakeConnectivityService service) {
    final container = ProviderContainer(
      overrides: [connectivityServiceProvider.overrideWithValue(service)],
    );
    addTearDown(() {
      container.dispose();
      service.controller.close();
    });
    return container;
  }

  test('assumes online until the first reading arrives', () {
    final container = build(_FakeConnectivityService());
    container.listen(isOnlineProvider, (_, _) {});

    expect(container.read(isOnlineProvider), isTrue);
  });

  test('reports the startup state, e.g. launching offline', () async {
    final container = build(_FakeConnectivityService(online: false));
    container.listen(isOnlineProvider, (_, _) {});
    await settle();

    expect(container.read(isOnlineProvider), isFalse);
  });

  test('follows loss and restoration of connectivity immediately', () async {
    final service = _FakeConnectivityService();
    final container = build(service);
    container.listen(isOnlineProvider, (_, _) {});
    await settle();

    service.controller.add(false);
    await settle();
    expect(container.read(isOnlineProvider), isFalse);

    service.controller.add(true);
    await settle();
    expect(container.read(isOnlineProvider), isTrue);
  });

  test(
    'drops repeated readings so listeners only see real transitions',
    () async {
      final service = _FakeConnectivityService();
      final container = build(service);
      final seen = <bool>[];
      container.listen<AsyncValue<bool>>(connectivityProvider, (_, next) {
        final value = next.value;
        if (value != null) seen.add(value);
      });
      await settle();

      service.controller
        ..add(true)
        ..add(false)
        ..add(false)
        ..add(true);
      await settle();

      expect(seen, [true, false, true]);
    },
  );
}
