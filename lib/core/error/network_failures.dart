import 'failures.dart';

/// The server responded, but with an error status code (4xx/5xx).
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;
}

/// No usable network connection was available (DNS failure, no internet,
/// connection refused, etc).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// The request took too long — connect, send, or receive timeout.
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

/// The request was cancelled before it completed.
class CancelledFailure extends Failure {
  const CancelledFailure(super.message);
}

/// Anything that doesn't fit the categories above — an unexpected error
/// either from Dio or from code outside Dio's own error handling.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
