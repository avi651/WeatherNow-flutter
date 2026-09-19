import 'package:dio/dio.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

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
        return const TimeoutFailure(AppStrings.requestTimedOut);

      case DioExceptionType.cancel:
        return const CancelledFailure(AppStrings.requestCancelled);

      case DioExceptionType.connectionError:
        return const NetworkFailure(AppStrings.noInternet);

      case DioExceptionType.badResponse:
        return _mapBadResponse(error.response?.statusCode);

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return UnknownFailure(error.message ?? AppStrings.unknownNetworkError);
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
      message = AppStrings.invalidApiKey;
    } else if (statusCode == 429) {
      message = AppStrings.rateLimitExceeded;
    } else if (statusCode != null && statusCode >= 500 && statusCode <= 599) {
      message = AppStrings.weatherServiceUnavailable;
    } else {
      message = AppStrings.serverError;
    }

    return ServerFailure(message, statusCode: statusCode);
  }
}
