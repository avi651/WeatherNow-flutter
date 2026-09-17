import 'failures.dart';

/// The remote data source failed to produce a usable response — a network
/// problem, a timeout, or a non-2xx status. [statusCode] is set only when
/// the failure originated from an HTTP response.
///
/// This wraps [WeatherApiException], which already collapses the more
/// specific network failures into one exception type, so the repository
/// can't recover which one it originally was — it's kept distinct from
/// [ServerFailure] to avoid implying a specific HTTP failure that may not
/// have occurred.
class RemoteDataFailure extends Failure {
  const RemoteDataFailure(super.message, {this.statusCode});

  final int? statusCode;
}

/// The remote data source responded, but the payload didn't match the
/// shape a model expected — a missing field, an unexpected type, etc.
class DataParsingFailure extends Failure {
  const DataParsingFailure(super.message);
}
