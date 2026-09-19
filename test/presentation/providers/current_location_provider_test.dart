import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../utils/location_test_overrides.dart';
import 'package:weather_now_flutter/core/error/location_failures.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/presentation/providers/current_location_provider.dart';
import 'package:weather_now_flutter/presentation/providers/home_weather_exception.dart';

class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockLocationService mockLocationService;

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
  });

  test('resolves to the device location on success', () async {
    const location = DeviceLocation(latitude: 12.9716, longitude: 77.5946);
    when(
      () => mockLocationService.getCurrentLocation(),
    ).thenAnswer((_) async => const Right(location));

    final container = buildContainer();

    expect(await container.read(currentLocationProvider.future), location);
  });

  test(
    'throws HomeWeatherFailureException carrying the failure message on error',
    () async {
      when(() => mockLocationService.getCurrentLocation()).thenAnswer(
        (_) async => const Left(
          LocationPermissionDeniedFailure('Location permission was denied.'),
        ),
      );

      final container = buildContainer();

      await expectLater(
        container.read(currentLocationProvider.future),
        throwsA(
          isA<HomeWeatherFailureException>().having(
            (e) => e.message,
            'message',
            'Location permission was denied.',
          ),
        ),
      );
    },
  );
}
