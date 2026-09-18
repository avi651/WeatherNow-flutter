import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/core/error/network_failures.dart';
import 'package:weather_now_flutter/core/location/device_location.dart';
import 'package:weather_now_flutter/core/location/location_service.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/repositories/geocoding_repository.dart';
import 'package:weather_now_flutter/presentation/providers/selected_city_provider.dart';
import 'package:weather_now_flutter/presentation/widgets/weather_search_bar.dart';

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockGeocodingRepository mockRepository;
  late MockLocationService mockLocationService;

  const london = CitySuggestion(
    name: 'London',
    state: 'England',
    country: 'GB',
    latitude: 51.5072,
    longitude: -0.1276,
  );

  const deviceLocation = DeviceLocation(latitude: 18.5213738, longitude: 73.8545071);
  const pune = CitySuggestion(
    name: 'Pune',
    state: 'Maharashtra',
    country: 'IN',
    latitude: 18.5213738,
    longitude: 73.8545071,
  );

  setUp(() {
    mockRepository = MockGeocodingRepository();
    mockLocationService = MockLocationService();
    when(() => mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => const Right(deviceLocation));
    when(
      () => mockRepository.reverseGeocode(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => const Right(pune));
  });

  Widget buildSubject({required ProviderContainer container}) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: WeatherSearchBar())),
    );
  }

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        geocodingRepositoryProvider.overrideWithValue(mockRepository),
        locationServiceProvider.overrideWithValue(mockLocationService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> searchAndSettle(WidgetTester tester, String query) async {
    await tester.tap(find.byKey(const Key('citySearchTextField')));
    await tester.enterText(find.byKey(const Key('citySearchTextField')), query);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  testWidgets('shows the search icon, the input, and a use-my-location button',
      (tester) async {
    await tester.pumpWidget(buildSubject(container: buildContainer()));

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byKey(const Key('citySearchTextField')), findsOneWidget);
  });

  testWidgets('does not show suggestions before the field is focused', (tester) async {
    await tester.pumpWidget(buildSubject(container: buildContainer()));

    expect(find.byKey(const Key('citySuggestionsList')), findsNothing);
  });

  testWidgets('shows matching suggestions once the debounced search resolves',
      (tester) async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right([london]));

    await tester.pumpWidget(buildSubject(container: buildContainer()));
    await searchAndSettle(tester, 'Lon');

    expect(find.text(london.displayLabel), findsOneWidget);
  });

  testWidgets('shows an error message when the search fails', (tester) async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Left(NetworkFailure('No connection')));

    await tester.pumpWidget(buildSubject(container: buildContainer()));
    await searchAndSettle(tester, 'Lon');

    expect(find.text('No connection'), findsOneWidget);
  });

  testWidgets('shows an empty-results message when nothing matches', (tester) async {
    when(
      () => mockRepository.searchCities(query: 'Zzznotacity'),
    ).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(buildSubject(container: buildContainer()));
    await searchAndSettle(tester, 'Zzznotacity');

    expect(find.text('No cities found for "Zzznotacity"'), findsOneWidget);
  });

  testWidgets(
    'selecting a suggestion updates selectedCityProvider, keeps its name '
    'visible in the field, hides suggestions, and dismisses the keyboard',
    (tester) async {
      when(
        () => mockRepository.searchCities(query: 'Lon'),
      ).thenAnswer((_) async => const Right([london]));

      final container = buildContainer();
      await tester.pumpWidget(buildSubject(container: container));
      await searchAndSettle(tester, 'Lon');

      await tester.tap(find.text(london.displayLabel));
      await tester.pump();

      expect(container.read(selectedCityProvider), london);

      final textField = tester.widget<TextField>(
        find.byKey(const Key('citySearchTextField')),
      );
      expect(textField.controller!.text, 'London');
      expect(find.byKey(const Key('citySuggestionsList')), findsNothing);
      expect(textField.focusNode!.hasFocus, isFalse);
    },
  );

  testWidgets(
    'the selected city name survives a rebuild instead of reverting to the '
    'device location',
    (tester) async {
      when(
        () => mockRepository.searchCities(query: 'Mum'),
      ).thenAnswer(
        (_) async => const Right([
          CitySuggestion(
            name: 'Mumbai',
            state: 'Maharashtra',
            country: 'IN',
            latitude: 19.0760,
            longitude: 72.8777,
          ),
        ]),
      );

      final container = buildContainer();
      await tester.pumpWidget(buildSubject(container: container));
      // Let the device-location reverse-geocode ("Pune") resolve first, so
      // a stale overwrite would be observable.
      await tester.pumpAndSettle();

      await searchAndSettle(tester, 'Mum');
      await tester.tap(find.text('Mumbai, Maharashtra, IN'));
      await tester.pump();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('citySearchTextField')),
      );
      expect(textField.controller!.text, 'Mumbai');

      // A late, in-flight resolution of the device location must not
      // overwrite the manually selected city.
      await tester.pumpAndSettle();
      final textFieldAfter = tester.widget<TextField>(
        find.byKey(const Key('citySearchTextField')),
      );
      expect(textFieldAfter.controller!.text, 'Mumbai');
    },
  );

  testWidgets(
    'shows the already-selected city name in an empty field on first build',
    (tester) async {
      const delhi = CitySuggestion(
        name: 'Delhi',
        state: 'Delhi',
        country: 'IN',
        latitude: 28.7041,
        longitude: 77.1025,
      );

      final container = buildContainer();
      container.read(selectedCityProvider.notifier).select(delhi);

      await tester.pumpWidget(buildSubject(container: container));
      await tester.pump();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('citySearchTextField')),
      );
      expect(textField.controller!.text, 'Delhi');
    },
  );

  testWidgets(
    'tapping use-my-location resets selectedCityProvider to null and clears the field',
    (tester) async {
      when(
        () => mockRepository.searchCities(query: 'Lon'),
      ).thenAnswer((_) async => const Right([london]));

      final container = buildContainer();
      container.read(selectedCityProvider.notifier).select(london);

      await tester.pumpWidget(buildSubject(container: container));
      await searchAndSettle(tester, 'Lon');
      await tester.tap(find.text(london.displayLabel));
      await tester.pump();
      expect(container.read(selectedCityProvider), london);

      await tester.tap(find.byKey(const Key('useMyLocationButton')));
      await tester.pump();

      expect(container.read(selectedCityProvider), isNull);
    },
  );

  testWidgets(
    'shows the reverse-geocoded device-location city once resolved',
    (tester) async {
      final container = buildContainer();
      await tester.pumpWidget(buildSubject(container: container));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('citySearchTextField')),
      );
      expect(textField.controller!.text, 'Pune');
    },
  );

  testWidgets(
    'tapping the field clears the passive device-location label so a fresh '
    'search can start',
    (tester) async {
      final container = buildContainer();
      await tester.pumpWidget(buildSubject(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('citySearchTextField')));
      await tester.pump();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('citySearchTextField')),
      );
      expect(textField.controller!.text, isEmpty);
    },
  );

  testWidgets(
    'unfocusing without selecting a result restores the device-location label',
    (tester) async {
      final container = buildContainer();
      await tester.pumpWidget(buildSubject(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('citySearchTextField')));
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('citySearchTextField')),
      );
      expect(textField.controller!.text, 'Pune');
    },
  );

  testWidgets(
    'tapping use-my-location after selecting a city shows the '
    'device-location city, not a blank field',
    (tester) async {
      when(
        () => mockRepository.searchCities(query: 'Lon'),
      ).thenAnswer((_) async => const Right([london]));

      final container = buildContainer();
      await tester.pumpWidget(buildSubject(container: container));
      await tester.pumpAndSettle();

      await searchAndSettle(tester, 'Lon');
      await tester.tap(find.text(london.displayLabel));
      await tester.pump();

      await tester.tap(find.byKey(const Key('useMyLocationButton')));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('citySearchTextField')),
      );
      expect(textField.controller!.text, 'Pune');
    },
  );
}
