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
        return _mapBadResponse(error.response?.statusCode);

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

  /// Gives a 4xx/5xx response a message specific enough to act on — e.g.
  /// telling an invalid API key apart from a rate limit apart from the
  /// provider being down — instead of one generic string for every status
  /// code. Never reads the response body: it may not be JSON, and the
  /// status code alone is enough to classify these cases without risking
  /// echoing back anything request- or provider-specific into a
  /// user-facing message.
  ServerFailure _mapBadResponse(int? statusCode) {
    final String message;
    if (statusCode == 401 || statusCode == 403) {
      message = 'Invalid or unauthorized API key';
    } else if (statusCode == 429) {
      message = 'Too many requests — rate limit exceeded, please try again later';
    } else if (statusCode != null && statusCode >= 500 && statusCode <= 599) {
      message = 'The weather service is temporarily unavailable';
    } else {
      message = 'The server returned an error';
    }

    return ServerFailure(message, statusCode: statusCode);
  }
}
