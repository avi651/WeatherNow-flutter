import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_theme_mode.dart';
import 'settings_provider.dart';

/// Maps the domain-pure [AppThemeMode] onto Flutter's own [ThemeMode] —
/// the only place this app's theme preference touches a Flutter type —
/// for [App] to pass straight to `MaterialApp.themeMode`.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode =
      ref.watch(settingsProvider).value?.themeMode ?? AppSettings.defaults.themeMode;

  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
});
