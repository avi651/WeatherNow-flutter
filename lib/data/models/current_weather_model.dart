import '../../domain/entities/current_weather.dart';
import '../../domain/entities/weather_condition.dart';
import 'weather_condition_mapper.dart';

/// The wire representation of OpenWeatherMap's current-weather endpoint,
/// decoded just enough to build a [CurrentWeather] domain entity.
///
/// Field access below intentionally uses direct casts rather than
/// defensive null-checks: a response missing `weather` or `main` is not a
/// usable current-weather response, so [fromJson] should throw and let the
/// repository translate that into a [Failure] — the exception is `wind`,
/// which OpenWeatherMap can genuinely omit for calm conditions.
class CurrentWeatherModel {
  CurrentWeatherModel({
    required this.temperatureCelsius,
    required this.feelsLikeCelsius,
    required this.humidityPercent,
    required this.pressureHpa,
    required this.windSpeedMetersPerSecond,
    required this.condition,
    required this.description,
    required this.observedAtEpochSeconds,
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather =
        (json['weather'] as List<dynamic>).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>?;

    return CurrentWeatherModel(
      temperatureCelsius: (main['temp'] as num).toDouble(),
      feelsLikeCelsius: (main['feels_like'] as num).toDouble(),
      humidityPercent: (main['humidity'] as num).toInt(),
      pressureHpa: (main['pressure'] as num).toInt(),
      windSpeedMetersPerSecond: ((wind?['speed'] as num?) ?? 0).toDouble(),
      condition: WeatherConditionMapper.fromOpenWeatherMain(
        weather['main'] as String,
      ),
      description: weather['description'] as String,
      observedAtEpochSeconds: (json['dt'] as num).toInt(),
    );
  }

  final double temperatureCelsius;
  final double feelsLikeCelsius;
  final int humidityPercent;
  final int pressureHpa;
  final double windSpeedMetersPerSecond;
  final WeatherCondition condition;
  final String description;
  final int observedAtEpochSeconds;

  CurrentWeather toEntity() {
    return CurrentWeather(
      temperatureCelsius: temperatureCelsius,
      feelsLikeCelsius: feelsLikeCelsius,
      humidityPercent: humidityPercent,
      pressureHpa: pressureHpa,
      windSpeedMetersPerSecond: windSpeedMetersPerSecond,
      condition: condition,
      description: description,
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        observedAtEpochSeconds * 1000,
        isUtc: true,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrentWeatherModel &&
        other.temperatureCelsius == temperatureCelsius &&
        other.feelsLikeCelsius == feelsLikeCelsius &&
        other.humidityPercent == humidityPercent &&
        other.pressureHpa == pressureHpa &&
        other.windSpeedMetersPerSecond == windSpeedMetersPerSecond &&
        other.condition == condition &&
        other.description == description &&
        other.observedAtEpochSeconds == observedAtEpochSeconds;
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
    observedAtEpochSeconds,
  );
}
