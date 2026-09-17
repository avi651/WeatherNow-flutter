import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/widgets/home_header.dart';

void main() {
  testWidgets('shows the app title, tagline, and a profile avatar',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeHeader()));

    expect(find.textContaining('Weather'), findsWidgets);
    expect(find.text('Know today. Plan better.'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('avatar is larger on a tablet-width screen than a phone-width one',
      (tester) async {
    // `tester.binding.setSurfaceSize` doesn't reliably propagate to
    // `MediaQuery` on this Flutter version — `tester.view.physicalSize` is
    // the framework's own recommended replacement and does.
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1.0;

    tester.view.physicalSize = const Size(320, 700);
    await tester.pumpWidget(const MaterialApp(home: HomeHeader()));
    final compactRadius =
        tester.widget<CircleAvatar>(find.byType(CircleAvatar)).radius;

    tester.view.physicalSize = const Size(1024, 700);
    await tester.pumpWidget(const MaterialApp(home: HomeHeader()));
    final expandedRadius =
        tester.widget<CircleAvatar>(find.byType(CircleAvatar)).radius;

    expect(expandedRadius, greaterThan(compactRadius!));
  });
}
