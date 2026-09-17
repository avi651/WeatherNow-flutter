import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/current_weather.dart';
import '../repositories/weather_repository.dart';

/// Fetches the current weather for a location.
class GetCurrentWeather {
  const GetCurrentWeather(this._repository);

  final WeatherRepository _repository;

  Future<Either<Failure, CurrentWeather>> call({
    required double latitude,
    required double longitude,
  }) {
    return _repository.getCurrentWeather(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
