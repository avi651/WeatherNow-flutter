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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('perf', (tester) async {
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

    const cities = [
      CitySuggestion(
        name: 'Mumbai',
        state: 'MH',
        country: 'IN',
        latitude: 19.07,
        longitude: 72.87,
      ),
      CitySuggestion(
        name: 'Delhi',
        state: 'DL',
        country: 'IN',
        latitude: 28.6,
        longitude: 77.2,
      ),
      CitySuggestion(
        name: 'Bengaluru',
        state: 'KA',
        country: 'IN',
        latitude: 12.97,
        longitude: 77.59,
      ),
      CitySuggestion(
        name: 'Pune',
        state: 'MH',
        country: 'IN',
        latitude: 18.52,
        longitude: 73.85,
      ),
      CitySuggestion(
        name: 'Chennai',
        state: 'TN',
        country: 'IN',
        latitude: 13.08,
        longitude: 80.27,
      ),
      CitySuggestion(
        name: 'Kolkata',
        state: 'WB',
        country: 'IN',
        latitude: 22.57,
        longitude: 88.36,
      ),
      CitySuggestion(
        name: 'Hyderabad',
        state: 'TS',
        country: 'IN',
        latitude: 17.38,
        longitude: 78.48,
      ),
      CitySuggestion(
        name: 'Jaipur',
        state: 'RJ',
        country: 'IN',
        latitude: 26.9,
        longitude: 75.78,
      ),
    ];
    for (final c in cities) {
      await container.read(favoritesProvider.notifier).add(c);
    }
    await tester.pumpAndSettle();

    Future<void> scrollBoth(Finder f) async {
      for (var i = 0; i < 4; i++) {
        await tester.fling(f, const Offset(0, -400), 2000);
        await tester.pumpAndSettle();
        await tester.fling(f, const Offset(0, 400), 2000);
        await tester.pumpAndSettle();
      }
    }

    await binding.traceAction(() async {
      await scrollBoth(find.byType(SingleChildScrollView).first);
    }, reportKey: 'home_scroll');

    await binding.traceAction(() async {
      await tester.enterText(find.byType(TextField), 'mum');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
    }, reportKey: 'search_typing');

    await binding.traceAction(() async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.star_border),
        ),
      );
      await tester.pumpAndSettle();
      await scrollBoth(find.byType(ListView).first);
    }, reportKey: 'favorites_scroll');

    await binding.traceAction(() async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.settings_outlined),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fahrenheit (°F)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Celsius (°C)'));
      await tester.pumpAndSettle();
    }, reportKey: 'settings_unit_toggle');
  });
}
