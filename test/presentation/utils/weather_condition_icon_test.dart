import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/presentation/utils/weather_condition_icon.dart';

void main() {
  final expected = {
    WeatherCondition.clear: Icons.wb_sunny,
    WeatherCondition.clouds: Icons.cloud,
    WeatherCondition.rain: Icons.grain,
    WeatherCondition.drizzle: Icons.grain,
    WeatherCondition.thunderstorm: Icons.thunderstorm,
    WeatherCondition.snow: Icons.ac_unit,
    WeatherCondition.atmosphere: Icons.blur_on,
    WeatherCondition.unknown: Icons.help_outline,
  };

  expected.forEach((condition, icon) {
    test('maps $condition to $icon', () {
      expect(weatherConditionIcon(condition), icon);
    });
  });
}
