import '../../domain/entities/forecast.dart';
import 'forecast_entry_model.dart';

/// The wire representation of OpenWeatherMap's 5-day/3-hour forecast
/// response, decoded just enough to build a [Forecast] domain entity.
class ForecastModel {
  ForecastModel({required List<ForecastEntryModel> entries})
      : entries = List.unmodifiable(entries);

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List<dynamic>;

    return ForecastModel(
      entries: list
          .map((entry) => ForecastEntryModel.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<ForecastEntryModel> entries;

  Forecast toEntity() {
    return Forecast(entries: entries.map((entry) => entry.toEntity()).toList());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ForecastModel) return false;
    if (other.entries.length != entries.length) return false;
    for (var i = 0; i < entries.length; i++) {
      if (other.entries[i] != entries[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(entries);
}
