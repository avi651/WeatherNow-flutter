import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/city_suggestion.dart';
import '../repositories/geocoding_repository.dart';

/// Resolves the device's GPS coordinates into a display-ready
/// [CitySuggestion], for the "use my location" flow.
class ReverseGeocode {
  const ReverseGeocode(this._repository);

  final GeocodingRepository _repository;

  Future<Either<Failure, CitySuggestion>> call({
    required double latitude,
    required double longitude,
  }) {
    return _repository.reverseGeocode(latitude: latitude, longitude: longitude);
  }
}
