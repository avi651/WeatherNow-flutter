import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../utils/location_test_overrides.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/presentation/providers/active_location_provider.dart';
import 'package:weather_now_flutter/presentation/providers/selected_city_provider.dart';

class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockLocationService mockLocationService;

  const deviceLocation = DeviceLocation(latitude: 12.9716, longitude: 77.5946);
  const city = CitySuggestion(
    name: 'London',
    state: 'England',
    country: 'GB',
    latitude: 51.5072,
    longitude: -0.1276,
  );

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        ...locationTestOverrides(),
        locationServiceProvider.overrideWithValue(mockLocationService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    mockLocationService = MockLocationService();
    when(
      () => mockLocationService.getCurrentLocation(),
    ).thenAnswer((_) async => const Right(deviceLocation));
  });

  test('resolves to the device location when no city is selected', () async {
    final container = buildContainer();

    final location = await container.read(activeLocationProvider.future);

    expect(location, deviceLocation);
    verify(() => mockLocationService.getCurrentLocation()).called(1);
  });

  test(
    'resolves to the selected city, without touching the location service',
    () async {
      final container = buildContainer();
      container.read(selectedCityProvider.notifier).select(city);

      final location = await container.read(activeLocationProvider.future);

      expect(
        location,
        const DeviceLocation(latitude: 51.5072, longitude: -0.1276),
      );
      verifyNever(() => mockLocationService.getCurrentLocation());
    },
  );

  test(
    'falls back to the device location after useDeviceLocation is called',
    () async {
      final container = buildContainer();
      container.read(selectedCityProvider.notifier).select(city);
      container.read(selectedCityProvider.notifier).useDeviceLocation();

      final location = await container.read(activeLocationProvider.future);

      expect(location, deviceLocation);
    },
  );
}
