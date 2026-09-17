import 'dart:convert';

import 'package:flutter/services.dart';

import 'weather_data_source.dart';

class WeatherMockDataSource implements WeatherDataSource {
  const WeatherMockDataSource();

  /// [latitude] and [longitude] are accepted (but ignored) so this can be
  /// used interchangeably with [WeatherDataSource]'s other implementations
  /// — the bundled mock JSON isn't location-specific.
  @override
  Future<Map<String, dynamic>> getCurrentWeather({
    double? latitude,
    double? longitude,
  }) async {
    final jsonString = await rootBundle.loadString(
      'assets/mock/current_weather.json',
    );

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getForecast({
    double? latitude,
    double? longitude,
  }) async {
    final jsonString = await rootBundle.loadString('assets/mock/forecast.json');

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
