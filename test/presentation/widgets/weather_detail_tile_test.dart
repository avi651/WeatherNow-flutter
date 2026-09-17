import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/widgets/weather_detail_tile.dart';

void main() {
  testWidgets('shows the label and value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WeatherDetailTile(
          icon: Icons.water_drop,
          label: 'Humidity',
          value: '60%',
        ),
      ),
    );

    expect(find.text('Humidity'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.byIcon(Icons.water_drop), findsOneWidget);
  });
}
