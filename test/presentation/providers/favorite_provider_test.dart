import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/providers/favorite_provider.dart';

void main() {
  test('starts as not favorite', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(isFavoriteProvider), isFalse);
  });

  test('toggle flips the value each time it is called', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(isFavoriteProvider.notifier).toggle();
    expect(container.read(isFavoriteProvider), isTrue);

    container.read(isFavoriteProvider.notifier).toggle();
    expect(container.read(isFavoriteProvider), isFalse);
  });
}
