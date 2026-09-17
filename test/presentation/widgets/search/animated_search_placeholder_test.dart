import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/widgets/search/animated_search_placeholder.dart';

void main() {
  const phrases = ['Search Your City', 'Search Mumbai', 'Search London'];

  testWidgets('shows the first phrase initially', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedSearchPlaceholder(
          phrases: phrases,
          interval: Duration(seconds: 2),
        ),
      ),
    );

    expect(find.text('Search Your City'), findsOneWidget);
  });

  testWidgets('cycles to the next phrase after the interval elapses', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedSearchPlaceholder(
          phrases: phrases,
          interval: Duration(seconds: 2),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    // The widget's AnimatedSwitcher cross-fade/slide runs for 600ms.
    await tester.pump(const Duration(milliseconds: 650));

    expect(find.text('Search Mumbai'), findsOneWidget);
    expect(find.text('Search Your City'), findsNothing);
  });

  testWidgets('wraps back to the first phrase after cycling through all of them',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedSearchPlaceholder(
          phrases: phrases,
          interval: Duration(seconds: 2),
        ),
      ),
    );

    for (var i = 0; i < phrases.length; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 650));
    }

    expect(find.text('Search Your City'), findsOneWidget);
  });

  testWidgets('cancels its timer on dispose (no pending-timer failure)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedSearchPlaceholder(
          phrases: phrases,
          interval: Duration(seconds: 2),
        ),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    // If the timer weren't cancelled in dispose(), flutter_test would fail
    // this test with "A Timer is still pending" once it tears down.
  });

  testWidgets('renders nothing for an empty phrase list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AnimatedSearchPlaceholder(phrases: [])),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('does not animate when there is only one phrase', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedSearchPlaceholder(
          phrases: ['Search Your City'],
          interval: Duration(seconds: 2),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 10));

    expect(find.text('Search Your City'), findsOneWidget);
  });
}
