import 'package:dartz/dartz.dart';

import '../../core/error/cache_failures.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/cached_current_weather.dart';
import '../../domain/entities/cached_forecast.dart';
import '../../domain/entities/current_weather.dart';
import '../../domain/entities/forecast.dart';
import '../../domain/repositories/weather_cache_repository.dart';
import '../datasources/weather_cache_local_data_source.dart';
import '../local/location_cache_key.dart';
import '../models/cached_current_weather_model.dart';
import '../models/cached_forecast_model.dart';

/// Persists the latest current weather/forecast per location through a
/// [WeatherCacheLocalDataSource] — Hive in production — translating storage
/// errors into [Failure]s so callers never see a raw Hive exception.
class WeatherCacheRepositoryImpl implements WeatherCacheRepository {
  const WeatherCacheRepositoryImpl({
    required WeatherCacheLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final WeatherCacheLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, Unit>> saveCurrentWeather({
    required double latitude,
    required double longitude,
    required CurrentWeather weather,
    required DateTime fetchedAt,
    String? cityName,
    String? country,
  }) async {
    try {
      final model = CachedCurrentWeatherModel.fromEntity(
        weather: weather,
        fetchedAt: fetchedAt,
        cityName: cityName,
        country: country,
      );
      await _localDataSource.putCurrentWeather(_keyFor(latitude, longitude), model.toJson());
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('Failed to cache current weather: $error'));
    }
  }

  @override
  Future<Either<Failure, CachedCurrentWeather?>> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final json = _localDataSource.getCurrentWeather(_keyFor(latitude, longitude));
      if (json == null) return const Right(null);

      return Right(CachedCurrentWeatherModel.fromJson(json).toEntity());
    } catch (error) {
      return Left(CacheFailure('Failed to read cached current weather: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveForecast({
    required double latitude,
    required double longitude,
    required Forecast forecast,
    required DateTime fetchedAt,
    String? cityName,
    String? country,
  }) async {
    try {
      final model = CachedForecastModel.fromEntity(
        forecast: forecast,
        fetchedAt: fetchedAt,
        cityName: cityName,
        country: country,
      );
      await _localDataSource.putForecast(_keyFor(latitude, longitude), model.toJson());
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('Failed to cache forecast: $error'));
    }
  }

  @override
  Future<Either<Failure, CachedForecast?>> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final json = _localDataSource.getForecast(_keyFor(latitude, longitude));
      if (json == null) return const Right(null);

      return Right(CachedForecastModel.fromJson(json).toEntity());
    } catch (error) {
      return Left(CacheFailure('Failed to read cached forecast: $error'));
    }
  }

  String _keyFor(double latitude, double longitude) {
    return LocationCacheKey.of(latitude: latitude, longitude: longitude);
  }
}
