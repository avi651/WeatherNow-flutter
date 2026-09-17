import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/location_failures.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/repositories/geocoding_repository.dart';
import 'package:weather_now_flutter/presentation/providers/current_location_city_provider.dart';

class MockLocationService extends Mock implements LocationService {}

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

void main() {
  late MockLocationService mockLocationService;
  late MockGeocodingRepository mockGeocodingRepository;

  const deviceLocation = DeviceLocation(latitude: 18.5213738, longitude: 73.8545071);
  const pune = CitySuggestion(
    name: 'Pune',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 18.5213738,
    longitude: 73.8545071,
  );

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
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
  });

  test('resolves to the reverse-geocoded city for the device location', () async {
    when(() => mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => const Right(deviceLocation));
    when(
      () => mockGeocodingRepository.reverseGeocode(
        latitude: deviceLocation.latitude,
        longitude: deviceLocation.longitude,
      ),
    ).thenAnswer((_) async => const Right(pune));

    final container = buildContainer();

    final city = await container.read(currentLocationCityProvider.future);

    expect(city, pune);
  });

  test('resolves to null when reverse geocoding fails, without throwing', () async {
    when(() => mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => const Right(deviceLocation));
    when(
      () => mockGeocodingRepository.reverseGeocode(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Left(LocationUnavailableFailure('No match')));

    final container = buildContainer();

    final city = await container.read(currentLocationCityProvider.future);

    expect(city, isNull);
  });

  test('propagates a device-location failure as an AsyncError', () async {
    when(() => mockLocationService.getCurrentLocation()).thenAnswer(
      (_) async => const Left(
        LocationPermissionDeniedFailure('Location permission was denied.'),
      ),
    );

    final container = buildContainer();

    await expectLater(
      container.read(currentLocationCityProvider.future),
      throwsA(anything),
    );
  });
}
