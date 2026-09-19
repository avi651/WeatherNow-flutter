import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/current_weather.dart';
import 'package:weather_now_flutter/domain/entities/weather_condition.dart';
import 'package:weather_now_flutter/presentation/widgets/current_weather_hero_card.dart';

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

  Widget buildSubject({bool isFavorite = false, VoidCallback? onToggle}) {
    return ProviderScope(
      child: MaterialApp(
        home: CurrentWeatherHeroCard(
          weather: weather,
          locationName: 'Bengaluru',
          country: 'India',
          isFavorite: isFavorite,
          onFavoriteToggle: onToggle ?? () {},
        ),
      ),
    );
  }

  testWidgets('shows location, temperature, condition, and feels-like',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Bengaluru'), findsOneWidget);
    expect(find.text('India'), findsOneWidget);
    expect(find.textContaining('28'), findsOneWidget); // 27.6 rounds to 28
    expect(find.text('Partly Cloudy'), findsOneWidget);
    expect(find.textContaining('31'), findsOneWidget); // feels like
  });

  testWidgets('reflects favorite state and calls onFavoriteToggle',
      (tester) async {
    var toggled = false;
    await tester.pumpWidget(buildSubject(onToggle: () => toggled = true));

    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border));

    expect(toggled, isTrue);
  });

  testWidgets('shows a filled star when favorite', (tester) async {
    await tester.pumpWidget(buildSubject(isFavorite: true));

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNothing);
  });

  testWidgets('uses more generous padding on a tablet-width screen',
      (tester) async {
    // `tester.binding.setSurfaceSize` doesn't reliably propagate to
    // `MediaQuery` on this Flutter version — `tester.view.physicalSize` is
    // the framework's own recommended replacement and does.
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1.0;

    tester.view.physicalSize = const Size(320, 700);
    await tester.pumpWidget(buildSubject());
    final compactPadding = tester
        .widget<Container>(find.byKey(const Key('currentWeatherHeroCard')))
        .padding as EdgeInsets;

    tester.view.physicalSize = const Size(1024, 700);
    await tester.pumpWidget(buildSubject());
    final expandedPadding = tester
        .widget<Container>(find.byKey(const Key('currentWeatherHeroCard')))
        .padding as EdgeInsets;

    expect(expandedPadding.left, greaterThan(compactPadding.left));
  });

  testWidgets('lays out without overflow at a very narrow width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 700));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'aligns the location pin icon with the city name, not floating between '
    'the name and the country line',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      final iconCenter = tester.getCenter(find.byIcon(Icons.location_on));
      final nameCenter = tester.getCenter(find.text('Bengaluru'));

      // The icon sits beside the city name on the same row, so their
      // vertical centers should line up closely — before the fix, the
      // icon was centered across both the name and country lines,
      // floating several pixels below the name's own center.
      expect((iconCenter.dy - nameCenter.dy).abs(), lessThan(3));
    },
  );
}
