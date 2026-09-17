import '../../domain/entities/weather_condition.dart';

/// Maps OpenWeatherMap's weather group string (the `weather[0].main` value
/// shared by both the current-weather and forecast responses) onto the
/// provider-agnostic [WeatherCondition] enum.
class WeatherConditionMapper {
  const WeatherConditionMapper._();

  static const _atmosphereGroups = {
    'Mist',
    'Smoke',
    'Haze',
    'Dust',
    'Fog',
    'Sand',
    'Ash',
    'Squall',
    'Tornado',
  };

  static WeatherCondition fromOpenWeatherMain(String main) {
    switch (main) {
      case 'Clear':
        return WeatherCondition.clear;
      case 'Clouds':
        return WeatherCondition.clouds;
      case 'Rain':
        return WeatherCondition.rain;
      case 'Drizzle':
        return WeatherCondition.drizzle;
      case 'Thunderstorm':
        return WeatherCondition.thunderstorm;
      case 'Snow':
        return WeatherCondition.snow;
      default:
        return _atmosphereGroups.contains(main)
            ? WeatherCondition.atmosphere
            : WeatherCondition.unknown;
    }
  }
}
