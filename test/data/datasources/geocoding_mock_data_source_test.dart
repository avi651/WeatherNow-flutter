import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/data/datasources/geocoding_mock_data_source.dart';

void main() {
  const dataSource = GeocodingMockDataSource();

  group('GeocodingMockDataSource.searchCities', () {
    test(
      'returns cities whose name starts with the query, case-insensitively',
      () async {
        final result = await dataSource.searchCities(query: 'lon');

        expect(result, isNotEmpty);
        expect(
          result.every(
            (city) => (city['name'] as String).toLowerCase().startsWith('lon'),
          ),
          isTrue,
        );
      },
    );

    test('returns entries shaped like the real geocoding API', () async {
      final result = await dataSource.searchCities(query: 'Mumbai');

      expect(result, isNotEmpty);
      final first = result.first;
      expect(first['name'], isA<String>());
      expect(first['country'], isA<String>());
      expect(first['lat'], isA<num>());
      expect(first['lon'], isA<num>());
    });

    test('returns an empty list when nothing matches', () async {
      final result = await dataSource.searchCities(query: 'Zzzznotacity');

      expect(result, isEmpty);
    });

    test('returns an empty list for a blank query', () async {
      final result = await dataSource.searchCities(query: '   ');

      expect(result, isEmpty);
    });

    test(
      'covers a broad set of major world cities, not just a handful',
      () async {
        // Regression check for a real gap: the bundled list used to be a
        // dozen-odd cities, so anything outside it (e.g. "Pune") showed
        // "No cities found" in mock mode even though it's a real, well-known
        // city. Each of these should resolve to at least one match.
        const expectedCities = [
          'Pune',
          'Hyderabad',
          'Chennai',
          'Kolkata',
          'Ahmedabad',
          'Jaipur',
          'Lucknow',
          'Chicago',
          'Madrid',
          'Rome',
          'Amsterdam',
          'Seoul',
          'Bangkok',
          'Cairo',
          'Moscow',
          'Mexico City',
        ];

        for (final city in expectedCities) {
          final result = await dataSource.searchCities(query: city);
          expect(result, isNotEmpty, reason: 'Expected a match for "$city"');
        }
      },
    );
  });

  group('GeocodingMockDataSource.reverseGeocode', () {
    test('returns the bundled city nearest to the given coordinates', () async {
      // Close to, but not exactly, Pune's bundled coordinates.
      final result = await dataSource.reverseGeocode(
        latitude: 18.52,
        longitude: 73.85,
      );

      expect(result, hasLength(1));
      expect(result.single['name'], 'Pune');
      expect(result.single['country'], 'IN');
    });

    test(
      'returns a different nearest city for different coordinates',
      () async {
        final result = await dataSource.reverseGeocode(
          latitude: 51.5072,
          longitude: -0.1276,
        );

        expect(result.single['name'], 'London');
      },
    );

    test('returns entries shaped like the real geocoding API', () async {
      final result = await dataSource.reverseGeocode(
        latitude: 18.52,
        longitude: 73.85,
      );

      final first = result.single;
      expect(first['name'], isA<String>());
      expect(first['country'], isA<String>());
      expect(first['lat'], isA<num>());
      expect(first['lon'], isA<num>());
    });

    test(
      'returns nothing for coordinates far from every bundled city, '
      'instead of the least-far one (never Delhi for the mid-Pacific)',
      () async {
        final result = await dataSource.reverseGeocode(
          latitude: 0.0,
          longitude: -140.0,
        );

        expect(result, isEmpty);
      },
    );
  });
}
