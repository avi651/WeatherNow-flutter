import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/widgets/weather_loading_view.dart';

void main() {
  testWidgets('shows a progress indicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WeatherLoadingView()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
