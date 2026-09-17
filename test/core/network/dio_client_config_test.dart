import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/config/app_environment.dart';
import 'package:weather_now_flutter/core/network/api_logging_interceptor.dart';
import 'package:weather_now_flutter/core/network/dio_client_config.dart';

void main() {
  group('DioClientConfig', () {
    test('attaches an ApiLoggingInterceptor so requests are diagnosable', () {
      const config = DioClientConfig(baseUrl: AppEnvironment.baseUrl);

      final dio = config.createDio();

      expect(dio.interceptors.whereType<ApiLoggingInterceptor>(), hasLength(1));
    });

    test('uses the provided base URL', () {
      const config = DioClientConfig(baseUrl: AppEnvironment.baseUrl);

      final dio = config.createDio();

      expect(dio.options.baseUrl, AppEnvironment.baseUrl);
    });

    test('uses default timeout values', () {
      const config = DioClientConfig(baseUrl: AppEnvironment.baseUrl);

      final dio = config.createDio();

      expect(dio.options.connectTimeout, const Duration(seconds: 10));

      expect(dio.options.receiveTimeout, const Duration(seconds: 10));
    });

    test('applies custom timeout values', () {
      const config = DioClientConfig(
        baseUrl: AppEnvironment.baseUrl,
        connectTimeout: Duration(seconds: 5),
        receiveTimeout: Duration(seconds: 15),
      );

      final dio = config.createDio();

      expect(dio.options.connectTimeout, const Duration(seconds: 5));

      expect(dio.options.receiveTimeout, const Duration(seconds: 15));
    });

    test('uses empty headers by default', () {
      const config = DioClientConfig(baseUrl: AppEnvironment.baseUrl);

      final dio = config.createDio();

      expect(dio.options.headers, isEmpty);
    });

    test('applies custom headers', () {
      const headers = {'Accept': 'application/json', 'X-App-Version': '1.0.0'};

      const config = DioClientConfig(
        baseUrl: AppEnvironment.baseUrl,
        headers: headers,
      );

      final dio = config.createDio();

      expect(dio.options.headers, headers);
    });

    test('creates a new Dio instance each time', () {
      const config = DioClientConfig(baseUrl: AppEnvironment.baseUrl);

      final firstDio = config.createDio();
      final secondDio = config.createDio();

      expect(firstDio, isA<Dio>());
      expect(secondDio, isA<Dio>());
      expect(identical(firstDio, secondDio), isFalse);
    });
  });
}
