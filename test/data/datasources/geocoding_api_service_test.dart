import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/constants/geocoding_api_endpoints.dart';
import 'package:weather_now_flutter/core/error/network_failures.dart';
import 'package:weather_now_flutter/core/error/geocoding_api_exception.dart';
import 'package:weather_now_flutter/core/network/api_client.dart';
import 'package:weather_now_flutter/core/network/geocoding_api_params.dart';
import 'package:weather_now_flutter/data/datasources/geocoding_api_service.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late GeocodingApiService service;

  const apiKey = 'test-api-key';
  const query = 'London';

  final expectedQuery = GeocodingApiParams.search(query: query, apiKey: apiKey);

  setUp(() {
    mockApiClient = MockApiClient();
    service = GeocodingApiService(apiClient: mockApiClient, apiKey: apiKey);
  });

  Response<List<dynamic>> response({List<dynamic>? data}) {
    return Response<List<dynamic>>(
      requestOptions: RequestOptions(path: GeocodingApiEndpoints.directGeocoding),
      statusCode: 200,
      data: data,
    );
  }

  group('GeocodingApiService.searchCities', () {
    test('returns decoded results and forwards the query', () async {
      when(
        () => mockApiClient.get<List<dynamic>>(
          GeocodingApiEndpoints.directGeocoding,
          queryParameters: expectedQuery,
        ),
      ).thenAnswer(
        (_) async => Right(
          response(
            data: [
              {'name': 'London', 'country': 'GB', 'lat': 51.5, 'lon': -0.12},
            ],
          ),
        ),
      );

      final result = await service.searchCities(query: query);

      expect(result, [
        {'name': 'London', 'country': 'GB', 'lat': 51.5, 'lon': -0.12},
      ]);
      verify(
        () => mockApiClient.get<List<dynamic>>(
          GeocodingApiEndpoints.directGeocoding,
          queryParameters: expectedQuery,
        ),
      ).called(1);
    });

    test('returns an empty list when the response data is null', () async {
      when(
        () => mockApiClient.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => Right(response()));

      final result = await service.searchCities(query: query);

      expect(result, isEmpty);
    });

    test('throws GeocodingApiException with status code on ServerFailure', () async {
      when(
        () => mockApiClient.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure('Unauthorized', statusCode: 401)),
      );

      expect(
        () => service.searchCities(query: query),
        throwsA(
          isA<GeocodingApiException>()
              .having((e) => e.message, 'message', 'Unauthorized')
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('throws GeocodingApiException without a status code on other failures', () async {
      when(
        () => mockApiClient.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure('No connection')));

      expect(
        () => service.searchCities(query: query),
        throwsA(
          isA<GeocodingApiException>()
              .having((e) => e.message, 'message', 'No connection')
              .having((e) => e.statusCode, 'statusCode', isNull),
        ),
      );
    });
  });

  group('GeocodingApiService.reverseGeocode', () {
    const latitude = 18.5213738;
    const longitude = 73.8545071;
    final expectedReverseQuery = GeocodingApiParams.reverse(
      latitude: latitude,
      longitude: longitude,
      apiKey: apiKey,
    );

    test('returns decoded results and forwards the coordinates', () async {
      when(
        () => mockApiClient.get<List<dynamic>>(
          GeocodingApiEndpoints.reverseGeocoding,
          queryParameters: expectedReverseQuery,
        ),
      ).thenAnswer(
        (_) async => Right(
          response(
            data: [
              {'name': 'Pune', 'country': 'IN', 'lat': latitude, 'lon': longitude},
            ],
          ),
        ),
      );

      final result = await service.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      expect(result, [
        {'name': 'Pune', 'country': 'IN', 'lat': latitude, 'lon': longitude},
      ]);
      verify(
        () => mockApiClient.get<List<dynamic>>(
          GeocodingApiEndpoints.reverseGeocoding,
          queryParameters: expectedReverseQuery,
        ),
      ).called(1);
    });

    test('returns an empty list when the response data is null', () async {
      when(
        () => mockApiClient.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => Right(response()));

      final result = await service.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      expect(result, isEmpty);
    });

    test('throws GeocodingApiException with status code on ServerFailure', () async {
      when(
        () => mockApiClient.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure('Unauthorized', statusCode: 401)),
      );

      expect(
        () => service.reverseGeocode(latitude: latitude, longitude: longitude),
        throwsA(
          isA<GeocodingApiException>()
              .having((e) => e.message, 'message', 'Unauthorized')
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });
}
