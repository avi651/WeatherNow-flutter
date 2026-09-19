import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/widgets/home_header.dart';

void main() {
  testWidgets('shows the app title and tagline without a profile avatar', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeHeader()));

    expect(find.textContaining('Weather'), findsWidgets);
    expect(find.text('Know today. Plan better.'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
    expect(find.byType(CircleAvatar), findsNothing);
  });
}
