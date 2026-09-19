import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The app's version and build number (e.g. "1.0.0 (1)"), for the
/// Settings screen's About section — read once via `package_info_plus`,
/// which reads the platform's own app metadata rather than anything this
/// app tracks itself.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});
