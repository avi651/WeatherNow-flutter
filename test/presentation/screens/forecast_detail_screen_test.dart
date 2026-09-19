import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/forecast_entry.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/presentation/screens/forecast_detail_screen.dart';
import 'package:weather_now_flutter/presentation/utils/daily_forecast_aggregator.dart';
import 'package:weather_now_flutter/presentation/widgets/daily_forecast_strip.dart';

ForecastEntry _entry(int day, int hour, double temp) => ForecastEntry(
  forecastFor: DateTime.utc(2026, 9, day, hour),
  temperatureCelsius: temp,
  feelsLikeCelsius: temp,
  humidityPercent: 50,
  condition: WeatherCondition.clear,
  description: 'clear sky',
  precipitationProbability: 0.1,
);

void main() {
  final days = DailyForecastAggregator.aggregate([
    _entry(16, 6, 14),
    _entry(16, 12, 26),
    _entry(16, 18, 20),
    _entry(17, 12, 30),
  ]);

  testWidgets('tapping a day card opens its detail screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyForecastStrip(days: days, locationName: 'Paris'),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('dayCard_Today')));
    await tester.pumpAndSettle();

    expect(find.byType(ForecastDetailScreen), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
    expect(find.byKey(const Key('periodCard_morning')), findsOneWidget);
    expect(find.byKey(const Key('periodCard_afternoon')), findsOneWidget);
    expect(find.byKey(const Key('periodCard_evening')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ForecastDetailScreen), findsNothing);
  });

  testWidgets('omits periods with no data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ForecastDetailScreen(summary: days[1], label: 'Thu'),
      ),
    );

    expect(find.byKey(const Key('periodCard_afternoon')), findsOneWidget);
    expect(find.byKey(const Key('periodCard_morning')), findsNothing);
  });
}
