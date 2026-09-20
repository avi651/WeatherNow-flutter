import 'package:flutter/material.dart';

/// Every hardcoded color value used by the app theme, in one place.
abstract final class AppColors {
  // Shared
  static const seed = Color(0xFF4F8FFF);

  // Dark theme
  static const darkSurface = Color(0xFF0D1B2A);
  static const darkSurfaceContainerLowest = Color(0xFF071019);
  static const darkSurfaceContainerLow = Color(0xFF122238);
  static const darkSurfaceContainer = Color(0xFF17293F);
  static const darkSurfaceContainerHigh = Color(0xFF1E3350);
  static const darkSurfaceContainerHighest = Color(0xFF264063);
  static const darkOutline = Color(0xFF3A4F72);
  static const darkOutlineVariant = Color(0xFF223353);
  static const darkSecondary = Color(0xFF6FD6FF);
  static const darkTertiary = Color(0xFFFFB871);

  // Light theme
  static const lightSecondary = Color(0xFF3E7CB1);
  static const lightTertiary = Color(0xFFB56A2C);
}
