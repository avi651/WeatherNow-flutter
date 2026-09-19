import 'weather_condition.dart';

/// A snapshot of the current weather at a single point in time.
///
/// This entity is intentionally shaped around what the app needs, not
/// around any particular provider's API response.
class CurrentWeather {
  CurrentWeather({
    required this.temperatureCelsius,
    required this.feelsLikeCelsius,
    required this.humidityPercent,
    required this.pressureHpa,
    required this.windSpeedMetersPerSecond,
    required this.condition,
    required this.description,
    required this.observedAt,
  }) {
    if (humidityPercent < 0 || humidityPercent > 100) {
      throw ArgumentError.value(
        humidityPercent,
        'humidityPercent',
        'must be between 0 and 100',
      );
    }
    if (windSpeedMetersPerSecond < 0) {
      throw ArgumentError.value(
        windSpeedMetersPerSecond,
        'windSpeedMetersPerSecond',
        'must not be negative',
      );
    }
  }

  final double temperatureCelsius;
  final double feelsLikeCelsius;
  final int humidityPercent;
  final int pressureHpa;
  final double windSpeedMetersPerSecond;
  final WeatherCondition condition;
  final String description;
  final DateTime observedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrentWeather &&
        other.temperatureCelsius == temperatureCelsius &&
        other.feelsLikeCelsius == feelsLikeCelsius &&
        other.humidityPercent == humidityPercent &&
        other.pressureHpa == pressureHpa &&
        other.windSpeedMetersPerSecond == windSpeedMetersPerSecond &&
        other.condition == condition &&
        other.description == description &&
        other.observedAt == observedAt;
  }

  @override
  int get hashCode => Object.hash(
    temperatureCelsius,
    feelsLikeCelsius,
    humidityPercent,
    pressureHpa,
    windSpeedMetersPerSecond,
    condition,
    description,
    observedAt,
  );

  @override
  String toString() =>
      'CurrentWeather('
      'temperatureCelsius: $temperatureCelsius, '
      'condition: $condition, '
      'observedAt: $observedAt)';
}
