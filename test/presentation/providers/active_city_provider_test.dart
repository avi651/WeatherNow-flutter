import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../utils/location_test_overrides.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/repositories/geocoding_repository.dart';
import 'package:weather_now_flutter/presentation/providers/active_city_provider.dart';
import 'package:weather_now_flutter/presentation/providers/current_location_city_provider.dart';
import 'package:weather_now_flutter/presentation/providers/selected_city_provider.dart';

class MockLocationService extends Mock implements LocationService {}

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

void main() {
  late MockLocationService mockLocationService;
  late MockGeocodingRepository mockGeocodingRepository;

  const deviceLocation = DeviceLocation(
    latitude: 18.5213738,
    longitude: 73.8545071,
  );
  const pune = CitySuggestion(
    name: 'Pune',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 18.5213738,
    longitude: 73.8545071,
  );
  const london = CitySuggestion(
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
        geocodingRepositoryProvider.overrideWithValue(mockGeocodingRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    mockLocationService = MockLocationService();
    mockGeocodingRepository = MockGeocodingRepository();
    when(
      () => mockLocationService.getCurrentLocation(),
    ).thenAnswer((_) async => const Right(deviceLocation));
    when(
      () => mockGeocodingRepository.reverseGeocode(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(pune));
  });

  test('is null before the device location has resolved', () {
    final container = buildContainer();

    expect(container.read(activeCityProvider), isNull);
  });

  test(
    'resolves to the reverse-geocoded device-location city once available',
    () async {
      final container = buildContainer();

      await container.read(currentLocationCityProvider.future);

      expect(container.read(activeCityProvider), pune);
    },
  );

  test(
    'prefers the explicitly selected city over the device location',
    () async {
      final container = buildContainer();
      await container.read(currentLocationCityProvider.future);
      container.read(selectedCityProvider.notifier).select(london);

      expect(container.read(activeCityProvider), london);
    },
  );

  test(
    'falls back to the device-location city after reverting from a selection',
    () async {
      final container = buildContainer();
      await container.read(currentLocationCityProvider.future);
      container.read(selectedCityProvider.notifier).select(london);
      container.read(selectedCityProvider.notifier).useDeviceLocation();

      expect(container.read(activeCityProvider), pune);
    },
  );
}
