import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/cache_failures.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/repositories/favorites_repository.dart';
import 'package:weather_now_flutter/domain/usecases/add_favorite.dart';
import 'package:weather_now_flutter/domain/usecases/get_favorites.dart';
import 'package:weather_now_flutter/domain/usecases/remove_favorite.dart';

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

void main() {
  late MockFavoritesRepository mockRepository;

  const pune = CitySuggestion(
    name: 'Pune',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 18.5213738,
    longitude: 73.8545071,
  );

  setUpAll(() {
    registerFallbackValue(pune);
  });

  setUp(() {
    mockRepository = MockFavoritesRepository();
  });

  test('GetFavorites delegates to the repository', () async {
    when(() => mockRepository.getFavorites()).thenAnswer((_) async => const Right([pune]));

    final result = await GetFavorites(mockRepository)();

    expect(result, const Right([pune]));
    verify(() => mockRepository.getFavorites()).called(1);
  });

  test('AddFavorite delegates to the repository', () async {
    when(() => mockRepository.addFavorite(pune)).thenAnswer((_) async => const Right(unit));

    final result = await AddFavorite(mockRepository)(pune);

    expect(result, const Right(unit));
    verify(() => mockRepository.addFavorite(pune)).called(1);
  });

  test('RemoveFavorite delegates to the repository', () async {
    when(
      () => mockRepository.removeFavorite(pune),
    ).thenAnswer((_) async => const Left(CacheFailure('boom')));

    final result = await RemoveFavorite(mockRepository)(pune);

    expect(result.isLeft(), isTrue);
    verify(() => mockRepository.removeFavorite(pune)).called(1);
  });
}
