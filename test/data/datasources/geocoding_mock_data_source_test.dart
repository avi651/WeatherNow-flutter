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

    group('55 km haversine radius', () {
      // Degrees of latitude per km (1° of latitude ≈ 111.195 km).
      double kmToLat(double km) => km / 111.195;

      test('matches Sydney and Nairobi from nearby coordinates', () async {
        final sydney = await dataSource.reverseGeocode(
          latitude: -33.87,
          longitude: 151.2,
        );
        final nairobi = await dataSource.reverseGeocode(
          latitude: -1.29,
          longitude: 36.82,
        );

        expect(sydney.single['name'], 'Sydney');
        expect(nairobi.single['name'], 'Nairobi');
      });

      test('matches just inside 55 km and rejects just outside', () async {
        const london = (lat: 51.5072, lon: -0.1276);

        final inside = await dataSource.reverseGeocode(
          latitude: london.lat + kmToLat(54.0),
          longitude: london.lon,
        );
        final outside = await dataSource.reverseGeocode(
          latitude: london.lat + kmToLat(56.0),
          longitude: london.lon,
        );

        expect(inside.single['name'], 'London');
        expect(outside, isEmpty);
      });

      test('applies the same km radius east-west at high latitude '
          '(0.6° of longitude is only ~41 km at London)', () async {
        final result = await dataSource.reverseGeocode(
          latitude: 51.5072,
          longitude: -0.1276 + 0.6,
        );

        expect(result.single['name'], 'London');
      });

      test('rejects a point more than 55 km east of Sydney', () async {
        // 0.7° of longitude at 33.9°S is ~64 km.
        final result = await dataSource.reverseGeocode(
          latitude: -33.8688,
          longitude: 151.2093 + 0.7,
        );

        expect(result, isEmpty);
      });

      test('matches Auckland when its longitude is given past the '
          'antimeridian (-185.2355° == 174.7645°)', () async {
        final result = await dataSource.reverseGeocode(
          latitude: -36.85,
          longitude: -185.2355,
        );

        expect(result.single['name'], 'Auckland');
      });

      test('a point on the other side of the antimeridian, ~500 km from '
          'Auckland, is not matched', () async {
        final result = await dataSource.reverseGeocode(
          latitude: -36.8509,
          longitude: -179.9,
        );

        expect(result, isEmpty);
      });

      test('haversineKm wraps across the antimeridian', () {
        final km = GeocodingMockDataSource.haversineKm(0, 179.9, 0, -179.9);

        // 0.2° of longitude at the equator ≈ 22.2 km, not ~40,000 km.
        expect(km, closeTo(22.24, 0.1));
      });

      test('haversineKm is zero for identical points and ~111.2 km per '
          'degree of latitude', () {
        expect(GeocodingMockDataSource.haversineKm(10, 20, 10, 20), 0);
        expect(
          GeocodingMockDataSource.haversineKm(0, 0, 1, 0),
          closeTo(111.195, 0.01),
        );
      });
    });
  });
}
