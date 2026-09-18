import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/error/cache_failures.dart';
import 'package:weather_now_flutter/data/datasources/favorites_local_data_source.dart';
import 'package:weather_now_flutter/data/repositories/favorites_repository_impl.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';

/// An in-memory stand-in for [FavoritesLocalDataSource] — keeps
/// [FavoritesRepositoryImpl]'s tests fast and independent of Hive, which
/// [HiveFavoritesDataSource] (tested separately) is responsible for.
class FakeFavoritesLocalDataSource implements FavoritesLocalDataSource {
  final Map<String, Map<String, dynamic>> store = {};

  /// When set, every method throws this instead of touching [store] —
  /// simulates a local-storage failure.
  Object? failWith;

  @override
  List<Map<String, dynamic>> getAll() {
    if (failWith != null) throw failWith!;
    return store.values.toList();
  }

  @override
  Future<void> put(String key, Map<String, dynamic> value) async {
    if (failWith != null) throw failWith!;
    store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failWith != null) throw failWith!;
    store.remove(key);
  }
}

void main() {
  late FakeFavoritesLocalDataSource dataSource;
  late FavoritesRepositoryImpl repository;

  const pune = CitySuggestion(
    name: 'Pune',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 18.5213738,
    longitude: 73.8545071,
  );

  const mumbai = CitySuggestion(
    name: 'Mumbai',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 19.0760,
    longitude: 72.8777,
  );

  setUp(() {
    dataSource = FakeFavoritesLocalDataSource();
    repository = FavoritesRepositoryImpl(localDataSource: dataSource);
  });

  test('getFavorites is empty when nothing has been saved', () async {
    final result = await repository.getFavorites();

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected Right'), (favorites) => expect(favorites, isEmpty));
  });

  test('addFavorite persists the city, then getFavorites returns it', () async {
    await repository.addFavorite(pune);

    final result = await repository.getFavorites();

    result.fold((_) => fail('expected Right'), (favorites) => expect(favorites, [pune]));
  });

  test('getFavorites returns saved cities sorted by name', () async {
    await repository.addFavorite(mumbai);
    await repository.addFavorite(pune);

    final result = await repository.getFavorites();

    result.fold(
      (_) => fail('expected Right'),
      (favorites) => expect(favorites, [mumbai, pune]),
    );
  });

  test('removeFavorite deletes a previously saved city', () async {
    await repository.addFavorite(pune);
    await repository.addFavorite(mumbai);

    await repository.removeFavorite(pune);

    final result = await repository.getFavorites();
    result.fold((_) => fail('expected Right'), (favorites) => expect(favorites, [mumbai]));
  });

  test(
    'a favorite persists across a new repository instance over the same '
    'data source — simulating surviving an app restart',
    () async {
      await repository.addFavorite(pune);

      final restarted = FavoritesRepositoryImpl(localDataSource: dataSource);
      final result = await restarted.getFavorites();

      result.fold((_) => fail('expected Right'), (favorites) => expect(favorites, [pune]));
    },
  );

  test('getFavorites returns a CacheFailure when the data source throws', () async {
    dataSource.failWith = Exception('disk error');

    final result = await repository.getFavorites();

    expect(result.isLeft(), isTrue);
    result.fold((failure) => expect(failure, isA<CacheFailure>()), (_) => fail('expected Left'));
  });

  test('addFavorite returns a CacheFailure when the data source throws', () async {
    dataSource.failWith = Exception('disk full');

    final result = await repository.addFavorite(pune);

    expect(result.isLeft(), isTrue);
    result.fold((failure) => expect(failure, isA<CacheFailure>()), (_) => fail('expected Left'));
  });

  test('removeFavorite returns a CacheFailure when the data source throws', () async {
    await repository.addFavorite(pune);
    dataSource.failWith = Exception('disk full');

    final result = await repository.removeFavorite(pune);

    expect(result.isLeft(), isTrue);
    result.fold((failure) => expect(failure, isA<CacheFailure>()), (_) => fail('expected Left'));
  });
}
