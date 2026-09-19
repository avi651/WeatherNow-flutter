import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:weather_now_flutter/app/app.dart';
import 'package:weather_now_flutter/core/error/failures.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_permission_status.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/data/local/hive_boxes.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/presentation/providers/favorite_provider.dart';

class FakeLocation implements LocationService {
  @override
  Future<Either<Failure, DeviceLocation>> getCurrentLocation() async =>
      const Right(DeviceLocation(latitude: 19.07, longitude: 72.87));
  @override
  Future<LocationPermissionStatus> checkPermissionStatus() async =>
      LocationPermissionStatus.granted;
  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      LocationPermissionStatus.granted;
  @override
  Future<void> openLocationSettings() async {}
  @override
  Future<void> openAppSettings() async {}
}


Future<void> hold(WidgetTester t, [int ms = 1500]) async {
  await t.pump();
  await Future<void>.delayed(Duration(milliseconds: ms));
  await t.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('record locate me', (tester) async {
    await Hive.initFlutter();
    await HiveBoxes.openAll();
    await HiveBoxes.clearAll();
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(FakeLocation())],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await hold(tester, 2500);

    await tester.enterText(find.byType(TextField).first, 'Delhi');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await hold(tester, 2000);
    final tiles = find.byType(ListTile);
    if (tiles.evaluate().isNotEmpty) {
      await tester.tap(tiles.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    await hold(tester, 2500);

    await tester.tap(find.byKey(const Key('useMyLocationButton')));
    await hold(tester, 400);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await hold(tester, 3000);
  });
}
