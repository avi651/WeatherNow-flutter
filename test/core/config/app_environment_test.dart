import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/config/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    test('exactly one environment flag is true', () {
      final flags = [
        AppEnvironment.isMock,
        AppEnvironment.isDev,
        AppEnvironment.isProduction,
      ];

      expect(flags.where((flag) => flag).length, 1);
    });

    test(
      'defaults to mock with empty baseUrl/apiKey when no --dart-define is '
      'passed',
      () {
        expect(AppEnvironment.environment, 'mock');
        expect(AppEnvironment.isMock, isTrue);
        expect(AppEnvironment.baseUrl, isEmpty);
        expect(AppEnvironment.apiKey, isEmpty);
      },
    );
  });
}
