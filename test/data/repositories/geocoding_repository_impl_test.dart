import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/geocoding_api_exception.dart';
import 'package:weather_now_flutter/data/datasources/geocoding_data_source.dart';
import 'package:weather_now_flutter/data/repositories/geocoding_repository_impl.dart';

class MockGeocodingDataSource extends Mock implements GeocodingDataSource {}

void main() {
  late MockGeocodingDataSource mockDataSource;
  late GeocodingRepositoryImpl repository;

  const query = 'London';

  setUp(() {
    mockDataSource = MockGeocodingDataSource();
    repository = GeocodingRepositoryImpl(dataSource: mockDataSource);
  });

  List<Map<String, dynamic>> resultsJson() => [
    {
      'name': 'London',
      'country': 'GB',
      'state': 'England',
      'lat': 51.5,
      'lon': -0.12,
    },
  ];

  group('GeocodingRepositoryImpl.searchCities', () {
    test('returns mapped CitySuggestions on success', () async {
      when(
        () => mockDataSource.searchCities(query: query),
      ).thenAnswer((_) async => resultsJson());

      final result = await repository.searchCities(query: query);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (cities) {
        expect(cities, hasLength(1));
        expect(cities.single.name, 'London');
        expect(cities.single.country, 'GB');
        expect(cities.single.state, 'England');
      });
    });

    test(
      'returns a RemoteDataFailure carrying the status code when the data source throws',
      () async {
        when(
          () => mockDataSource.searchCities(query: query),
        ).thenThrow(GeocodingApiException('Unauthorized', statusCode: 401));

        final result = await repository.searchCities(query: query);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<RemoteDataFailure>());
          expect(failure.message, 'Unauthorized');
          expect((failure as RemoteDataFailure).statusCode, 401);
        }, (_) => fail('expected Left'));
      },
    );

    test(
      'returns a DataParsingFailure when the response is malformed',
      () async {
        when(() => mockDataSource.searchCities(query: query)).thenAnswer(
          (_) async => [
            {'unexpected': 'shape'},
          ],
        );

        final result = await repository.searchCities(query: query);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<DataParsingFailure>()),
          (_) => fail('expected Left'),
        );
      },
    );

    test('returns an empty list on success with no matches', () async {
      when(
        () => mockDataSource.searchCities(query: query),
      ).thenAnswer((_) async => []);

      final result = await repository.searchCities(query: query);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (cities) => expect(cities, isEmpty),
      );
    });

    test(
      'maps a real multi-result geocoding response (captured for "Pune")',
      () async {
        // Verbatim shape of
        // https://api.openweathermap.org/geo/1.0/direct?q=Pune&limit=5 —
        // several same-named cities across countries, one with a
        // `local_names` map and lowercase "pune" entry.
        when(() => mockDataSource.searchCities(query: 'Pune')).thenAnswer(
          (_) async => [
            {
              'name': 'Pune',
              'local_names': {'en': 'Pune', 'hi': 'पुणे'},
              'lat': 18.5213738,
              'lon': 73.8545071,
              'country': 'IN',
              'state': 'Maharashtra',
            },
            {
              'name': 'pune',
              'lat': 16.7541259,
              'lon': 74.6513915,
              'country': 'IN',
              'state': 'Maharashtra',
            },
            {
              'name': 'Pune',
              'lat': 1.7837578,
              'lon': 127.8542945,
              'country': 'ID',
              'state': 'North Maluku',
            },
            {
              'name': 'Pune',
              'lat': -9.36924,
              'lon': 124.31618,
              'country': 'TL',
              'state': 'Oecussi-Ambeno',
            },
          ],
        );

        final result = await repository.searchCities(query: 'Pune');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('expected Right'), (cities) {
          expect(cities, hasLength(4));
          expect(cities.first.name, 'Pune');
          expect(cities.first.state, 'Maharashtra');
          expect(cities.first.country, 'IN');
          expect(cities.first.latitude, 18.5213738);
          expect(cities.first.longitude, 73.8545071);
        });
      },
    );
  });

  group('GeocodingRepositoryImpl.reverseGeocode', () {
    const latitude = 18.5213738;
    const longitude = 73.8545071;

    test('returns the mapped CitySuggestion on success', () async {
      when(
        () => mockDataSource.reverseGeocode(
          latitude: latitude,
          longitude: longitude,
        ),
      ).thenAnswer(
        (_) async => [
          {
            'name': 'Pune',
            'country': 'IN',
            'state': 'Maharashtra',
            'lat': latitude,
            'lon': longitude,
          },
        ],
      );

      final result = await repository.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (city) {
        expect(city.name, 'Pune');
        expect(city.country, 'IN');
      });
    });

    test('returns a RemoteDataFailure when nothing is found', () async {
      when(
        () => mockDataSource.reverseGeocode(
          latitude: latitude,
          longitude: longitude,
        ),
      ).thenAnswer((_) async => []);

      final result = await repository.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<RemoteDataFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test(
      'returns a RemoteDataFailure carrying the status code when the data source throws',
      () async {
        when(
          () => mockDataSource.reverseGeocode(
            latitude: latitude,
            longitude: longitude,
          ),
        ).thenThrow(GeocodingApiException('Unauthorized', statusCode: 401));

        final result = await repository.reverseGeocode(
          latitude: latitude,
          longitude: longitude,
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<RemoteDataFailure>());
          expect((failure as RemoteDataFailure).statusCode, 401);
        }, (_) => fail('expected Left'));
      },
    );

    test(
      'returns a DataParsingFailure when the response is malformed',
      () async {
        when(
          () => mockDataSource.reverseGeocode(
            latitude: latitude,
            longitude: longitude,
          ),
        ).thenAnswer(
          (_) async => [
            {'unexpected': 'shape'},
          ],
        );

        final result = await repository.reverseGeocode(
          latitude: latitude,
          longitude: longitude,
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<DataParsingFailure>()),
          (_) => fail('expected Left'),
        );
      },
    );
  });
}
