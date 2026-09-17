import 'package:dartz/dartz.dart';

import '../../core/error/data_failures.dart';
import '../../core/error/failures.dart';
import '../../core/error/weather_api_exception.dart';
import '../../domain/entities/current_weather.dart';
import '../../domain/entities/forecast.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_data_source.dart';
import '../models/current_weather_model.dart';
import '../models/forecast_model.dart';

/// Fetches weather data through a [WeatherDataSource] — the real
/// [WeatherApiService] or the mock one, depending on [AppEnvironment.isMock]
/// — and translates its raw JSON and exceptions into domain entities and
/// [Failure]s.
class WeatherRepositoryImpl implements WeatherRepository {
  const WeatherRepositoryImpl({required WeatherDataSource dataSource})
      : _dataSource = dataSource;

  final WeatherDataSource _dataSource;

  @override
  Future<Either<Failure, CurrentWeather>> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) {
    return _run(() async {
      final json = await _dataSource.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );
      return CurrentWeatherModel.fromJson(json).toEntity();
    });
  }

  @override
  Future<Either<Failure, Forecast>> getForecast({
    required double latitude,
    required double longitude,
  }) {
    return _run(() async {
      final json = await _dataSource.getForecast(
        latitude: latitude,
        longitude: longitude,
      );
      return ForecastModel.fromJson(json).toEntity();
    });
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on WeatherApiException catch (error) {
      return Left(RemoteDataFailure(error.message, statusCode: error.statusCode));
    } catch (error) {
      return Left(DataParsingFailure('Failed to parse weather response: $error'));
    }
  }
}
