import 'weather_condition.dart';

/// A single forecast slot (OpenWeatherMap's free forecast API steps in
/// 3-hour increments, but this entity doesn't hardcode that interval —
/// it just represents "the forecast for a given point in time").
class ForecastEntry {
  ForecastEntry({
    required this.forecastFor,
    required this.temperatureCelsius,
    required this.feelsLikeCelsius,
    required this.humidityPercent,
    required this.condition,
    required this.description,
    required this.precipitationProbability,
  }) {
    if (humidityPercent < 0 || humidityPercent > 100) {
      throw ArgumentError.value(
        humidityPercent,
        'humidityPercent',
        'must be between 0 and 100',
      );
    }
    if (precipitationProbability < 0 || precipitationProbability > 1) {
      throw ArgumentError.value(
        precipitationProbability,
        'precipitationProbability',
        'must be between 0.0 and 1.0',
      );
    }
  }

  final DateTime forecastFor;
  final double temperatureCelsius;
  final double feelsLikeCelsius;
  final int humidityPercent;
  final WeatherCondition condition;
  final String description;

  /// Probability of precipitation, expressed as a fraction between
  /// 0.0 (no chance) and 1.0 (certain).
  final double precipitationProbability;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForecastEntry &&
        other.forecastFor == forecastFor &&
        other.temperatureCelsius == temperatureCelsius &&
        other.feelsLikeCelsius == feelsLikeCelsius &&
        other.humidityPercent == humidityPercent &&
        other.condition == condition &&
        other.description == description &&
        other.precipitationProbability == precipitationProbability;
  }

  @override
  int get hashCode => Object.hash(
    forecastFor,
    temperatureCelsius,
    feelsLikeCelsius,
    humidityPercent,
    condition,
    description,
    precipitationProbability,
  );

  @override
  String toString() =>
      'ForecastEntry('
      'forecastFor: $forecastFor, '
      'temperatureCelsius: $temperatureCelsius, '
      'condition: $condition)';
}
