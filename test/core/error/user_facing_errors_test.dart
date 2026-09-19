import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';
import 'package:weather_now_flutter/core/error/data_failures.dart';
import 'package:weather_now_flutter/core/error/failures.dart';
import 'package:weather_now_flutter/core/network/dio_exception_mapper.dart';
import 'package:weather_now_flutter/data/datasources/geocoding_data_source.dart';
import 'package:weather_now_flutter/data/datasources/weather_data_source.dart';
import 'package:weather_now_flutter/data/repositories/geocoding_repository_impl.dart';
import 'package:weather_now_flutter/data/repositories/weather_repository_impl.dart';

class MockWeatherDataSource extends Mock implements WeatherDataSource {}

class MockGeocodingDataSource extends Mock implements GeocodingDataSource {}

/// Technical fragments that must never reach a user-facing message.
const _leaks = [
  'DioException',
  'FormatException',
  'HandshakeException',
  'CERTIFICATE',
  'type \'',
  'Null',
  'Exception',
  'Unexpected error',
  'Failed to parse',
  'SecretDetail',
];

void expectSanitized(String message) {
  for (final leak in _leaks) {
    expect(message, isNot(contains(leak)), reason: 'leaked "$leak"');
  }
}

void main() {
  const mapper = DioExceptionMapper();

  DioException dioError(DioExceptionType type, {String? message}) =>
      DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: type,
        message: message,
        error: 'SecretDetail',
      );

  group('DioExceptionMapper sanitizes messages', () {
    test('badCertificate hides the certificate details', () {
      final failure = mapper.mapDioException(
        dioError(
          DioExceptionType.badCertificate,
          message: 'CERTIFICATE_VERIFY_FAILED SecretDetail',
        ),
      );

      expect(failure.message, AppStrings.secureConnectionFailed);
      expectSanitized(failure.message);
    });

    test('unknown hides the underlying exception message', () {
      final failure = mapper.mapDioException(
        dioError(
          DioExceptionType.unknown,
          message: 'DioException [unknown]: FormatException SecretDetail',
        ),
      );

      expect(failure.message, AppStrings.unknownNetworkError);
      expectSanitized(failure.message);
    });

    test('mapUnknownError hides the raw exception', () {
      final failure = mapper.mapUnknownError(
        const FormatException('SecretDetail'),
      );

      expect(failure.message, AppStrings.unexpectedError);
      expectSanitized(failure.message);
    });

    test('timeout, offline and status-code messages are preserved', () {
      expect(
        mapper
            .mapDioException(dioError(DioExceptionType.receiveTimeout))
            .message,
        AppStrings.requestTimedOut,
      );
      expect(
        mapper
            .mapDioException(dioError(DioExceptionType.connectionError))
            .message,
        AppStrings.noInternet,
      );
      for (final entry in {
        401: AppStrings.invalidApiKey,
        429: AppStrings.rateLimitExceeded,
        503: AppStrings.weatherServiceUnavailable,
        404: AppStrings.serverError,
      }.entries) {
        final failure = mapper.mapDioException(
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: entry.key,
              data: 'SecretDetail',
            ),
          ),
        );
        expect(failure.message, entry.value);
      }
    });
  });

  group('repositories sanitize parse failures', () {
    test('weather repository', () async {
      final dataSource = MockWeatherDataSource();
      when(
        () => dataSource.getCurrentWeather(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => {'SecretDetail': 'bad shape'});

      final result = await WeatherRepositoryImpl(
        dataSource: dataSource,
      ).getCurrentWeather(latitude: 1, longitude: 2);

      final failure = result.fold<Failure>((f) => f, (_) => fail('Left'));
      expect(failure, isA<DataParsingFailure>());
      expect(failure.message, AppStrings.weatherParseError);
      expectSanitized(failure.message);
    });

    test('geocoding repository', () async {
      final dataSource = MockGeocodingDataSource();
      when(
        () => dataSource.searchCities(query: any(named: 'query')),
      ).thenAnswer(
        (_) async => [
          <String, dynamic>{'SecretDetail': 1},
        ],
      );

      final result = await GeocodingRepositoryImpl(
        dataSource: dataSource,
      ).searchCities(query: 'x');

      final failure = result.fold<Failure>((f) => f, (_) => fail('Left'));
      expect(failure, isA<DataParsingFailure>());
      expect(failure.message, AppStrings.citySearchParseError);
      expectSanitized(failure.message);
    });
  });
}
