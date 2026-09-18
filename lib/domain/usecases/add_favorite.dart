import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/city_suggestion.dart';
import '../repositories/favorites_repository.dart';

/// Saves a city as a favorite.
class AddFavorite {
  const AddFavorite(this._repository);

  final FavoritesRepository _repository;

  Future<Either<Failure, Unit>> call(CitySuggestion city) {
    return _repository.addFavorite(city);
  }
}
