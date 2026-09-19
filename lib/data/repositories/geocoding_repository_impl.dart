import 'package:dartz/dartz.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../core/error/data_failures.dart';
import '../../core/error/failures.dart';
import '../../core/error/geocoding_api_exception.dart';
import '../../domain/entities/city_suggestion.dart';
import '../../domain/repositories/geocoding_repository.dart';
import '../datasources/geocoding_data_source.dart';
import '../models/city_suggestion_model.dart';

/// Searches for cities through a [GeocodingDataSource] — the real
/// [GeocodingApiService] or the mock one, depending on
/// [AppEnvironment.isMock] — and translates its raw JSON and exceptions
/// into domain entities and [Failure]s. Mirrors [WeatherRepositoryImpl]'s
/// shape.
class GeocodingRepositoryImpl implements GeocodingRepository {
  const GeocodingRepositoryImpl({required GeocodingDataSource dataSource})
    : _dataSource = dataSource;

  final GeocodingDataSource _dataSource;

  @override
  Future<Either<Failure, List<CitySuggestion>>> searchCities({
    required String query,
  }) {
    return _run(() async {
      final results = await _dataSource.searchCities(query: query);
      return results
          .map((json) => CitySuggestionModel.fromJson(json).toEntity())
          .toList();
    });
  }

  @override
  Future<Either<Failure, CitySuggestion>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) {
    return _run(() async {
      final results = await _dataSource.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      if (results.isEmpty) {
        throw GeocodingApiException(AppStrings.noLocationForCoordinates);
      }

      return CitySuggestionModel.fromJson(results.first).toEntity();
    });
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on GeocodingApiException catch (error) {
      return Left(
        RemoteDataFailure(error.message, statusCode: error.statusCode),
      );
    } catch (error) {
      return Left(
        DataParsingFailure('Failed to parse city search response: $error'),
      );
    }
  }
}
