import 'dart:convert';

import 'package:flutter/services.dart';

class WeatherMockDataSource {
  const WeatherMockDataSource();

  Future<Map<String, dynamic>> getCurrentWeather() async {
    final jsonString = await rootBundle.loadString(
      'assets/mock/current_weather.json',
    );

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getForecast() async {
    final jsonString = await rootBundle.loadString('assets/mock/forecast.json');

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
