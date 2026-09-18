import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/cache_failures.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/repositories/favorites_repository.dart';
import 'package:weather_now_flutter/presentation/providers/active_city_provider.dart';
import 'package:weather_now_flutter/presentation/providers/favorite_provider.dart';
import 'package:weather_now_flutter/presentation/providers/selected_city_provider.dart';

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

  const mumbai = CitySuggestion(
    name: 'Mumbai',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 19.0760,
    longitude: 72.8777,
  );

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [favoritesRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUpAll(() {
    registerFallbackValue(pune);
  });

  setUp(() {
    mockRepository = MockFavoritesRepository();
    when(() => mockRepository.getFavorites()).thenAnswer((_) async => const Right([]));
    when(() => mockRepository.addFavorite(any())).thenAnswer((_) async => const Right(unit));
    when(
      () => mockRepository.removeFavorite(any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  test('loads favorites from the repository', () async {
    when(
      () => mockRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune, mumbai]));

    final container = buildContainer();

    expect(await container.read(favoritesProvider.future), [pune, mumbai]);
  });

  test('starts empty when the repository fails to load favorites', () async {
    when(
      () => mockRepository.getFavorites(),
    ).thenAnswer((_) async => const Left(CacheFailure('boom')));

    final container = buildContainer();

    expect(await container.read(favoritesProvider.future), isEmpty);
  });

  test('add appends the city optimistically and persists it', () async {
    final container = buildContainer();
    await container.read(favoritesProvider.future);

    await container.read(favoritesProvider.notifier).add(pune);

    expect(container.read(favoritesProvider).value, [pune]);
    verify(() => mockRepository.addFavorite(pune)).called(1);
  });

  test('add rolls back the optimistic update when persisting fails', () async {
    when(
      () => mockRepository.addFavorite(pune),
    ).thenAnswer((_) async => const Left(CacheFailure('disk full')));

    final container = buildContainer();
    await container.read(favoritesProvider.future);

    await container.read(favoritesProvider.notifier).add(pune);

    expect(container.read(favoritesProvider).value, isEmpty);
  });

  test('remove drops the city optimistically and persists it', () async {
    when(
      () => mockRepository.getFavorites(),
    ).thenAnswer((_) async => const Right([pune, mumbai]));

    final container = buildContainer();
    await container.read(favoritesProvider.future);

    await container.read(favoritesProvider.notifier).remove(pune);

    expect(container.read(favoritesProvider).value, [mumbai]);
    verify(() => mockRepository.removeFavorite(pune)).called(1);
  });

  test('toggle adds when not a favorite and removes when it already is', () async {
    final container = buildContainer();
    await container.read(favoritesProvider.future);

    await container.read(favoritesProvider.notifier).toggle(pune);
    expect(container.read(favoritesProvider).value, [pune]);

    await container.read(favoritesProvider.notifier).toggle(pune);
    expect(container.read(favoritesProvider).value, isEmpty);
  });

  group('isFavoriteProvider', () {
    test('is false when there is no active city', () async {
      final container = buildContainer();
      await container.read(favoritesProvider.future);

      expect(container.read(isFavoriteProvider), isFalse);
    });

    test('reflects whether the active city is in the favorites list', () async {
      when(
        () => mockRepository.getFavorites(),
      ).thenAnswer((_) async => const Right([pune]));

      final container = buildContainer();
      await container.read(favoritesProvider.future);
      container.read(selectedCityProvider.notifier).select(pune);

      expect(container.read(activeCityProvider), pune);
      expect(container.read(isFavoriteProvider), isTrue);

      container.read(selectedCityProvider.notifier).select(mumbai);
      expect(container.read(isFavoriteProvider), isFalse);
    });
  });
}
