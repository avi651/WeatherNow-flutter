import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../presentation/providers/theme_mode_provider.dart';
import '../presentation/screens/home_screen.dart';

/// Root widget of the application.
///
/// Keep this file limited to app-level wiring (theme, routes, localization).
/// Feature UI belongs under `presentation/screens`.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
