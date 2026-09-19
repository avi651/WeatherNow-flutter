import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/widgets/offline_banner.dart';

void main() {
  testWidgets('shows an offline message and the formatted cached time', (
    tester,
  ) async {
    final fetchedAt = DateTime(2026, 9, 18, 15, 45);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OfflineBanner(fetchedAt: fetchedAt)),
      ),
    );

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.textContaining("You're offline"), findsOneWidget);
    expect(find.textContaining('3:45'), findsOneWidget);
  });
}
