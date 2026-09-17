import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_now_flutter/di/providers.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/domain/repositories/geocoding_repository.dart';
import 'package:weather_now_flutter/presentation/providers/city_search_provider.dart';
import 'package:weather_now_flutter/presentation/widgets/search/search_input_field.dart';

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

void main() {
  late MockGeocodingRepository mockRepository;
  late TextEditingController controller;
  late FocusNode focusNode;

  const results = [
    CitySuggestion(
      name: 'London',
      state: 'England',
      country: 'GB',
      latitude: 51.5072,
      longitude: -0.1276,
    ),
  ];

  setUp(() {
    mockRepository = MockGeocodingRepository();
    controller = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [geocodingRepositoryProvider.overrideWithValue(mockRepository)],
      child: MaterialApp(
        home: Scaffold(
          body: SearchInputField(
            controller: controller,
            focusNode: focusNode,
            debounceDuration: const Duration(milliseconds: 400),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the animated placeholder when empty', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Search Your City'), findsOneWidget);
  });

  testWidgets('hides the placeholder and shows a clear button once text is entered',
      (tester) async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right(results));

    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byKey(const Key('citySearchTextField')), 'Lon');
    await tester.pump();

    expect(find.text('Search Your City'), findsNothing);
    expect(find.byKey(const Key('citySearchClearButton')), findsOneWidget);
  });

  testWidgets('debounces search: does not search before the debounce interval elapses',
      (tester) async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right(results));

    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byKey(const Key('citySearchTextField')), 'Lon');
    await tester.pump(const Duration(milliseconds: 200));

    verifyNever(() => mockRepository.searchCities(query: any(named: 'query')));
  });

  testWidgets('debounces search: searches once the debounce interval elapses',
      (tester) async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right(results));

    final container = ProviderContainer(
      overrides: [geocodingRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SearchInputField(
              controller: controller,
              focusNode: focusNode,
              debounceDuration: const Duration(milliseconds: 400),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('citySearchTextField')), 'Lon');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    verify(() => mockRepository.searchCities(query: 'Lon')).called(1);
    expect(container.read(citySearchProvider).results, results);
  });

  testWidgets('cancels the previous debounce timer on each new keystroke', (tester) async {
    when(
      () => mockRepository.searchCities(query: any(named: 'query')),
    ).thenAnswer((_) async => const Right(results));

    await tester.pumpWidget(buildSubject());

    await tester.enterText(find.byKey(const Key('citySearchTextField')), 'L');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byKey(const Key('citySearchTextField')), 'Lo');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byKey(const Key('citySearchTextField')), 'Lon');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    verifyNever(() => mockRepository.searchCities(query: 'L'));
    verifyNever(() => mockRepository.searchCities(query: 'Lo'));
    verify(() => mockRepository.searchCities(query: 'Lon')).called(1);
  });

  testWidgets('tapping clear empties the field and clears search results',
      (tester) async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right(results));

    final container = ProviderContainer(
      overrides: [geocodingRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SearchInputField(
              controller: controller,
              focusNode: focusNode,
              debounceDuration: const Duration(milliseconds: 400),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('citySearchTextField')), 'Lon');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(container.read(citySearchProvider).results, results);

    await tester.tap(find.byKey(const Key('citySearchClearButton')));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(container.read(citySearchProvider).results, isEmpty);
    expect(find.text('Search Your City'), findsOneWidget);
  });

  testWidgets('submitting the field searches immediately without waiting for debounce',
      (tester) async {
    when(
      () => mockRepository.searchCities(query: 'Lon'),
    ).thenAnswer((_) async => const Right(results));

    final container = ProviderContainer(
      overrides: [geocodingRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SearchInputField(
              controller: controller,
              focusNode: focusNode,
              debounceDuration: const Duration(milliseconds: 400),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('citySearchTextField')), 'Lon');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    verify(() => mockRepository.searchCities(query: 'Lon')).called(1);
  });
}
