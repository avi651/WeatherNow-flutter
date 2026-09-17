import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/network/api_logging_interceptor.dart';

void main() {
  group('ApiLoggingInterceptor.redact', () {
    test('replaces the appid query parameter with a placeholder', () {
      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=19.0144&lon=72.8479&appid=super-secret-key&units=metric',
      );

      final redacted = ApiLoggingInterceptor.redact(uri);

      expect(redacted.queryParameters['appid'], '***');
      expect(redacted.toString(), isNot(contains('super-secret-key')));
    });

    test('preserves every other query parameter unchanged', () {
      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=19.0144&lon=72.8479&appid=super-secret-key&units=metric',
      );

      final redacted = ApiLoggingInterceptor.redact(uri);

      expect(redacted.queryParameters['lat'], '19.0144');
      expect(redacted.queryParameters['lon'], '72.8479');
      expect(redacted.queryParameters['units'], 'metric');
    });

    test('returns the URI unchanged when there is no appid parameter', () {
      final uri = Uri.parse('https://api.openweathermap.org/data/2.5/weather');

      expect(ApiLoggingInterceptor.redact(uri), uri);
    });
  });
}
