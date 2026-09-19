import '../../domain/entities/forecast_entry.dart';
import '../../domain/entities/weather_condition.dart';
import 'weather_condition_mapper.dart';

/// The wire representation of a single entry in OpenWeatherMap's
/// 5-day/3-hour forecast `list`, decoded just enough to build a
/// [ForecastEntry] domain entity.
class ForecastEntryModel {
  ForecastEntryModel({
    required this.forecastForEpochSeconds,
    required this.temperatureCelsius,
    required this.feelsLikeCelsius,
    required this.humidityPercent,
    required this.condition,
    required this.description,
    required this.precipitationProbability,
  });

  factory ForecastEntryModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather =
        (json['weather'] as List<dynamic>).first as Map<String, dynamic>;

    return ForecastEntryModel(
      forecastForEpochSeconds: (json['dt'] as num).toInt(),
      temperatureCelsius: (main['temp'] as num).toDouble(),
      feelsLikeCelsius: (main['feels_like'] as num).toDouble(),
      humidityPercent: (main['humidity'] as num).toInt(),
      condition: WeatherConditionMapper.fromOpenWeatherMain(
        weather['main'] as String,
      ),
      description: weather['description'] as String,
      // OpenWeatherMap omits `pop` for some historical forecast entries;
      // treat that as "no data" rather than failing the whole response.
      precipitationProbability: ((json['pop'] as num?) ?? 0).toDouble(),
    );
  }

  final int forecastForEpochSeconds;
  final double temperatureCelsius;
  final double feelsLikeCelsius;
  final int humidityPercent;
  final WeatherCondition condition;
  final String description;
  final double precipitationProbability;

  ForecastEntry toEntity() {
    return ForecastEntry(
      forecastFor: DateTime.fromMillisecondsSinceEpoch(
        forecastForEpochSeconds * 1000,
        isUtc: true,
      ),
      temperatureCelsius: temperatureCelsius,
      feelsLikeCelsius: feelsLikeCelsius,
      humidityPercent: humidityPercent,
      condition: condition,
      description: description,
      precipitationProbability: precipitationProbability,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForecastEntryModel &&
        other.forecastForEpochSeconds == forecastForEpochSeconds &&
        other.temperatureCelsius == temperatureCelsius &&
        other.feelsLikeCelsius == feelsLikeCelsius &&
        other.humidityPercent == humidityPercent &&
        other.condition == condition &&
        other.description == description &&
        other.precipitationProbability == precipitationProbability;
  }

  @override
  int get hashCode => Object.hash(
    forecastForEpochSeconds,
    temperatureCelsius,
    feelsLikeCelsius,
    humidityPercent,
    condition,
    description,
    precipitationProbability,
  );
}
