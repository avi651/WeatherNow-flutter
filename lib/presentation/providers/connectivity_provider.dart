import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';

/// The device's online/offline state: its state at startup, then every
/// change. Repeated identical values are dropped so listeners only react
/// to real transitions.
///
/// Subscribes to changes *before* asking for the startup state, so a change
/// landing while that check is in flight isn't lost — and if one does, it
/// wins over the (by then stale) startup reading.
final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  final controller = StreamController<bool>();
  bool? last;
  var sawChange = false;

  void publish(bool online) {
    if (online == last || controller.isClosed) return;
    last = online;
    controller.add(online);
  }

  final subscription = service.onlineChanges.listen((online) {
    sawChange = true;
    publish(online);
  });
  service.checkOnline().then((online) {
    if (!sawChange) publish(online);
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });
  return controller.stream;
});

/// [connectivityProvider] as a plain `bool` — assumed online until the
/// first reading arrives, so the offline banner never flashes at startup.
/// Being a `Provider<bool>`, watchers rebuild only when it flips.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true;
});
