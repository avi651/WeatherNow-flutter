import 'forecast_entry.dart';

/// An ordered collection of forecast slots for a location.
class Forecast {
  Forecast({required List<ForecastEntry> entries})
      : entries = List.unmodifiable(entries);

  final List<ForecastEntry> entries;

  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Forecast) return false;
    if (other.entries.length != entries.length) return false;
    for (var i = 0; i < entries.length; i++) {
      if (other.entries[i] != entries[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(entries);

  @override
  String toString() => 'Forecast(entries: ${entries.length})';
}
