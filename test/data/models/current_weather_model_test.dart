import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/data/models/current_weather_model.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

void main() {
  // Shaped exactly like OpenWeatherMap's current-weather endpoint response.
  Map<String, dynamic> json({
    double temp = 29.99,
    double feelsLike = 35.01,
    int humidity = 70,
    int pressure = 1010,
    double windSpeed = 4.63,
    String weatherMain = 'Rain',
    String description = 'light rain',
    int dt = 1789558849,
  }) {
    return {
      'coord': {'lon': 72.8479, 'lat': 19.0144},
      'weather': [
        {
          'id': 500,
          'main': weatherMain,
          'description': description,
          'icon': '10d',
        },
      ],
      'base': 'stations',
      'main': {
        'temp': temp,
        'feels_like': feelsLike,
        'temp_min': 29.94,
        'temp_max': 29.99,
        'pressure': pressure,
        'humidity': humidity,
        'sea_level': 1010,
        'grnd_level': 1009,
      },
      'visibility': 10000,
      'wind': {'speed': windSpeed, 'deg': 270},
      'clouds': {'all': 4},
      'dt': dt,
      'sys': {
        'type': 1,
        'id': 9052,
        'country': 'IN',
        'sunrise': 1,
        'sunset': 2,
      },
      'timezone': 19800,
      'id': 1275339,
      'name': 'Mumbai',
      'cod': 200,
    };
  }

  group('CurrentWeatherModel.fromJson', () {
    test('parses all fields from a well-formed response', () {
      final model = CurrentWeatherModel.fromJson(json());

      expect(model.temperatureCelsius, 29.99);
      expect(model.feelsLikeCelsius, 35.01);
      expect(model.humidityPercent, 70);
      expect(model.pressureHpa, 1010);
      expect(model.windSpeedMetersPerSecond, 4.63);
      expect(model.condition, WeatherCondition.rain);
      expect(model.description, 'light rain');
      expect(model.observedAtEpochSeconds, 1789558849);
    });

    test('accepts integer temperature values (no decimal point)', () {
      final model = CurrentWeatherModel.fromJson(json(temp: 30, feelsLike: 30));

      expect(model.temperatureCelsius, 30.0);
      expect(model.feelsLikeCelsius, 30.0);
    });

    test('defaults wind speed to 0 when the wind block is absent', () {
      final withoutWind = json()..remove('wind');

      final model = CurrentWeatherModel.fromJson(withoutWind);

      expect(model.windSpeedMetersPerSecond, 0);
    });

    test('maps an unrecognized weather group to unknown', () {
      final model = CurrentWeatherModel.fromJson(json(weatherMain: 'Nonsense'));

      expect(model.condition, WeatherCondition.unknown);
    });

    test('two models parsed from identical JSON are equal', () {
      expect(
        CurrentWeatherModel.fromJson(json()),
        CurrentWeatherModel.fromJson(json()),
      );
    });

    test('models parsed from different JSON are not equal', () {
      expect(
        CurrentWeatherModel.fromJson(json(temp: 20)),
        isNot(CurrentWeatherModel.fromJson(json(temp: 25))),
      );
    });
  });

  group('CurrentWeatherModel.toEntity', () {
    test('maps to a CurrentWeather with the observation time in UTC', () {
      final entity = CurrentWeatherModel.fromJson(json()).toEntity();

      expect(
        entity,
        CurrentWeather(
          temperatureCelsius: 29.99,
          feelsLikeCelsius: 35.01,
          humidityPercent: 70,
          pressureHpa: 1010,
          windSpeedMetersPerSecond: 4.63,
          condition: WeatherCondition.rain,
          description: 'light rain',
          observedAt: DateTime.fromMillisecondsSinceEpoch(
            1789558849 * 1000,
            isUtc: true,
          ),
        ),
      );
    });

    test('round-trips the epoch seconds into an equivalent UTC instant', () {
      final entity = CurrentWeatherModel.fromJson(json(dt: 1000)).toEntity();

      expect(entity.observedAt.isUtc, isTrue);
      expect(entity.observedAt.millisecondsSinceEpoch, 1000 * 1000);
    });
  });
}
