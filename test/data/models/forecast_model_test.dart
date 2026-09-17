import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/data/models/forecast_model.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

void main() {
  Map<String, dynamic> entryJson({
    int dt = 1789560000,
    double temp = 29.99,
    String weatherMain = 'Rain',
  }) {
    return {
      'dt': dt,
      'main': {
        'temp': temp,
        'feels_like': temp,
        'humidity': 70,
        'pressure': 1010,
      },
      'weather': [
        {'id': 500, 'main': weatherMain, 'description': 'light rain', 'icon': '10d'},
      ],
      'pop': 0.5,
    };
  }

  // Shaped like OpenWeatherMap's 5-day/3-hour forecast response.
  Map<String, dynamic> json({List<Map<String, dynamic>>? list}) {
    return {
      'cod': '200',
      'message': 0,
      'cnt': list?.length ?? 0,
      'list': list ?? const [],
      'city': {
        'id': 1275339,
        'name': 'Mumbai',
        'coord': {'lat': 19.0144, 'lon': 72.8479},
        'country': 'IN',
        'timezone': 19800,
      },
    };
  }

  group('ForecastModel.fromJson', () {
    test('parses every entry in the list, preserving order', () {
      final model = ForecastModel.fromJson(
        json(
          list: [
            entryJson(dt: 1, temp: 20),
            entryJson(dt: 2, temp: 25),
            entryJson(dt: 3, temp: 30),
          ],
        ),
      );

      expect(model.entries, hasLength(3));
      expect(model.entries.map((e) => e.forecastForEpochSeconds), [1, 2, 3]);
      expect(model.entries.map((e) => e.temperatureCelsius), [20, 25, 30]);
    });

    test('parses an empty list', () {
      final model = ForecastModel.fromJson(json());

      expect(model.entries, isEmpty);
    });
  });

  group('ForecastModel.toEntity', () {
    test('maps each entry through ForecastEntryModel.toEntity', () {
      final entity = ForecastModel.fromJson(
        json(list: [entryJson(weatherMain: 'Snow')]),
      ).toEntity();

      expect(entity.entries, hasLength(1));
      expect(entity.entries.single.condition, WeatherCondition.snow);
    });

    test('an empty model maps to an empty forecast', () {
      final entity = ForecastModel.fromJson(json()).toEntity();

      expect(entity.isEmpty, isTrue);
    });
  });
}
