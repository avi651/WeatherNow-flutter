import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/failures.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/repositories/geocoding_repository.dart';
import 'package:weather_now_flutter/presentation/providers/city_search_provider.dart';

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

void main() {
  late MockGeocodingRepository mockRepository;

  const results = [
    CitySuggestion(
      name: 'London',
      state: 'England',
      country: 'GB',
      latitude: 51.5072,
      longitude: -0.1276,
    ),
  ];

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [geocodingRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    mockRepository = MockGeocodingRepository();
  });

  test('initial state is empty, not loading, no error', () {
    final container = buildContainer();

    final state = container.read(citySearchProvider);

    expect(state.query, '');
    expect(state.results, isEmpty);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
    expect(state.hasQuery, isFalse);
    expect(state.isEmptyResult, isFalse);
  });

  test('search populates results on success', () async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right(results));

    final container = buildContainer();
    await container.read(citySearchProvider.notifier).search('Lon');

    final state = container.read(citySearchProvider);
    expect(state.results, results);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
    expect(state.query, 'Lon');
  });

  test('search sets an error message on failure', () async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Left(RemoteDataFailure('No connection')));

    final container = buildContainer();
    await container.read(citySearchProvider.notifier).search('Lon');

    final state = container.read(citySearchProvider);
    expect(state.errorMessage, 'No connection');
    expect(state.results, isEmpty);
    expect(state.isLoading, isFalse);
  });

  test('isEmptyResult is true after a successful search with no matches', () async {
    when(
      () => mockRepository.searchCities(query: 'Zzz'),
    ).thenAnswer((_) async => const Right([]));

    final container = buildContainer();
    await container.read(citySearchProvider.notifier).search('Zzz');

    expect(container.read(citySearchProvider).isEmptyResult, isTrue);
  });

  test('search with a blank query resets to the initial state', () async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right(results));

    final container = buildContainer();
    await container.read(citySearchProvider.notifier).search('Lon');
    expect(container.read(citySearchProvider).results, isNotEmpty);

    await container.read(citySearchProvider.notifier).search('   ');

    final state = container.read(citySearchProvider);
    expect(state.query, '');
    expect(state.results, isEmpty);
    expect(state.hasQuery, isFalse);
  });

  test('clear resets to the initial state', () async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right(results));

    final container = buildContainer();
    await container.read(citySearchProvider.notifier).search('Lon');

    container.read(citySearchProvider.notifier).clear();

    final state = container.read(citySearchProvider);
    expect(state.query, '');
    expect(state.results, isEmpty);
  });

  test('discards a stale response superseded by a newer search', () async {
    final firstCompleter = Completer<Either<Failure, List<CitySuggestion>>>();
    final secondCompleter = Completer<Either<Failure, List<CitySuggestion>>>();

    when(
      () => mockRepository.searchCities(query: 'L'),
    ).thenAnswer((_) => firstCompleter.future);
    when(
      () => mockRepository.searchCities(query: 'Lo'),
    ).thenAnswer((_) => secondCompleter.future);

    final container = buildContainer();
    final notifier = container.read(citySearchProvider.notifier);

    final firstSearch = notifier.search('L');
    final secondSearch = notifier.search('Lo');

    // The newer search ('Lo') resolves first...
    secondCompleter.complete(const Right(results));
    await secondSearch;

    // ...then the stale one ('L') resolves after it, and must not
    // overwrite the newer, already-applied results.
    firstCompleter.complete(const Right([]));
    await firstSearch;

    expect(container.read(citySearchProvider).results, results);
  });
}
