import '../../domain/entities/forecast_entry.dart';
import '../../domain/entities/weather_condition.dart';

enum DayPeriod {
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening');

  const DayPeriod(this.label);

  final String label;

  /// Maps an hour of day (0-23) to its period, or null for overnight hours
  /// (22:00-04:59) which the detail view doesn't show.
  static DayPeriod? fromHour(int hour) {
    if (hour >= 5 && hour <= 11) return morning;
    if (hour >= 12 && hour <= 16) return afternoon;
    if (hour >= 17 && hour <= 21) return evening;
    return null;
  }
}

/// The 3-hour entries falling in one [DayPeriod], summarized.
class DayPeriodForecast {
  const DayPeriodForecast({
    required this.period,
    required this.entries,
    required this.minTemperatureCelsius,
    required this.maxTemperatureCelsius,
    required this.averageFeelsLikeCelsius,
    required this.averageHumidityPercent,
    required this.maxPrecipitationProbability,
    required this.condition,
    required this.description,
  });

  final DayPeriod period;
  final List<ForecastEntry> entries;
  final double minTemperatureCelsius;
  final double maxTemperatureCelsius;
  final double averageFeelsLikeCelsius;
  final int averageHumidityPercent;
  final double maxPrecipitationProbability;
  final WeatherCondition condition;
  final String description;
}

/// Groups a single day's 3-hour entries into morning / afternoon / evening.
/// Hours are read the same way `DailyForecastAggregator` reads them, so the
/// two stay consistent. Periods with no entries are omitted.
class DayPeriodGrouper {
  const DayPeriodGrouper._();

  static List<DayPeriodForecast> group(List<ForecastEntry> entries) {
    final byPeriod = <DayPeriod, List<ForecastEntry>>{};
    for (final entry in entries) {
      final period = DayPeriod.fromHour(entry.forecastFor.hour);
      if (period == null) continue;
      byPeriod.putIfAbsent(period, () => []).add(entry);
    }

    return [
      for (final period in DayPeriod.values)
        if (byPeriod[period] case final list?) _summarize(period, list),
    ];
  }

  static DayPeriodForecast _summarize(
    DayPeriod period,
    List<ForecastEntry> entries,
  ) {
    final sorted = [...entries]
      ..sort((a, b) => a.forecastFor.compareTo(b.forecastFor));
    final temps = sorted.map((e) => e.temperatureCelsius);
    final representative = sorted[sorted.length ~/ 2];

    return DayPeriodForecast(
      period: period,
      entries: List.unmodifiable(sorted),
      minTemperatureCelsius: temps.reduce((a, b) => a < b ? a : b),
      maxTemperatureCelsius: temps.reduce((a, b) => a > b ? a : b),
      averageFeelsLikeCelsius:
          sorted.fold(0.0, (sum, e) => sum + e.feelsLikeCelsius) /
          sorted.length,
      averageHumidityPercent:
          (sorted.fold(0, (sum, e) => sum + e.humidityPercent) / sorted.length)
              .round(),
      maxPrecipitationProbability: sorted
          .map((e) => e.precipitationProbability)
          .reduce((a, b) => a > b ? a : b),
      condition: representative.condition,
      description: representative.description,
    );
  }
}
