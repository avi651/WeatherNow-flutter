import '../../domain/entities/cached_forecast.dart';
import '../../domain/entities/forecast.dart';
import '../../domain/entities/forecast_entry.dart';
import '../../domain/entities/weather_condition.dart';

/// The local-storage JSON shape for a single cached [ForecastEntry] —
/// mirrors the domain entity's own fields directly, independent of any
/// wire format.
class CachedForecastEntryModel {
  const CachedForecastEntryModel({
    required this.forecastForEpochMs,
    required this.temperatureCelsius,
    required this.feelsLikeCelsius,
    required this.humidityPercent,
    required this.condition,
    required this.description,
    required this.precipitationProbability,
  });

  factory CachedForecastEntryModel.fromEntity(ForecastEntry entry) {
    return CachedForecastEntryModel(
      forecastForEpochMs: entry.forecastFor.millisecondsSinceEpoch,
      temperatureCelsius: entry.temperatureCelsius,
      feelsLikeCelsius: entry.feelsLikeCelsius,
      humidityPercent: entry.humidityPercent,
      condition: entry.condition,
      description: entry.description,
      precipitationProbability: entry.precipitationProbability,
    );
  }

  factory CachedForecastEntryModel.fromJson(Map<String, dynamic> json) {
    return CachedForecastEntryModel(
      forecastForEpochMs: (json['forecastForEpochMs'] as num).toInt(),
      temperatureCelsius: (json['temperatureCelsius'] as num).toDouble(),
      feelsLikeCelsius: (json['feelsLikeCelsius'] as num).toDouble(),
      humidityPercent: (json['humidityPercent'] as num).toInt(),
      condition: WeatherCondition.values.byName(json['condition'] as String),
      description: json['description'] as String,
      precipitationProbability: (json['precipitationProbability'] as num)
          .toDouble(),
    );
  }

  final int forecastForEpochMs;
  final double temperatureCelsius;
  final double feelsLikeCelsius;
  final int humidityPercent;
  final WeatherCondition condition;
  final String description;
  final double precipitationProbability;

  Map<String, dynamic> toJson() {
    return {
      'forecastForEpochMs': forecastForEpochMs,
      'temperatureCelsius': temperatureCelsius,
      'feelsLikeCelsius': feelsLikeCelsius,
      'humidityPercent': humidityPercent,
      'condition': condition.name,
      'description': description,
      'precipitationProbability': precipitationProbability,
    };
  }

  ForecastEntry toEntity() {
    return ForecastEntry(
      forecastFor: DateTime.fromMillisecondsSinceEpoch(
        forecastForEpochMs,
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
}

/// The local-storage JSON shape for a cached [Forecast].
class CachedForecastModel {
  const CachedForecastModel({
    required this.entries,
    required this.fetchedAtEpochMs,
    this.cityName,
    this.country,
  });

  factory CachedForecastModel.fromEntity({
    required Forecast forecast,
    required DateTime fetchedAt,
    String? cityName,
    String? country,
  }) {
    return CachedForecastModel(
      entries: forecast.entries
          .map(CachedForecastEntryModel.fromEntity)
          .toList(),
      fetchedAtEpochMs: fetchedAt.millisecondsSinceEpoch,
      cityName: cityName,
      country: country,
    );
  }

  factory CachedForecastModel.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>;

    return CachedForecastModel(
      entries: rawEntries
          .map(
            (entry) => CachedForecastEntryModel.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      fetchedAtEpochMs: (json['fetchedAtEpochMs'] as num).toInt(),
      cityName: json['cityName'] as String?,
      country: json['country'] as String?,
    );
  }

  final List<CachedForecastEntryModel> entries;
  final int fetchedAtEpochMs;
  final String? cityName;
  final String? country;

  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'fetchedAtEpochMs': fetchedAtEpochMs,
      'cityName': cityName,
      'country': country,
    };
  }

  CachedForecast toEntity() {
    return CachedForecast(
      cityName: cityName,
      country: country,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(fetchedAtEpochMs, isUtc: true),
      forecast: Forecast(
        entries: entries.map((entry) => entry.toEntity()).toList(),
      ),
    );
  }
}
