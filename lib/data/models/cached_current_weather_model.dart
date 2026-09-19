import '../../domain/entities/cached_current_weather.dart';
import '../../domain/entities/current_weather.dart';
import '../../domain/entities/weather_condition.dart';

/// The local-storage JSON shape for a cached [CurrentWeather] — this
/// mirrors the domain entity's own fields directly rather than reusing
/// [CurrentWeatherModel]'s OpenWeatherMap wire format, since what's
/// persisted here has nothing to do with any particular weather provider.
class CachedCurrentWeatherModel {
  const CachedCurrentWeatherModel({
    required this.temperatureCelsius,
    required this.feelsLikeCelsius,
    required this.humidityPercent,
    required this.pressureHpa,
    required this.windSpeedMetersPerSecond,
    required this.condition,
    required this.description,
    required this.observedAtEpochMs,
    required this.fetchedAtEpochMs,
    this.cityName,
    this.country,
  });

  factory CachedCurrentWeatherModel.fromEntity({
    required CurrentWeather weather,
    required DateTime fetchedAt,
    String? cityName,
    String? country,
  }) {
    return CachedCurrentWeatherModel(
      temperatureCelsius: weather.temperatureCelsius,
      feelsLikeCelsius: weather.feelsLikeCelsius,
      humidityPercent: weather.humidityPercent,
      pressureHpa: weather.pressureHpa,
      windSpeedMetersPerSecond: weather.windSpeedMetersPerSecond,
      condition: weather.condition,
      description: weather.description,
      observedAtEpochMs: weather.observedAt.millisecondsSinceEpoch,
      fetchedAtEpochMs: fetchedAt.millisecondsSinceEpoch,
      cityName: cityName,
      country: country,
    );
  }

  factory CachedCurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    return CachedCurrentWeatherModel(
      temperatureCelsius: (json['temperatureCelsius'] as num).toDouble(),
      feelsLikeCelsius: (json['feelsLikeCelsius'] as num).toDouble(),
      humidityPercent: (json['humidityPercent'] as num).toInt(),
      pressureHpa: (json['pressureHpa'] as num).toInt(),
      windSpeedMetersPerSecond: (json['windSpeedMetersPerSecond'] as num)
          .toDouble(),
      condition: WeatherCondition.values.byName(json['condition'] as String),
      description: json['description'] as String,
      observedAtEpochMs: (json['observedAtEpochMs'] as num).toInt(),
      fetchedAtEpochMs: (json['fetchedAtEpochMs'] as num).toInt(),
      cityName: json['cityName'] as String?,
      country: json['country'] as String?,
    );
  }

  final double temperatureCelsius;
  final double feelsLikeCelsius;
  final int humidityPercent;
  final int pressureHpa;
  final double windSpeedMetersPerSecond;
  final WeatherCondition condition;
  final String description;
  final int observedAtEpochMs;
  final int fetchedAtEpochMs;
  final String? cityName;
  final String? country;

  Map<String, dynamic> toJson() {
    return {
      'temperatureCelsius': temperatureCelsius,
      'feelsLikeCelsius': feelsLikeCelsius,
      'humidityPercent': humidityPercent,
      'pressureHpa': pressureHpa,
      'windSpeedMetersPerSecond': windSpeedMetersPerSecond,
      'condition': condition.name,
      'description': description,
      'observedAtEpochMs': observedAtEpochMs,
      'fetchedAtEpochMs': fetchedAtEpochMs,
      'cityName': cityName,
      'country': country,
    };
  }

  CachedCurrentWeather toEntity() {
    return CachedCurrentWeather(
      cityName: cityName,
      country: country,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        fetchedAtEpochMs,
        isUtc: true,
      ),
      weather: CurrentWeather(
        temperatureCelsius: temperatureCelsius,
        feelsLikeCelsius: feelsLikeCelsius,
        humidityPercent: humidityPercent,
        pressureHpa: pressureHpa,
        windSpeedMetersPerSecond: windSpeedMetersPerSecond,
        condition: condition,
        description: description,
        observedAt: DateTime.fromMillisecondsSinceEpoch(
          observedAtEpochMs,
          isUtc: true,
        ),
      ),
    );
  }
}
