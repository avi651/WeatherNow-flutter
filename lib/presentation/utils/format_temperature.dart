import '../../domain/entities/temperature_unit.dart';

/// Formats a Celsius reading for display in [unit], rounded to the
/// nearest whole degree with its unit suffix (e.g. "24°C" / "75°F") —
/// weather data is always fetched and cached in Celsius, so every display
/// site converts at render time rather than storing a second, unit-
/// dependent copy.
String formatTemperature(double celsius, TemperatureUnit unit) {
  final value = unit == TemperatureUnit.fahrenheit
      ? celsius * 9 / 5 + 32
      : celsius;
  final suffix = unit == TemperatureUnit.fahrenheit ? '°F' : '°C';

  return '${value.round()}$suffix';
}
