import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/city_suggestion.dart';

/// A no-op placeholder distinct from `null`, so [CitySearchState.copyWith]
/// can tell "leave errorMessage as-is" apart from "clear errorMessage".
const _unset = Object();

/// The search bar's current query, results, and loading/error status.
class CitySearchState {
  const CitySearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final String query;
  final List<CitySuggestion> results;
  final bool isLoading;
  final String? errorMessage;

  /// Whether there's an active (non-blank) search query.
  bool get hasQuery => query.trim().isNotEmpty;

  /// Whether a completed, error-free search came back with no matches.
  bool get isEmptyResult =>
      hasQuery && !isLoading && errorMessage == null && results.isEmpty;

  CitySearchState copyWith({
    String? query,
    List<CitySuggestion>? results,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return CitySearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

/// Searches for cities via [searchCitiesProvider] and holds the result as
/// state for the search bar's suggestion list.
///
/// Deliberately has no debounce timer of its own — [search] runs
/// immediately when called. Debouncing rapid keystrokes is the search
/// input widget's job (a `Timer`-based UI concern, testable with
/// `WidgetTester.pump`), keeping this notifier a plain, synchronously
/// testable unit: call [search], await it, assert on the state.
class CitySearchNotifier extends Notifier<CitySearchState> {
  /// Guards against a stale, superseded search overwriting a newer one's
  /// results if responses arrive out of order.
  int _requestId = 0;

  @override
  CitySearchState build() => const CitySearchState();

  Future<void> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _requestId++;
      state = const CitySearchState();
      return;
    }

    final requestId = ++_requestId;
    state = state.copyWith(query: query, isLoading: true, errorMessage: null);

    final searchCities = ref.read(searchCitiesProvider);
    final result = await searchCities(query: trimmed);

    if (requestId != _requestId) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        results: const [],
      ),
      (cities) => state = state.copyWith(
        isLoading: false,
        results: cities,
        errorMessage: null,
      ),
    );
  }

  void clear() {
    _requestId++;
    state = const CitySearchState();
  }
}

final citySearchProvider = NotifierProvider<CitySearchNotifier, CitySearchState>(
  CitySearchNotifier.new,
);
