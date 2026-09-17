import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/data/models/weather_condition_mapper.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';

void main() {
  group('WeatherConditionMapper.fromOpenWeatherMain', () {
    final cases = <String, WeatherCondition>{
      'Clear': WeatherCondition.clear,
      'Clouds': WeatherCondition.clouds,
      'Rain': WeatherCondition.rain,
      'Drizzle': WeatherCondition.drizzle,
      'Thunderstorm': WeatherCondition.thunderstorm,
      'Snow': WeatherCondition.snow,
    };

    cases.forEach((main, expected) {
      test('maps "$main" to $expected', () {
        expect(WeatherConditionMapper.fromOpenWeatherMain(main), expected);
      });
    });

    const atmosphereGroups = [
      'Mist',
      'Smoke',
      'Haze',
      'Dust',
      'Fog',
      'Sand',
      'Ash',
      'Squall',
      'Tornado',
    ];

    for (final main in atmosphereGroups) {
      test('maps atmospheric group "$main" to atmosphere', () {
        expect(
          WeatherConditionMapper.fromOpenWeatherMain(main),
          WeatherCondition.atmosphere,
        );
      });
    }

    test('maps an unrecognized value to unknown', () {
      expect(
        WeatherConditionMapper.fromOpenWeatherMain('SomethingNew'),
        WeatherCondition.unknown,
      );
    });

    test('is case-sensitive and treats mismatched casing as unknown', () {
      expect(
        WeatherConditionMapper.fromOpenWeatherMain('clear'),
        WeatherCondition.unknown,
      );
    });
  });
}
