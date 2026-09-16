import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/network_failures.dart';
import 'package:weather_now_flutter/core/network/api_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ApiClient apiClient;

  setUp(() {
    mockDio = MockDio();
    apiClient = ApiClient(dio: mockDio);
  });

  Response<T> response<T>(String path, {T? data, int statusCode = 200}) {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: statusCode,
      data: data,
    );
  }

  DioException exception(DioExceptionType type, {int? statusCode}) {
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

  void mockGetSuccess<T>(String path, {T? data}) {
    when(
      () => mockDio.get<T>(
        path,
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => response<T>(path, data: data));
  }

  void mockGetFailure<T>(DioException error) {
    when(
      () => mockDio.get<T>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenThrow(error);
  }

  group('ApiClient.get', () {
    test('returns Right and forwards query parameters', () async {
      mockGetSuccess<Map<String, dynamic>>(
        '/weather',
        data: {'temperature': 25},
      );

      final result = await apiClient.get<Map<String, dynamic>>(
        '/weather',
        queryParameters: {'lat': 1.0, 'lon': 2.0},
      );

      expect(result.isRight(), isTrue);

      result.fold((failure) => fail('Expected Right, got $failure'), (
        response,
      ) {
        expect(response.statusCode, 200);
        expect(response.data, {'temperature': 25});
      });

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/weather',
          queryParameters: {'lat': 1.0, 'lon': 2.0},
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('returns ServerFailure for bad response', () async {
      mockGetFailure<Map<String, dynamic>>(
        exception(DioExceptionType.badResponse, statusCode: 404),
      );

      final result = await apiClient.get<Map<String, dynamic>>('/weather');

      expect(result.isLeft(), isTrue);

      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect((failure as ServerFailure).statusCode, 404);
      }, (_) => fail('Expected Left'));
    });

    test('returns UnknownFailure for unexpected error', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(StateError('Unexpected error'));

      final result = await apiClient.get<Map<String, dynamic>>('/weather');

      expect(result.isLeft(), isTrue);

      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('ApiClient.post', () {
    test('returns Right and forwards request body', () async {
      const requestBody = {'foo': 'bar'};

      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/weather',
          data: requestBody,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async =>
            response<Map<String, dynamic>>('/weather', data: {'success': true}),
      );

      final result = await apiClient.post<Map<String, dynamic>>(
        '/weather',
        data: requestBody,
      );

      expect(result.isRight(), isTrue);

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/weather',
          data: requestBody,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('returns Left when Dio throws', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(exception(DioExceptionType.badResponse, statusCode: 500));

      final result = await apiClient.post<Map<String, dynamic>>('/weather');

      expect(result.isLeft(), isTrue);
    });
  });

  group('ApiClient.put', () {
    test('returns Right and forwards request body', () async {
      const requestBody = {'foo': 'bar'};

      when(
        () => mockDio.put<Map<String, dynamic>>(
          '/weather/1',
          data: requestBody,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => response<Map<String, dynamic>>(
          '/weather/1',
          data: {'updated': true},
        ),
      );

      final result = await apiClient.put<Map<String, dynamic>>(
        '/weather/1',
        data: requestBody,
      );

      expect(result.isRight(), isTrue);

      verify(
        () => mockDio.put<Map<String, dynamic>>(
          '/weather/1',
          data: requestBody,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('returns Left when Dio throws', () async {
      when(
        () => mockDio.put<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(exception(DioExceptionType.badResponse, statusCode: 400));

      final result = await apiClient.put<Map<String, dynamic>>('/weather/1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('ApiClient.delete', () {
    test('returns Right when request succeeds', () async {
      when(
        () => mockDio.delete<Map<String, dynamic>>(
          '/weather/1',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => response<Map<String, dynamic>>(
          '/weather/1',
          data: {'deleted': true},
        ),
      );

      final result = await apiClient.delete<Map<String, dynamic>>('/weather/1');

      expect(result.isRight(), isTrue);

      verify(
        () => mockDio.delete<Map<String, dynamic>>(
          '/weather/1',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('returns Left when Dio throws', () async {
      when(
        () => mockDio.delete<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(exception(DioExceptionType.unknown));

      final result = await apiClient.delete<Map<String, dynamic>>('/weather/1');

      expect(result.isLeft(), isTrue);
    });
  });
}
