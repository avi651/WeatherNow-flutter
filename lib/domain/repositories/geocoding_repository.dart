import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/city_suggestion.dart';

/// Resolves a free-text query (a city, state, or country name) into
/// matching cities, hiding whatever geocoding provider the data layer
/// uses to obtain them.
abstract class GeocodingRepository {
  Future<Either<Failure, List<CitySuggestion>>> searchCities({
    required String query,
  });

  /// Resolves the nearest known place to [latitude]/[longitude] — used to
  /// turn the device's GPS coordinates into a display-ready [CitySuggestion]
  /// for the "use my location" flow.
  Future<Either<Failure, CitySuggestion>> reverseGeocode({
    required double latitude,
    required double longitude,
  });
}
