import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/theme/app_theme.dart';

void main() {
  group('AppTheme.dark', () {
    final theme = AppTheme.dark;

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('is a dark theme', () {
      expect(theme.brightness, Brightness.dark);
    });

    test('uses the app navy background color', () {
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0D1B2A));
    });
  });
}
