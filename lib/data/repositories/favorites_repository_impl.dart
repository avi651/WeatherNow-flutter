import 'package:dartz/dartz.dart';

import '../../core/error/error_logger.dart';
import '../../core/constants/app_strings.dart';
import '../../core/error/cache_failures.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/city_suggestion.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_data_source.dart';
import '../local/location_cache_key.dart';
import '../models/city_suggestion_model.dart';

/// Persists favorite cities through a [FavoritesLocalDataSource] — Hive in
/// production — translating storage errors into [Failure]s so callers
/// never see a raw Hive exception. Mirrors [WeatherRepositoryImpl]'s shape.
class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl({
    required FavoritesLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final FavoritesLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, List<CitySuggestion>>> getFavorites() async {
    try {
      final cities =
          _localDataSource
              .getAll()
              .map((json) => CitySuggestionModel.fromJson(json).toEntity())
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      return Right(cities);
    } catch (error, stackTrace) {
      logError('Failed to read favorites', error, stackTrace);
      return const Left(CacheFailure(AppStrings.storageReadError));
    }
  }

  @override
  Future<Either<Failure, Unit>> addFavorite(CitySuggestion city) async {
    try {
      await _localDataSource.put(
        _keyFor(city),
        CitySuggestionModel.fromEntity(city).toJson(),
      );
      return const Right(unit);
    } catch (error, stackTrace) {
      logError('Failed to save favorite', error, stackTrace);
      return const Left(CacheFailure(AppStrings.storageWriteError));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeFavorite(CitySuggestion city) async {
    try {
      await _localDataSource.delete(_keyFor(city));
      return const Right(unit);
    } catch (error, stackTrace) {
      logError('Failed to remove favorite', error, stackTrace);
      return const Left(CacheFailure(AppStrings.storageWriteError));
    }
  }

  String _keyFor(CitySuggestion city) {
    return LocationCacheKey.of(
      latitude: city.latitude,
      longitude: city.longitude,
    );
  }
}
