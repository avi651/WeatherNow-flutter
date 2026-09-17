import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/domain/entities/city_suggestion.dart';
import 'package:weather_now_flutter/presentation/providers/city_search_provider.dart';
import 'package:weather_now_flutter/presentation/widgets/search/city_suggestions_list.dart';

void main() {
  const london = CitySuggestion(
    name: 'London',
    state: 'England',
    country: 'GB',
    latitude: 51.5072,
    longitude: -0.1276,
  );
  const liverpool = CitySuggestion(
    name: 'Liverpool',
    state: 'England',
    country: 'GB',
    latitude: 53.4084,
    longitude: -2.9916,
  );

  Widget buildSubject(CitySearchState state, {ValueChanged<CitySuggestion>? onSelected}) {
    return MaterialApp(
      home: Scaffold(
        body: CitySuggestionsList(
          state: state,
          onSelected: onSelected ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renders nothing when there is no active query', (tester) async {
    await tester.pumpWidget(buildSubject(const CitySearchState()));

    expect(find.byType(CitySuggestionsList), findsOneWidget);
    expect(find.byKey(const Key('citySuggestionsList')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a loading indicator while searching', (tester) async {
    await tester.pumpWidget(
      buildSubject(const CitySearchState(query: 'Lon', isLoading: true)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the error message on failure', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const CitySearchState(query: 'Lon', errorMessage: 'No connection'),
      ),
    );

    expect(find.text('No connection'), findsOneWidget);
  });

  testWidgets('shows an empty-results message when nothing matches', (tester) async {
    await tester.pumpWidget(
      buildSubject(const CitySearchState(query: 'Zzznotacity')),
    );

    expect(find.textContaining('Zzznotacity'), findsOneWidget);
  });

  testWidgets('lists each suggestion by its display label', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const CitySearchState(query: 'Lon', results: [london, liverpool]),
      ),
    );

    expect(find.text(london.displayLabel), findsOneWidget);
    expect(find.text(liverpool.displayLabel), findsOneWidget);
  });

  testWidgets('calls onSelected with the tapped city', (tester) async {
    CitySuggestion? selected;

    await tester.pumpWidget(
      buildSubject(
        const CitySearchState(query: 'Lon', results: [london, liverpool]),
        onSelected: (city) => selected = city,
      ),
    );

    await tester.tap(find.text(london.displayLabel));

    expect(selected, london);
  });
}
