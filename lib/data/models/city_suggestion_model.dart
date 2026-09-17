import '../../domain/entities/city_suggestion.dart';

/// The wire representation of one entry in OpenWeatherMap's Geocoding
/// API response, decoded just enough to build a [CitySuggestion] domain
/// entity.
class CitySuggestionModel {
  CitySuggestionModel({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.state,
  });

  factory CitySuggestionModel.fromJson(Map<String, dynamic> json) {
    return CitySuggestionModel(
      name: json['name'] as String,
      state: json['state'] as String?,
      country: json['country'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
    );
  }

  final String name;
  final String? state;
  final String country;
  final double latitude;
  final double longitude;

  CitySuggestion toEntity() {
    return CitySuggestion(
      name: name,
      state: state,
      country: country,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CitySuggestionModel &&
        other.name == name &&
        other.state == state &&
        other.country == country &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(name, state, country, latitude, longitude);
}
