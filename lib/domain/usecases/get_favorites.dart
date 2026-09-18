import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/city_suggestion.dart';
import '../repositories/favorites_repository.dart';

/// Fetches the user's saved favorite cities.
class GetFavorites {
  const GetFavorites(this._repository);

  final FavoritesRepository _repository;

  Future<Either<Failure, List<CitySuggestion>>> call() {
    return _repository.getFavorites();
  }
}
