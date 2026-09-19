import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/data/models/city_suggestion_model.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';

void main() {
  Map<String, dynamic> json({String? state}) {
    final map = <String, dynamic>{
      'name': 'Mumbai',
      'country': 'IN',
      'lat': 19.0760,
      'lon': 72.8777,
    };
    if (state != null) map['state'] = state;
    return map;
  }

  group('CitySuggestionModel.fromJson', () {
    test('parses all fields from a well-formed response', () {
      final model = CitySuggestionModel.fromJson(json(state: 'Maharashtra'));

      expect(model.name, 'Mumbai');
      expect(model.state, 'Maharashtra');
      expect(model.country, 'IN');
      expect(model.latitude, 19.0760);
      expect(model.longitude, 72.8777);
    });

    test('defaults state to null when absent', () {
      final model = CitySuggestionModel.fromJson(json());

      expect(model.state, isNull);
    });

    test('accepts integer coordinates (no decimal point)', () {
      final model = CitySuggestionModel.fromJson({
        'name': 'Null Island',
        'country': 'XX',
        'lat': 0,
        'lon': 0,
      });

      expect(model.latitude, 0.0);
      expect(model.longitude, 0.0);
    });

    test('ignores extra fields the real API sends, like local_names', () {
      // A real (trimmed) response from
      // https://api.openweathermap.org/geo/1.0/direct?q=Pune — regression
      // check that the `local_names` map (present for most real cities,
      // absent from our other fixtures) doesn't trip up parsing.
      final model = CitySuggestionModel.fromJson({
        'name': 'Pune',
        'local_names': {'en': 'Pune', 'hi': 'पुणे', 'mr': 'पुणे शहर'},
        'lat': 18.5213738,
        'lon': 73.8545071,
        'country': 'IN',
        'state': 'Maharashtra',
      });

      expect(model.name, 'Pune');
      expect(model.state, 'Maharashtra');
      expect(model.country, 'IN');
      expect(model.latitude, 18.5213738);
      expect(model.longitude, 73.8545071);
    });
  });

  test('CitySuggestionModel.toEntity maps every field across', () {
    final entity = CitySuggestionModel.fromJson(
      json(state: 'Maharashtra'),
    ).toEntity();

    expect(entity.name, 'Mumbai');
    expect(entity.state, 'Maharashtra');
    expect(entity.country, 'IN');
    expect(entity.latitude, 19.0760);
    expect(entity.longitude, 72.8777);
  });

  test('two models parsed from identical JSON are equal', () {
    final a = CitySuggestionModel.fromJson(json(state: 'Maharashtra'));
    final b = CitySuggestionModel.fromJson(json(state: 'Maharashtra'));

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('models parsed from different JSON are not equal', () {
    final a = CitySuggestionModel.fromJson(json(state: 'Maharashtra'));
    final b = CitySuggestionModel.fromJson({
      'name': 'Delhi',
      'state': 'Delhi',
      'country': 'IN',
      'lat': 28.7041,
      'lon': 77.1025,
    });

    expect(a, isNot(b));
  });

  test('fromEntity -> toJson -> fromJson round-trips a favorited city', () {
    const city = CitySuggestion(
      name: 'Pune',
      state: 'Maharashtra',
      country: 'IN',
      latitude: 18.5213738,
      longitude: 73.8545071,
    );

    final restored = CitySuggestionModel.fromJson(
      CitySuggestionModel.fromEntity(city).toJson(),
    ).toEntity();

    expect(restored, city);
  });

  test('fromEntity round-trips a city with no state', () {
    const city = CitySuggestion(
      name: 'Singapore',
      country: 'SG',
      latitude: 1.3521,
      longitude: 103.8198,
    );

    final restored = CitySuggestionModel.fromJson(
      CitySuggestionModel.fromEntity(city).toJson(),
    ).toEntity();

    expect(restored, city);
  });
}
