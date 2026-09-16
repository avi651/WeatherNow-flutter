import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/error/network_failures.dart';
import 'package:weather_now_flutter/core/network/dio_exception_mapper.dart';

void main() {
  const mapper = DioExceptionMapper();

  DioException dioError(DioExceptionType type, {int? statusCode}) {
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: type,
      response: statusCode == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: statusCode,
            ),
    );
  }

  group('DioExceptionMapper.mapDioException', () {
    test('maps connectionTimeout to TimeoutFailure', () {
      final failure = mapper.mapDioException(
        dioError(DioExceptionType.connectionTimeout),
      );

      expect(failure, isA<TimeoutFailure>());
    });

    test('maps sendTimeout to TimeoutFailure', () {
      final failure = mapper.mapDioException(
        dioError(DioExceptionType.sendTimeout),
      );

      expect(failure, isA<TimeoutFailure>());
    });

    test('maps receiveTimeout to TimeoutFailure', () {
      final failure = mapper.mapDioException(
        dioError(DioExceptionType.receiveTimeout),
      );

      expect(failure, isA<TimeoutFailure>());
    });

    test('maps cancel to CancelledFailure', () {
      final failure = mapper.mapDioException(dioError(DioExceptionType.cancel));

      expect(failure, isA<CancelledFailure>());
    });

    test('maps connectionError to NetworkFailure', () {
      final failure = mapper.mapDioException(
        dioError(DioExceptionType.connectionError),
      );

      expect(failure, isA<NetworkFailure>());
    });

    test('maps badResponse to ServerFailure with status code', () {
      final failure = mapper.mapDioException(
        dioError(DioExceptionType.badResponse, statusCode: 404),
      );

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 404);
    });

    test('maps badCertificate to UnknownFailure', () {
      final failure = mapper.mapDioException(
        dioError(DioExceptionType.badCertificate),
      );

      expect(failure, isA<UnknownFailure>());
    });

    test('maps unknown to UnknownFailure', () {
      final failure = mapper.mapDioException(
        dioError(DioExceptionType.unknown),
      );

      expect(failure, isA<UnknownFailure>());
    });
  });

  group('DioExceptionMapper.mapUnknownError', () {
    test('wraps non-Dio error as UnknownFailure', () {
      final failure = mapper.mapUnknownError(StateError('Unexpected error'));

      expect(failure, isA<UnknownFailure>());
    });
  });
}
