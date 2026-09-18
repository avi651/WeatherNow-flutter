import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/cached_current_weather.dart';
import '../entities/cached_forecast.dart';
import '../entities/current_weather.dart';
import '../entities/forecast.dart';

/// Persists the most recently fetched current weather and forecast per
/// location, so the app can keep showing (clearly marked, stale) data when
/// a fresh fetch fails — e.g. because the device is offline.
///
/// This is deliberately separate from [WeatherRepository]: that interface
/// represents "get me the weather," while this one represents "remember
/// the weather," so callers can (and do) fetch fresh data and fall back to
/// a cached snapshot without either repository knowing about the other.
abstract class WeatherCacheRepository {
  Future<Either<Failure, Unit>> saveCurrentWeather({
    required double latitude,
    required double longitude,
    required CurrentWeather weather,
    required DateTime fetchedAt,
    String? cityName,
    String? country,
  });

  /// The last cached current weather for this location, or `Right(null)`
  /// if nothing has ever been cached for it.
  Future<Either<Failure, CachedCurrentWeather?>> getCurrentWeather({
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, Unit>> saveForecast({
    required double latitude,
    required double longitude,
    required Forecast forecast,
    required DateTime fetchedAt,
    String? cityName,
    String? country,
  });

  /// The last cached forecast for this location, or `Right(null)` if
  /// nothing has ever been cached for it.
  Future<Either<Failure, CachedForecast?>> getForecast({
    required double latitude,
    required double longitude,
  });
}
