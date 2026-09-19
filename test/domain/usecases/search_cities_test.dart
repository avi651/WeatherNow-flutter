import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/failures.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/repositories/geocoding_repository.dart';
import 'package:weather_now_flutter/domain/usecases/search_cities.dart';

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

void main() {
  late MockGeocodingRepository mockRepository;
  late SearchCities useCase;

  const results = [
    CitySuggestion(
      name: 'London',
      state: 'England',
      country: 'GB',
      latitude: 51.5072,
      longitude: -0.1276,
    ),
  ];

  setUp(() {
    mockRepository = MockGeocodingRepository();
    useCase = SearchCities(mockRepository);
  });

  test('returns the suggestions from the repository on success', () async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right(results));

    final result = await useCase(query: 'Lon');

    expect(result, const Right<Failure, List<CitySuggestion>>(results));
    verify(() => mockRepository.searchCities(query: 'Lon')).called(1);
  });

  test('returns the Failure from the repository on error', () async {
    const failure = RemoteDataFailure('No connection');
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(query: 'Lon');

    expect(result, const Left<Failure, List<CitySuggestion>>(failure));
  });

  test('trims the query before delegating to the repository', () async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right(results));

    await useCase(query: '  Lon  ');

    verify(() => mockRepository.searchCities(query: 'Lon')).called(1);
  });

  test(
    'returns an empty list without calling the repository for a blank query',
    () async {
      final result = await useCase(query: '   ');

      expect(result, const Right<Failure, List<CitySuggestion>>([]));
      verifyNever(
        () => mockRepository.searchCities(query: any(named: 'query')),
      );
    },
  );
}
