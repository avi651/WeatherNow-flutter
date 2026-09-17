import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/presentation/widgets/weather_stats_row.dart';

void main() {
  final weather = CurrentWeather(
    temperatureCelsius: 27.6,
    feelsLikeCelsius: 31.0,
    humidityPercent: 68,
    pressureHpa: 1013,
    windSpeedMetersPerSecond: 3.4,
    condition: WeatherCondition.clouds,
    description: 'Partly Cloudy',
    observedAt: DateTime.utc(2026, 9, 16),
  );

  testWidgets('shows humidity, wind, and pressure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: WeatherStatsRow(weather: weather)),
    );

    expect(find.text('Humidity'), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);
    expect(find.text('Wind'), findsOneWidget);
    expect(find.text('3.4 m/s'), findsOneWidget);
    expect(find.text('Pressure'), findsOneWidget);
    expect(find.text('1013 hPa'), findsOneWidget);
  });

  testWidgets('uses Wrap so stats can reflow instead of overflowing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: WeatherStatsRow(weather: weather)),
    );

    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('lays out without overflow at an extremely narrow width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(240, 400));
    await tester.pumpWidget(
      MaterialApp(home: WeatherStatsRow(weather: weather)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });
}
