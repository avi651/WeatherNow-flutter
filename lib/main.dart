import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/security/device_integrity_checker.dart';
import 'core/security/device_integrity_report.dart';
import 'data/local/secure_hive_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SecureHiveInitializer().openAll();

  runApp(const ProviderScope(child: App()));

  // Advisory only: runs after startup and never blocks or alters the app.
  unawaited(reportDeviceIntegrity(PluginDeviceIntegrityChecker()));
}
