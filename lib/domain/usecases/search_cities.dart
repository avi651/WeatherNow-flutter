import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/city_suggestion.dart';
import '../repositories/geocoding_repository.dart';

/// Searches for cities matching [query], for the search-bar's suggestion
/// list.
///
/// A blank query resolves to an empty result immediately, without calling
/// the repository — there's nothing meaningful to search for, and it
/// saves a wasted network round-trip.
class SearchCities {
  const SearchCities(this._repository);

  final GeocodingRepository _repository;

  Future<Either<Failure, List<CitySuggestion>>> call({required String query}) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      return Future.value(const Right(<CitySuggestion>[]));
    }

    return _repository.searchCities(query: trimmed);
  }
}
