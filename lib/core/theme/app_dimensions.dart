import 'app_breakpoints.dart';

abstract final class AppDimensions {
  const AppDimensions._();

  static const double forecastCardMinWidth = 64.0;
  static const double forecastCardMaxWidth = 104.0;
  static const double forecastCardAspectRatio = 0.62;

  static double avatarRadius(ScreenSizeClass sizeClass) {
    return sizeClass == ScreenSizeClass.expanded ? 28.0 : 20.0;
  }

  static double forecastCardWidth(double availableWidth) {
    final calculatedWidth = availableWidth / 5;

    return calculatedWidth
        .clamp(forecastCardMinWidth, forecastCardMaxWidth)
        .toDouble();
  }
}
