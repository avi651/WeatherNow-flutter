import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/forecast.dart';
import '../repositories/weather_repository.dart';

/// Fetches the weather forecast for a location.
class GetForecast {
  const GetForecast(this._repository);

  final WeatherRepository _repository;

  Future<Either<Failure, Forecast>> call({
    required double latitude,
    required double longitude,
  }) {
    return _repository.getForecast(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
