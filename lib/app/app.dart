import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../di/providers.dart';
import '../presentation/providers/theme_mode_provider.dart';
import '../presentation/providers/weather_refresh_provider.dart';
import '../presentation/screens/home_screen.dart';

/// Root widget of the application.
///
/// Keep this file limited to app-level wiring (theme, routes, localization).
/// Feature UI belongs under `presentation/screens`.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// On resume, fetch fresh data if online. Offline there's nothing to
  /// refresh — what's on screen (live or cached) stays.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refreshIfOnline();
  }

  Future<void> _refreshIfOnline() async {
    final online = await ref.read(connectivityServiceProvider).checkOnline();
    if (online && mounted) ref.read(refreshWeatherProvider)();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeatherNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      home: const HomeScreen(),
    );
  }
}
