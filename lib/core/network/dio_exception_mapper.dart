import 'package:dio/dio.dart';

import '../error/failures.dart';
import '../error/network_failures.dart';

/// Maps Dio errors to the app's Failure hierarchy.
class DioExceptionMapper {
  const DioExceptionMapper();

  Failure mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutFailure('The request timed out');

      case DioExceptionType.cancel:
        return const CancelledFailure('The request was cancelled');

      case DioExceptionType.connectionError:
        return const NetworkFailure('No internet connection');

      case DioExceptionType.badResponse:
        return ServerFailure(
          'The server returned an error',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return UnknownFailure(
          error.message ?? 'An unknown network error occurred',
        );
    }
  }

  /// Maps unexpected errors to an UnknownFailure.
  Failure mapUnknownError(Object error) {
    return UnknownFailure('Unexpected error: $error');
  }
}
