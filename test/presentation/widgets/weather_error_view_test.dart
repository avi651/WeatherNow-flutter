import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/widgets/weather_error_view.dart';

void main() {
  testWidgets('shows the error message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WeatherErrorView(message: 'No connection', onRetry: () {}),
      ),
    );

    expect(find.text('No connection'), findsOneWidget);
  });

  testWidgets('calls onRetry when the retry button is tapped', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: WeatherErrorView(
          message: 'No connection',
          onRetry: () => retried = true,
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
