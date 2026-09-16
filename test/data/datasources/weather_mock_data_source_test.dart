import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/data/datasources/weather_mock_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dataSource = WeatherMockDataSource();

  void mockAssets(Map<String, String> assets) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          final content = assets[key];

          if (content == null) return null;

          return ByteData.view(Uint8List.fromList(utf8.encode(content)).buffer);
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    rootBundle.clear();
  });

  group('WeatherMockDataSource.getCurrentWeather', () {
    test('returns the decoded current weather asset', () async {
      mockAssets({
        'assets/mock/current_weather.json': jsonEncode({'temp': 21.5}),
      });

      final result = await dataSource.getCurrentWeather();

      expect(result, {'temp': 21.5});
    });

    test('throws FormatException when the asset JSON is malformed', () async {
      mockAssets({'assets/mock/current_weather.json': 'not valid json'});

      expect(dataSource.getCurrentWeather(), throwsA(isA<FormatException>()));
    });
  });

  group('WeatherMockDataSource.getForecast', () {
    test('returns the decoded forecast asset', () async {
      mockAssets({
        'assets/mock/forecast.json': jsonEncode({
          'list': [
            {'dt': 1234},
          ],
        }),
      });

      final result = await dataSource.getForecast();

      expect(result, {
        'list': [
          {'dt': 1234},
        ],
      });
    });

    test('throws FormatException when the asset JSON is malformed', () async {
      mockAssets({'assets/mock/forecast.json': 'not valid json'});

      expect(dataSource.getForecast(), throwsA(isA<FormatException>()));
    });
  });
}
