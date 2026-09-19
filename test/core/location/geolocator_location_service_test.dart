import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';
import 'package:weather_now_flutter/core/error/failures.dart';
import 'package:weather_now_flutter/core/error/location_failures.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/geolocator_client.dart';
import 'package:weather_now_flutter/core/location/geolocator_location_service.dart';
import 'package:weather_now_flutter/core/location/location_permission_status.dart';

class MockGeolocatorClient extends Mock implements GeolocatorClient {}

void main() {
  late MockGeolocatorClient client;
  late GeolocatorLocationService service;

  const pune = DeviceLocation(latitude: 18.5213738, longitude: 73.8545071);

  setUpAll(() => registerFallbackValue(Duration.zero));

  setUp(() {
    client = MockGeolocatorClient();
    service = GeolocatorLocationService(client: client);

    when(() => client.isLocationServiceEnabled()).thenAnswer((_) async => true);
    when(
      () => client.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.whileInUse);
    when(
      () => client.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
    ).thenAnswer((_) async => pune);
  });

  Failure failureOf(dynamic either) =>
      (either as dynamic).fold((f) => f as Failure, (_) => throw 'not a Left');

  group('getCurrentLocation', () {
    test('returns the device location on success', () async {
      final result = await service.getCurrentLocation();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => throw 'unexpected'), pune);
    });

    test('asks the platform for a position with the 15 second limit', () async {
      await service.getCurrentLocation();

      expect(
        GeolocatorLocationService.positionTimeout,
        const Duration(seconds: 15),
      );
      verify(
        () => client.getCurrentLocation(timeLimit: const Duration(seconds: 15)),
      ).called(1);
    });

    test('does not request permission when it is already granted', () async {
      await service.getCurrentLocation();

      verifyNever(() => client.requestPermission());
    });

    test('returns LocationServiceDisabledFailure when services are off, '
        'without checking permission or reading a position', () async {
      when(
        () => client.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);

      final failure = failureOf(await service.getCurrentLocation());

      expect(failure, isA<LocationServiceDisabledFailure>());
      expect(failure.message, AppStrings.locationServicesDisabled);
      verifyNever(() => client.checkPermission());
      verifyNever(
        () => client.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
      );
    });

    group('permission', () {
      test('is requested when denied, and a grant proceeds to a fix', () async {
        when(
          () => client.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);
        when(
          () => client.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);

        final result = await service.getCurrentLocation();

        expect(result.getOrElse(() => throw 'unexpected'), pune);
        verify(() => client.requestPermission()).called(1);
      });

      test('returns LocationPermissionDeniedFailure when the request is '
          'denied, without reading a position', () async {
        when(
          () => client.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);
        when(
          () => client.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);

        final failure = failureOf(await service.getCurrentLocation());

        expect(failure, isA<LocationPermissionDeniedFailure>());
        expect(failure.message, AppStrings.locationPermissionDenied);
        verifyNever(
          () => client.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
        );
      });

      test('returns LocationPermissionDeniedForeverFailure when permanently '
          'denied, without prompting again', () async {
        when(
          () => client.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.deniedForever);

        final failure = failureOf(await service.getCurrentLocation());

        expect(failure, isA<LocationPermissionDeniedForeverFailure>());
        expect(failure.message, AppStrings.locationPermissionDeniedForever);
        verifyNever(() => client.requestPermission());
      });

      test('a request that ends in deniedForever maps to '
          'LocationPermissionDeniedForeverFailure', () async {
        when(
          () => client.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);
        when(
          () => client.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.deniedForever);

        final failure = failureOf(await service.getCurrentLocation());

        expect(failure, isA<LocationPermissionDeniedForeverFailure>());
      });
    });

    group('timeout', () {
      testWidgets('a position that never arrives fails with '
          'LocationUnavailableFailure(locationTimedOut) after 15 seconds, '
          'and not before', (tester) async {
        when(
          () => client.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
        ).thenAnswer((_) => Completer<DeviceLocation>().future);

        Failure? failure;
        var completed = false;
        service.getCurrentLocation().then((result) {
          completed = true;
          failure = failureOf(result);
        });

        await tester.pump(const Duration(seconds: 14, milliseconds: 900));
        expect(completed, isFalse);

        await tester.pump(const Duration(milliseconds: 200));
        expect(completed, isTrue);
        expect(failure, isA<LocationUnavailableFailure>());
        expect(failure!.message, AppStrings.locationTimedOut);
      });

      test('a TimeoutException from the platform maps to the same '
          'timed-out failure', () async {
        when(
          () => client.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
        ).thenThrow(TimeoutException('platform gave up'));

        final failure = failureOf(await service.getCurrentLocation());

        expect(failure, isA<LocationUnavailableFailure>());
        expect(failure.message, AppStrings.locationTimedOut);
      });
    });

    group('unexpected errors', () {
      test('map to LocationUnavailableFailure with a generic message that '
          'does not leak the technical error', () async {
        when(
          () => client.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
        ).thenThrow(StateError('secret platform detail'));

        final failure = failureOf(await service.getCurrentLocation());

        expect(failure, isA<LocationUnavailableFailure>());
        expect(failure.message, AppStrings.locationUnavailable);
        expect(failure.message, isNot(contains('secret platform detail')));
      });

      test(
        'an asynchronous error from the platform maps the same way',
        () async {
          when(
            () => client.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
          ).thenAnswer(
            (_) => Future.error(const LocationServiceDisabledException()),
          );

          final failure = failureOf(await service.getCurrentLocation());

          expect(failure, isA<LocationUnavailableFailure>());
          expect(failure.message, AppStrings.locationUnavailable);
        },
      );

      test('an error while checking permission is not swallowed (it sits '
          'outside the position try/catch)', () async {
        when(() => client.checkPermission()).thenThrow(StateError('boom'));

        await expectLater(service.getCurrentLocation(), throwsStateError);
      });
    });
  });

  group('checkPermissionStatus', () {
    test('reports serviceDisabled when location services are off', () async {
      when(
        () => client.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);

      expect(
        await service.checkPermissionStatus(),
        LocationPermissionStatus.serviceDisabled,
      );
    });

    for (final (permission, expected) in [
      (LocationPermission.always, LocationPermissionStatus.granted),
      (LocationPermission.whileInUse, LocationPermissionStatus.granted),
      (LocationPermission.denied, LocationPermissionStatus.denied),
      (LocationPermission.unableToDetermine, LocationPermissionStatus.denied),
      (
        LocationPermission.deniedForever,
        LocationPermissionStatus.deniedForever,
      ),
    ]) {
      test('maps $permission to $expected', () async {
        when(
          () => client.checkPermission(),
        ).thenAnswer((_) async => permission);

        expect(await service.checkPermissionStatus(), expected);
      });
    }
  });

  group('requestPermission', () {
    test(
      'requests only when currently denied and returns the outcome',
      () async {
        when(
          () => client.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);
        when(
          () => client.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.always);

        expect(
          await service.requestPermission(),
          LocationPermissionStatus.granted,
        );
        verify(() => client.requestPermission()).called(1);
      },
    );

    test('does not prompt when already granted', () async {
      expect(
        await service.requestPermission(),
        LocationPermissionStatus.granted,
      );
      verifyNever(() => client.requestPermission());
    });

    test(
      'reports serviceDisabled without prompting when services are off',
      () async {
        when(
          () => client.isLocationServiceEnabled(),
        ).thenAnswer((_) async => false);

        expect(
          await service.requestPermission(),
          LocationPermissionStatus.serviceDisabled,
        );
        verifyNever(() => client.requestPermission());
      },
    );
  });

  group('settings shortcuts', () {
    test('delegate to the client', () async {
      when(() => client.openLocationSettings()).thenAnswer((_) async {});
      when(() => client.openAppSettings()).thenAnswer((_) async {});

      await service.openLocationSettings();
      await service.openAppSettings();

      verify(() => client.openLocationSettings()).called(1);
      verify(() => client.openAppSettings()).called(1);
    });
  });
}
