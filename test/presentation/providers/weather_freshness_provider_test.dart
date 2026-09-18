import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/providers/weather_freshness_provider.dart';

void main() {
  for (final provider in [
    currentWeatherFreshnessProvider,
    forecastFreshnessProvider,
  ]) {
    group(provider == currentWeatherFreshnessProvider
        ? 'currentWeatherFreshnessProvider'
        : 'forecastFreshnessProvider', () {
      test('starts null before any fetch has resolved', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(provider), isNull);
      });

      test('report updates the state with the given freshness', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final fetchedAt = DateTime.utc(2026, 9, 18);

        container
            .read(provider.notifier)
            .report(WeatherFreshness(isFromCache: true, fetchedAt: fetchedAt));

        final state = container.read(provider);
        expect(state!.isFromCache, isTrue);
        expect(state.fetchedAt, fetchedAt);
      });

      test('a later report replaces the earlier one', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(provider.notifier).report(
              WeatherFreshness(isFromCache: true, fetchedAt: DateTime.utc(2026, 9, 17)),
            );
        container.read(provider.notifier).report(
              WeatherFreshness(isFromCache: false, fetchedAt: DateTime.utc(2026, 9, 18)),
            );

        expect(container.read(provider)!.isFromCache, isFalse);
      });
    });
  }

  test(
    'the current-weather and forecast freshness providers are independent — '
    'reporting one does not affect the other',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentWeatherFreshnessProvider.notifier).report(
            WeatherFreshness(isFromCache: true, fetchedAt: DateTime.utc(2026, 9, 17)),
          );
      container.read(forecastFreshnessProvider.notifier).report(
            WeatherFreshness(isFromCache: false, fetchedAt: DateTime.utc(2026, 9, 18)),
          );

      expect(container.read(currentWeatherFreshnessProvider)!.isFromCache, isTrue);
      expect(container.read(forecastFreshnessProvider)!.isFromCache, isFalse);
    },
  );
}
