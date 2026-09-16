import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/constants/weather_api_endpoints.dart';
import 'package:weather_now_flutter/core/error/network_failures.dart';
import 'package:weather_now_flutter/core/error/weather_api_exception.dart';
import 'package:weather_now_flutter/core/network/api_client.dart';
import 'package:weather_now_flutter/core/network/weather_api_params.dart';
import 'package:weather_now_flutter/data/datasources/weather_api_service.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late WeatherApiService service;

  const apiKey = 'test-api-key';
  const latitude = 12.34;
  const longitude = 56.78;

  final expectedQuery = WeatherApiParams.coordinates(
    latitude: latitude,
    longitude: longitude,
    apiKey: apiKey,
  );

  setUp(() {
    mockApiClient = MockApiClient();
    service = WeatherApiService(apiClient: mockApiClient, apiKey: apiKey);
  });

  Response<Map<String, dynamic>> response(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: data,
    );
  }

  group('WeatherApiService.getCurrentWeather', () {
    test('returns decoded data and forwards coordinates', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          WeatherApiEndpoints.currentWeather,
          queryParameters: expectedQuery,
        ),
      ).thenAnswer(
        (_) async =>
            Right(response(WeatherApiEndpoints.currentWeather, data: {'temp': 25})),
      );

      final result = await service.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );

      expect(result, {'temp': 25});
      verify(
        () => mockApiClient.get<Map<String, dynamic>>(
          WeatherApiEndpoints.currentWeather,
          queryParameters: expectedQuery,
        ),
      ).called(1);
    });

    test(
      'throws WeatherApiException with status code on ServerFailure',
      () async {
        when(
          () => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('Not found', statusCode: 404)),
        );

        expect(
          () => service.getCurrentWeather(
            latitude: latitude,
            longitude: longitude,
          ),
          throwsA(
            isA<WeatherApiException>()
                .having((e) => e.message, 'message', 'Not found')
                .having((e) => e.statusCode, 'statusCode', 404),
          ),
        );
      },
    );

    test(
      'throws WeatherApiException without a status code on other failures',
      () async {
        when(
          () => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure('No connection')));

        expect(
          () => service.getCurrentWeather(
            latitude: latitude,
            longitude: longitude,
          ),
          throwsA(
            isA<WeatherApiException>()
                .having((e) => e.message, 'message', 'No connection')
                .having((e) => e.statusCode, 'statusCode', isNull),
          ),
        );
      },
    );

    test('throws WeatherApiException when response data is null', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Right(response(WeatherApiEndpoints.currentWeather)),
      );

      expect(
        () => service.getCurrentWeather(
          latitude: latitude,
          longitude: longitude,
        ),
        throwsA(
          isA<WeatherApiException>().having(
            (e) => e.message,
            'message',
            'Empty response from weather service',
          ),
        ),
      );
    });
  });

  group('WeatherApiService.getForecast', () {
    test('returns decoded data and forwards coordinates', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          WeatherApiEndpoints.forecast,
          queryParameters: expectedQuery,
        ),
      ).thenAnswer(
        (_) async =>
            Right(response(WeatherApiEndpoints.forecast, data: {'list': []})),
      );

      final result = await service.getForecast(
        latitude: latitude,
        longitude: longitude,
      );

      expect(result, {'list': []});
      verify(
        () => mockApiClient.get<Map<String, dynamic>>(
          WeatherApiEndpoints.forecast,
          queryParameters: expectedQuery,
        ),
      ).called(1);
    });

    test('throws WeatherApiException on ServerFailure', () async {
      when(
        () => mockApiClient.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left(ServerFailure('Server error', statusCode: 500)),
      );

      expect(
        () =>
            service.getForecast(latitude: latitude, longitude: longitude),
        throwsA(
          isA<WeatherApiException>()
              .having((e) => e.message, 'message', 'Server error')
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });
}
