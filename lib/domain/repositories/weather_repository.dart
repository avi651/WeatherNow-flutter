import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/current_weather.dart';
import '../entities/forecast.dart';

/// Provides weather data to the domain layer, hiding whatever provider or
/// transport the data layer uses to obtain it.
abstract class WeatherRepository {
  Future<Either<Failure, CurrentWeather>> getCurrentWeather({
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, Forecast>> getForecast({
    required double latitude,
    required double longitude,
  });
}
