import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/presentation/utils/daily_forecast_aggregator.dart';
import 'package:weather_now_flutter/presentation/widgets/daily_forecast_strip.dart';

void main() {
  final today = DateTime.now().toUtc();
  final days = [
    DailyForecastSummary(
      date: DateTime.utc(today.year, today.month, today.day),
      minTemperatureCelsius: 22,
      maxTemperatureCelsius: 28,
      condition: WeatherCondition.clouds,
    ),
    DailyForecastSummary(
      date: DateTime.utc(today.year, today.month, today.day + 1),
      minTemperatureCelsius: 22,
      maxTemperatureCelsius: 30,
      condition: WeatherCondition.clear,
    ),
  ];

  testWidgets('labels the first day as Today and shows hi/lo for each day', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: DailyForecastStrip(days: days)));

    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('28'), findsOneWidget);
    expect(find.textContaining('30'), findsOneWidget);
  });

  testWidgets('renders nothing when there are no days', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DailyForecastStrip(days: [])),
    );

    expect(find.byType(DailyForecastStrip), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cards grow on a wider (tablet) screen than a narrow (small phone) one',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(
        MaterialApp(home: DailyForecastStrip(days: days)),
      );
      final compactHeight = tester
          .widget<SizedBox>(find.byKey(const Key('dailyForecastStripSize')))
          .height;

      await tester.binding.setSurfaceSize(const Size(1024, 700));
      await tester.pumpWidget(
        MaterialApp(home: DailyForecastStrip(days: days)),
      );
      final expandedHeight = tester
          .widget<SizedBox>(find.byKey(const Key('dailyForecastStripSize')))
          .height;

      expect(expandedHeight, greaterThan(compactHeight!));

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('lays out without overflow at a very narrow width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 700));
    await tester.pumpWidget(MaterialApp(home: DailyForecastStrip(days: days)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('lays out without overflow at a very wide (tablet) width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(MaterialApp(home: DailyForecastStrip(days: days)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });
}
