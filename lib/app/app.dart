import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Root widget of the application.
///
/// Keep this file limited to app-level wiring (theme, routes, localization).
/// Feature UI belongs under `presentation/screens`.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const Scaffold(
        body: Center(
          child: Text('Home placeholder'),
        ),
      ),
    );
  }
}
