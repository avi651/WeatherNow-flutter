import '../../domain/entities/forecast_entry.dart';
import '../../domain/entities/weather_condition.dart';

/// A day's worth of forecast, summarized from several 3-hour entries.
class DailyForecastSummary {
  const DailyForecastSummary({
    required this.date,
    required this.minTemperatureCelsius,
    required this.maxTemperatureCelsius,
    required this.condition,
    this.entries = const [],
  });

  /// Midnight UTC of the day this summary covers.
  final DateTime date;
  final double minTemperatureCelsius;
  final double maxTemperatureCelsius;
  final WeatherCondition condition;

  /// The 3-hour entries this summary was built from, kept so a detail
  /// view can break the day down without refetching.
  final List<ForecastEntry> entries;
}

/// Groups OpenWeatherMap's 3-hour forecast entries into daily summaries.
///
/// This is presentation-layer view logic, not a domain concern: the
/// domain only knows about individual forecast slots, not "a day's
/// weather" as a concept.
class DailyForecastAggregator {
  const DailyForecastAggregator._();

  static List<DailyForecastSummary> aggregate(List<ForecastEntry> entries) {
    final byDay = <DateTime, List<ForecastEntry>>{};

    for (final entry in entries) {
      final day = DateTime.utc(
        entry.forecastFor.year,
        entry.forecastFor.month,
        entry.forecastFor.day,
      );
      byDay.putIfAbsent(day, () => []).add(entry);
    }

    final sortedDays = byDay.keys.toList()..sort();

    return sortedDays.map((day) {
      final dayEntries = byDay[day]!;
      final temperatures = dayEntries.map((e) => e.temperatureCelsius);

      final representative = dayEntries.reduce((a, b) {
        final aDistanceFromNoon = (a.forecastFor.hour - 12).abs();
        final bDistanceFromNoon = (b.forecastFor.hour - 12).abs();
        return aDistanceFromNoon <= bDistanceFromNoon ? a : b;
      });

      return DailyForecastSummary(
        date: day,
        minTemperatureCelsius: temperatures.reduce((a, b) => a < b ? a : b),
        maxTemperatureCelsius: temperatures.reduce((a, b) => a > b ? a : b),
        condition: representative.condition,
        entries: List.unmodifiable(dayEntries),
      );
    }).toList();
  }
}
