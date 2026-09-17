import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/widgets/favorite_star_button.dart';

void main() {
  testWidgets('shows an outlined star when not favorite', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FavoriteStarButton(isFavorite: false, onPressed: () {}),
      ),
    );

    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('shows a filled star when favorite', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FavoriteStarButton(isFavorite: true, onPressed: () {}),
      ),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNothing);
  });

  testWidgets('calls onPressed when tapped', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: FavoriteStarButton(
          isFavorite: false,
          onPressed: () => pressed = true,
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));

    expect(pressed, isTrue);
  });
}
