import 'package:flutter/material.dart';

import '../../domain/entities/weather_condition.dart';

/// Maps a [WeatherCondition] to the icon used to represent it, so every
/// widget that shows a condition icon agrees on which one.
IconData weatherConditionIcon(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.clear:
      return Icons.wb_sunny;
    case WeatherCondition.clouds:
      return Icons.cloud;
    case WeatherCondition.rain:
      return Icons.grain;
    case WeatherCondition.drizzle:
      return Icons.grain;
    case WeatherCondition.thunderstorm:
      return Icons.thunderstorm;
    case WeatherCondition.snow:
      return Icons.ac_unit;
    case WeatherCondition.atmosphere:
      return Icons.blur_on;
    case WeatherCondition.unknown:
      return Icons.help_outline;
  }
}
