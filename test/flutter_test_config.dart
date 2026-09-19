import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:weather_now_flutter/data/local/hive_boxes.dart';

/// Global test setup, run once per test file before its `main()`.
///
/// Initializes Hive against a throwaway temp directory (plain [Hive.init],
/// not [Hive.initFlutter] — that needs `path_provider`'s platform channel,
/// which isn't available in the `flutter_test` VM environment) and opens
/// the app's boxes, then clears them before every individual test so tests
/// in the same file never see data left behind by an earlier one.
///
/// Note for widget tests: a real Hive box *write* (`put`/`delete`) needs
/// real asynchronous I/O to complete, which never resolves under
/// `testWidgets`' default fake-async pump clock — only `tester.runAsync()`
/// or a plain `test()` can wait for it. Reads (`get`/`values`) are fine
/// either way, since Hive keeps box contents decoded in memory. Widget
/// tests that don't specifically exercise persistence should override
/// `favoritesRepositoryProvider`/`weatherCacheRepositoryProvider` with a
/// mock instead of hitting these real boxes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final tempDir = await Directory.systemTemp.createTemp(
    'weather_now_hive_test',
  );
  Hive.init(tempDir.path);
  await HiveBoxes.openAll();

  setUp(() async {
    // Re-open defensively: something about the transition from this
    // top-level setup into each test's own zone closes Hive's open boxes
    // (same `Hive` instance, different `Zone`) even though nothing here
    // ever calls `close()`. `openBox` is a cheap no-op when a box is
    // already open, so this is a safe, low-cost guard either way.
    await HiveBoxes.openAll();
    await HiveBoxes.clearAll();
  });

  await testMain();

  await Hive.close();
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}
