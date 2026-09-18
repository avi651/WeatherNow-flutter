import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/data/local/location_cache_key.dart';

void main() {
  test('formats latitude and longitude to 4 decimal places', () {
    expect(
      LocationCacheKey.of(latitude: 18.5213738, longitude: 73.8545071),
      '18.5214,73.8545',
    );
  });

  test('the same coordinates always produce the same key', () {
    final a = LocationCacheKey.of(latitude: 12.34, longitude: 56.78);
    final b = LocationCacheKey.of(latitude: 12.34, longitude: 56.78);

    expect(a, b);
  });

  test('tiny GPS jitter within 4 decimal places lands on the same key', () {
    final a = LocationCacheKey.of(latitude: 18.52137, longitude: 73.85450);
    final b = LocationCacheKey.of(latitude: 18.52138, longitude: 73.85451);

    expect(a, b);
  });

  test('different locations produce different keys', () {
    final a = LocationCacheKey.of(latitude: 18.5213738, longitude: 73.8545071);
    final b = LocationCacheKey.of(latitude: 51.5072, longitude: -0.1276);

    expect(a, isNot(b));
  });
}
