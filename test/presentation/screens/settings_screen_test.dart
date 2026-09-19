import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:weather_now_flutter/core/location/location_permission_status.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/app_settings.dart';
import 'package:weather_now_flutter/domain/entities/app_theme_mode.dart';
import 'package:weather_now_flutter/domain/entities/temperature_unit.dart';
import 'package:weather_now_flutter/domain/repositories/settings_repository.dart';
import 'package:weather_now_flutter/presentation/screens/settings_screen.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockSettingsRepository mockSettingsRepository;
  late MockLocationService mockLocationService;

  setUpAll(() {
    registerFallbackValue(TemperatureUnit.celsius);
    registerFallbackValue(AppThemeMode.system);
    PackageInfo.setMockInitialValues(
      appName: 'WeatherNow',
      packageName: 'com.example.weather_now_flutter',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    mockLocationService = MockLocationService();

    when(() => mockSettingsRepository.getSettings())
        .thenAnswer((_) async => const Right(AppSettings.defaults));
    when(() => mockSettingsRepository.saveTemperatureUnit(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => mockSettingsRepository.saveThemeMode(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => mockSettingsRepository.saveOfflineDataEnabled(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => mockLocationService.checkPermissionStatus())
        .thenAnswer((_) async => LocationPermissionStatus.granted);
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
        locationServiceProvider.overrideWithValue(mockLocationService),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  /// Pumps [buildSubject] at a surface tall enough that every section
  /// (including About, the last one) is visible without scrolling — the
  /// "responsive layout" tests set their own surface size instead, after
  /// calling this.
  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    await tester.pumpWidget(buildSubject());
  }

  testWidgets('shows every section', (tester) async {
    await pumpSubject(tester);
    await tester.pumpAndSettle();

    expect(find.text('Units'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Location & Permissions'), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Weather alerts'), findsNothing);
    expect(find.text('Offline Data'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  group('Units', () {
    testWidgets('defaults to Celsius selected', (tester) async {
      await pumpSubject(tester);
      await tester.pumpAndSettle();

      final segmented = tester.widget<SegmentedButton<TemperatureUnit>>(
        find.byKey(const Key('temperatureUnitSegmented')),
      );
      expect(segmented.selected, {TemperatureUnit.celsius});
    });

    testWidgets('selecting Fahrenheit persists it', (tester) async {
      await pumpSubject(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fahrenheit (°F)'));
      await tester.pumpAndSettle();

      verify(() => mockSettingsRepository.saveTemperatureUnit(TemperatureUnit.fahrenheit))
          .called(1);
      final segmented = tester.widget<SegmentedButton<TemperatureUnit>>(
        find.byKey(const Key('temperatureUnitSegmented')),
      );
      expect(segmented.selected, {TemperatureUnit.fahrenheit});
    });
  });

  group('Appearance', () {
    testWidgets('selecting Dark persists it', (tester) async {
      await pumpSubject(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      verify(() => mockSettingsRepository.saveThemeMode(AppThemeMode.dark)).called(1);
      final segmented = tester.widget<SegmentedButton<AppThemeMode>>(
        find.byKey(const Key('themeModeSegmented')),
      );
      expect(segmented.selected, {AppThemeMode.dark});
    });
  });

  group('Offline Data', () {
    testWidgets('defaults to enabled', (tester) async {
      await pumpSubject(tester);
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('offlineDataSwitch')),
      );
      expect(switchTile.value, isTrue);
    });

    testWidgets('toggling off persists it', (tester) async {
      await pumpSubject(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('offlineDataSwitch')));
      await tester.pumpAndSettle();

      verify(() => mockSettingsRepository.saveOfflineDataEnabled(false)).called(1);
    });
  });

  group('Location & Permissions', () {
    testWidgets('shows Allowed when permission is granted', (tester) async {
      await pumpSubject(tester);
      await tester.pumpAndSettle();

      expect(find.text('Allowed'), findsOneWidget);
    });

    testWidgets('shows a denied status and requests permission when tapped',
        (tester) async {
      when(() => mockLocationService.checkPermissionStatus())
          .thenAnswer((_) async => LocationPermissionStatus.denied);
      when(() => mockLocationService.requestPermission())
          .thenAnswer((_) async => LocationPermissionStatus.granted);

      await pumpSubject(tester);
      await tester.pumpAndSettle();

      expect(find.text('Not allowed yet'), findsOneWidget);

      await tester.tap(find.byKey(const Key('manageLocationPermissionButton')));
      await tester.pumpAndSettle();

      verify(() => mockLocationService.requestPermission()).called(1);
    });

    testWidgets(
      'opens the app settings screen when permanently denied',
      (tester) async {
        when(() => mockLocationService.checkPermissionStatus())
            .thenAnswer((_) async => LocationPermissionStatus.deniedForever);
        when(() => mockLocationService.openAppSettings()).thenAnswer((_) async {});

        await pumpSubject(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('manageLocationPermissionButton')));
        await tester.pumpAndSettle();

        verify(() => mockLocationService.openAppSettings()).called(1);
        verifyNever(() => mockLocationService.requestPermission());
      },
    );

    testWidgets(
      'opens the location-services screen when services are disabled',
      (tester) async {
        when(() => mockLocationService.checkPermissionStatus())
            .thenAnswer((_) async => LocationPermissionStatus.serviceDisabled);
        when(() => mockLocationService.openLocationSettings()).thenAnswer((_) async {});

        await pumpSubject(tester);
        await tester.pumpAndSettle();

        expect(find.text('Location services are off'), findsOneWidget);

        await tester.tap(find.byKey(const Key('manageLocationPermissionButton')));
        await tester.pumpAndSettle();

        verify(() => mockLocationService.openLocationSettings()).called(1);
      },
    );
  });

  group('About', () {
    testWidgets('shows the app version', (tester) async {
      await pumpSubject(tester);
      await tester.pumpAndSettle();

      expect(find.text('1.0.0 (1)'), findsOneWidget);
    });

    testWidgets('has no Terms, Privacy or Feedback entries', (tester) async {
      await pumpSubject(tester);
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsNothing);
      expect(find.text('Privacy Policy'), findsNothing);
      expect(find.text('Send Feedback'), findsNothing);
    });
  });

  group('bottom navigation', () {
    testWidgets('shows the bottom nav bar with Settings selected', (tester) async {
      await pumpSubject(tester);
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Settings'), findsNWidgets(2));
    });

    testWidgets('has no back button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
            locationServiceProvider.overrideWithValue(mockLocationService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('tapping Home in the bottom nav pops back', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
            locationServiceProvider.overrideWithValue(mockLocationService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: const Text('placeholder-home'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('placeholder-home'));
      await tester.pumpAndSettle();
      expect(find.text('Units'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('placeholder-home'), findsOneWidget);
    });
  });

  group('responsive layout', () {
    testWidgets('lays out without overflow on a small phone width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('caps content width on a tablet-width screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 900));
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.byKey(const Key('settingsContentConstraint')),
      );
      expect(constrainedBox.constraints.maxWidth, lessThan(1024));

      await tester.binding.setSurfaceSize(null);
    });
  });
}
