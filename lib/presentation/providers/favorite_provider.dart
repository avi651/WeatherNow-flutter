import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/city_suggestion.dart';
import 'active_city_provider.dart';

/// The user's saved favorite cities, loaded from local storage on first
/// read and kept in sync as [add]/[remove]/[toggle] are called.
///
/// State updates optimistically — before the storage write resolves — so
/// the UI (the favorite star, a favorites list) reflects the change
/// immediately; if the write fails, the optimistic change is rolled back.
class FavoritesNotifier extends AsyncNotifier<List<CitySuggestion>> {
  @override
  Future<List<CitySuggestion>> build() async {
    final getFavorites = ref.watch(getFavoritesProvider);
    final result = await getFavorites();

    return result.fold(
      (failure) => throw StateError(failure.message),
      (favorites) => favorites,
    );
  }

  bool _contains(List<CitySuggestion> favorites, CitySuggestion city) {
    return favorites.any((favorite) => favorite == city);
  }

  Future<void> add(CitySuggestion city) async {
    final current = state.value ?? const <CitySuggestion>[];
    if (_contains(current, city)) return;

    state = AsyncData([...current, city]);

    final addFavorite = ref.read(addFavoriteProvider);
    final result = await addFavorite(city);
    result.fold((failure) => state = AsyncData(current), (_) {});
  }

  Future<void> remove(CitySuggestion city) async {
    final current = state.value ?? const <CitySuggestion>[];
    if (!_contains(current, city)) return;

    state = AsyncData(current.where((favorite) => favorite != city).toList());

    final removeFavorite = ref.read(removeFavoriteProvider);
    final result = await removeFavorite(city);
    result.fold((failure) => state = AsyncData(current), (_) {});
  }

  /// Adds [city] if it isn't already a favorite, otherwise removes it —
  /// what the hero card's star button calls.
  Future<void> toggle(CitySuggestion city) {
    final current = state.value ?? const <CitySuggestion>[];
    return _contains(current, city) ? remove(city) : add(city);
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<CitySuggestion>>(
      FavoritesNotifier.new,
    );

/// Whether [activeCityProvider]'s city is currently a favorite — `false`
/// while favorites are still loading, on a load failure, or when there's
/// no active city yet (e.g. the device location hasn't reverse-geocoded).
final isFavoriteProvider = Provider<bool>((ref) {
  final activeCity = ref.watch(activeCityProvider);
  if (activeCity == null) return false;

  final favorites = ref.watch(favoritesProvider).value ?? const [];
  return favorites.any((favorite) => favorite == activeCity);
});
