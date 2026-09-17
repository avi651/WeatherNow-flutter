import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/entities/city_suggestion.dart';
import '../providers/city_search_provider.dart';
import '../providers/current_location_city_provider.dart';
import '../providers/selected_city_provider.dart';
import 'search/city_suggestions_list.dart';
import 'search/search_input_field.dart';

/// The city search bar: a debounced [SearchInputField] with a rotating
/// placeholder, a "use my location" button, and a suggestions dropdown
/// that appears below it while focused with an active query.
///
/// Selecting a suggestion (or tapping "use my location") updates
/// [selectedCityProvider], clears the field, and dismisses the keyboard —
/// [selectedCityProvider] is what [activeLocationProvider] reads to
/// decide which coordinates to fetch weather for.
///
/// While in "use my location" mode (the default, and after tapping the
/// location button), the field displays [currentLocationCityProvider]'s
/// resolved city name once reverse geocoding finishes — mirroring the
/// same city on the weather card — but reading the field back to blank
/// whenever it's focused, so tapping in to search doesn't require first
/// deleting that text.
class WeatherSearchBar extends ConsumerStatefulWidget {
  const WeatherSearchBar({super.key});

  @override
  ConsumerState<WeatherSearchBar> createState() => _WeatherSearchBarState();
}

class _WeatherSearchBarState extends ConsumerState<WeatherSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _usingDeviceLocation = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    // Gaining focus on a field showing the passive device-location label
    // clears it, so the user can start typing a search immediately instead
    // of first deleting that text. Losing focus without having typed
    // anything restores it, via the sync in `build`.
    if (_focusNode.hasFocus && _usingDeviceLocation && _controller.text.isNotEmpty) {
      _controller.clear();
    }
    setState(() {});
  }

  void _selectCity(CitySuggestion city) {
    _usingDeviceLocation = false;
    ref.read(selectedCityProvider.notifier).select(city);
    _resetSearch();
  }

  void _useMyLocation() {
    _usingDeviceLocation = true;
    ref.read(selectedCityProvider.notifier).useDeviceLocation();
    _resetSearch();
    // `_resetSearch` doesn't reliably trigger a rebuild on its own here:
    // `citySearchProvider`'s `clear()` sets state to a `const
    // CitySearchState()`, and when the search was already empty (as it
    // is right after selecting a city), that's the exact same
    // canonicalized instance already in place — Riverpod sees no change
    // and skips notifying. Force one explicitly so `build`'s
    // device-location-label sync below actually re-runs.
    setState(() {});
  }

  void _resetSearch() {
    _controller.clear();
    ref.read(citySearchProvider.notifier).clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // Fills the field with the resolved device-location city name whenever
    // it's otherwise empty — reading the provider reactively (rather than
    // only reacting to its future transitions via `ref.listen`) so this
    // also covers the common case where the provider already resolved
    // before this widget was first built (e.g. on initial app load, since
    // `HomeScreen` starts resolving it well before the weather finishes
    // loading and this widget ever mounts).
    final currentLocationCity = ref.watch(currentLocationCityProvider).value;
    if (_usingDeviceLocation &&
        _controller.text.isEmpty &&
        !_focusNode.hasFocus &&
        currentLocationCity != null) {
      _controller.text = currentLocationCity.name;
    }

    final theme = Theme.of(context);
    final searchState = ref.watch(citySearchProvider);
    final showSuggestions = _focusNode.hasFocus && searchState.hasQuery;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.xl),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: SearchInputField(
                  controller: _controller,
                  focusNode: _focusNode,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Material(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('useMyLocationButton'),
                  customBorder: const CircleBorder(),
                  onTap: _useMyLocation,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Icon(
                      Icons.my_location,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: theme.colorScheme.surfaceContainerHigh,
                child: CitySuggestionsList(state: searchState, onSelected: _selectCity),
              ),
            ),
          ),
      ],
    );
  }
}
