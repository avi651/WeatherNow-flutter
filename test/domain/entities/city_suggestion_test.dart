import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';

void main() {
  const suggestion = CitySuggestion(
    name: 'Mumbai',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 19.0760,
    longitude: 72.8777,
  );

  test('exposes the values it was built with', () {
    expect(suggestion.name, 'Mumbai');
    expect(suggestion.state, 'Maharashtra');
    expect(suggestion.country, 'IN');
    expect(suggestion.latitude, 19.0760);
    expect(suggestion.longitude, 72.8777);
  });

  group('displayLabel', () {
    test('joins name, state, and country when state is present', () {
      expect(suggestion.displayLabel, 'Mumbai, Maharashtra, IN');
    });

    test('omits state when it is null', () {
      const noState = CitySuggestion(
        name: 'Singapore',
        state: null,
        country: 'SG',
        latitude: 1.3521,
        longitude: 103.8198,
      );

      expect(noState.displayLabel, 'Singapore, SG');
    });

    test('omits state when it is empty', () {
      const emptyState = CitySuggestion(
        name: 'Singapore',
        state: '',
        country: 'SG',
        latitude: 1.3521,
        longitude: 103.8198,
      );

      expect(emptyState.displayLabel, 'Singapore, SG');
    });
  });

  test('two instances with identical values are equal', () {
    const other = CitySuggestion(
      name: 'Mumbai',
      state: 'Maharashtra',
      country: 'IN',
      latitude: 19.0760,
      longitude: 72.8777,
    );

    expect(suggestion, other);
    expect(suggestion.hashCode, other.hashCode);
  });

  test('two instances with different values are not equal', () {
    const other = CitySuggestion(
      name: 'Delhi',
      state: 'Delhi',
      country: 'IN',
      latitude: 28.7041,
      longitude: 77.1025,
    );

    expect(suggestion, isNot(other));
  });
}
