import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/data/models/forecast_entry_model.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

void main() {
  // Shaped like one entry of OpenWeatherMap's `list` in the forecast response.
  Map<String, dynamic> json({
    int dt = 1789560000,
    double temp = 29.99,
    double feelsLike = 35.01,
    int humidity = 70,
    String weatherMain = 'Rain',
    String description = 'light rain',
    Object? pop = 1,
  }) {
    return {
      'dt': dt,
      'main': {
        'temp': temp,
        'feels_like': feelsLike,
        'temp_min': 27.88,
        'temp_max': 29.99,
        'pressure': 1010,
        'sea_level': 1010,
        'grnd_level': 1009,
        'humidity': humidity,
        'temp_kf': 2.11,
      },
      'weather': [
        {
          'id': 500,
          'main': weatherMain,
          'description': description,
          'icon': '10d',
        },
      ],
      'clouds': {'all': 4},
      'wind': {'speed': 3.93, 'deg': 245, 'gust': 4.54},
      'visibility': 10000,
      'pop': ?pop,
      'sys': {'pod': 'd'},
      'dt_txt': '2026-09-16 12:00:00',
    };
  }

  group('ForecastEntryModel.fromJson', () {
    test('parses all fields from a well-formed entry', () {
      final model = ForecastEntryModel.fromJson(json());

      expect(model.forecastForEpochSeconds, 1789560000);
      expect(model.temperatureCelsius, 29.99);
      expect(model.feelsLikeCelsius, 35.01);
      expect(model.humidityPercent, 70);
      expect(model.condition, WeatherCondition.rain);
      expect(model.description, 'light rain');
      expect(model.precipitationProbability, 1.0);
    });

    test('defaults precipitation probability to 0 when pop is absent', () {
      final model = ForecastEntryModel.fromJson(json(pop: null));

      expect(model.precipitationProbability, 0.0);
    });

    test('accepts an integer pop value', () {
      final model = ForecastEntryModel.fromJson(json(pop: 0));

      expect(model.precipitationProbability, 0.0);
    });

    test('maps an unrecognized weather group to unknown', () {
      final model = ForecastEntryModel.fromJson(json(weatherMain: 'Nonsense'));

      expect(model.condition, WeatherCondition.unknown);
    });
  });

  group('ForecastEntryModel.toEntity', () {
    test('maps to a ForecastEntry with the forecast time in UTC', () {
      final entity = ForecastEntryModel.fromJson(json()).toEntity();

      expect(
        entity,
        ForecastEntry(
          forecastFor: DateTime.fromMillisecondsSinceEpoch(
            1789560000 * 1000,
            isUtc: true,
          ),
          temperatureCelsius: 29.99,
          feelsLikeCelsius: 35.01,
          humidityPercent: 70,
          condition: WeatherCondition.rain,
          description: 'light rain',
          precipitationProbability: 1.0,
        ),
      );
    });
  });
}
