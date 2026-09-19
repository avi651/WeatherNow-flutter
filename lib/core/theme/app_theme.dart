import 'package:flutter/material.dart';

/// Centralized theme definitions for the app.
///
/// Builds a premium, weather-app-appropriate dark palette from a single
/// seed color via [ColorScheme.fromSeed], then nudges the surface tones
/// toward a deep navy (rather than Material's default neutral-grey dark
/// surfaces) so cards and the scaffold read as "night sky", not generic
/// Material dark mode.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF4F8FFF);

  static ThemeData get dark {
    final seeded = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    final colorScheme = seeded.copyWith(
      surface: const Color(0xFF0D1B2A),
      surfaceContainerLowest: const Color(0xFF071019),
      surfaceContainerLow: const Color(0xFF122238),
      surfaceContainer: const Color(0xFF17293F),
      surfaceContainerHigh: const Color(0xFF1E3350),
      surfaceContainerHighest: const Color(0xFF264063),
      outline: const Color(0xFF3A4F72),
      outlineVariant: const Color(0xFF223353),
      secondary: const Color(0xFF6FD6FF),
      tertiary: const Color(0xFFFFB871),
    );

    final baseTextTheme = ThemeData(brightness: Brightness.dark).textTheme;
    final textTheme = baseTextTheme
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        )
        .copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: colorScheme.onSurface,
          ),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: colorScheme.onSurface,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            height: 1.35,
            color: colorScheme.onSurfaceVariant,
          ),
          bodySmall: baseTextTheme.bodySmall?.copyWith(
            height: 1.3,
            color: colorScheme.onSurfaceVariant,
          ),
          labelMedium: baseTextTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      dividerColor: colorScheme.outlineVariant,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.20),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// The Appearance section's "Light" option. Mirrors [dark]'s structure
  /// (same seed color, same nudged-surface-tone approach, same component
  /// theming) so switching between them changes only brightness — not the
  /// app's overall shape or spacing.
  static ThemeData get light {
    final seeded = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    final colorScheme = seeded.copyWith(
      secondary: const Color(0xFF3E7CB1),
      tertiary: const Color(0xFFB56A2C),
    );

    final baseTextTheme = ThemeData(brightness: Brightness.light).textTheme;
    final textTheme = baseTextTheme
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        )
        .copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: colorScheme.onSurface,
          ),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: colorScheme.onSurface,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            height: 1.35,
            color: colorScheme.onSurfaceVariant,
          ),
          bodySmall: baseTextTheme.bodySmall?.copyWith(
            height: 1.3,
            color: colorScheme.onSurfaceVariant,
          ),
          labelMedium: baseTextTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      dividerColor: colorScheme.outlineVariant,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.20),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
