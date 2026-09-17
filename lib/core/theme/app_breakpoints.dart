import 'app_spacing.dart';

/// Responsive screen size categories.
enum ScreenSizeClass { compact, medium, expanded }

/// Centralized responsive breakpoints.
class AppBreakpoints {
  const AppBreakpoints._();

  /// Small phone breakpoint.
  static const double compact = 360;

  /// Tablet breakpoint.
  static const double tablet = 600;

  /// Maximum content width on larger screens.
  static const double contentMaxWidth = 480;

  /// Returns the appropriate screen size class.
  static ScreenSizeClass classify(double width) {
    if (width < compact) {
      return ScreenSizeClass.compact;
    }

    if (width < tablet) {
      return ScreenSizeClass.medium;
    }

    return ScreenSizeClass.expanded;
  }

  /// Returns responsive spacing based on screen size.
  static double spacingForSizeClass(ScreenSizeClass sizeClass) {
    return switch (sizeClass) {
      ScreenSizeClass.compact => AppSpacing.sm,
      ScreenSizeClass.medium => AppSpacing.md,
      ScreenSizeClass.expanded => AppSpacing.xl,
    };
  }
}
