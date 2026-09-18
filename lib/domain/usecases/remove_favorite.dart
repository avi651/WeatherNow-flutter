import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/city_suggestion.dart';
import '../repositories/favorites_repository.dart';

/// Removes a city from favorites.
class RemoveFavorite {
  const RemoveFavorite(this._repository);

  final FavoritesRepository _repository;

  Future<Either<Failure, Unit>> call(CitySuggestion city) {
    return _repository.removeFavorite(city);
  }
}
