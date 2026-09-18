import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/city_suggestion.dart';

/// Persists the user's favorite cities so they survive an app restart.
abstract class FavoritesRepository {
  Future<Either<Failure, List<CitySuggestion>>> getFavorites();

  Future<Either<Failure, Unit>> addFavorite(CitySuggestion city);

  Future<Either<Failure, Unit>> removeFavorite(CitySuggestion city);
}
