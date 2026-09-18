import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/entities/city_suggestion.dart';
import '../providers/active_city_provider.dart';
import '../providers/city_search_provider.dart';
import '../providers/selected_city_provider.dart';
import 'search/city_suggestions_list.dart';
import 'search/search_input_field.dart';

/// The city search bar: a debounced [SearchInputField] with a rotating
/// placeholder, a "use my location" button, and a suggestions dropdown
/// that appears below it while focused with an active query.
///
/// Selecting a suggestion (or tapping "use my location") updates
/// [selectedCityProvider] and dismisses the keyboard — [selectedCityProvider]
/// is what [activeLocationProvider] reads to decide which coordinates to
/// fetch weather for.
///
/// [activeCityProvider] — the selected city if one was chosen via search,
/// otherwise the device's reverse-geocoded current-location city — is this
/// widget's single source of truth for what the field displays. Whenever
/// the field is empty and unfocused, it's synced to that city's name, so:
/// the selected city stays visible after choosing it, a blank field always
/// falls back to showing whichever city is active, and the device's current
/// location (once it resolves) can never overwrite a manually selected city
/// — [activeCityProvider] already prefers the selection over it, and this
/// only fills a field that's empty to begin with.
///
/// Gaining focus while the field is showing that passive label (rather than
/// text the user actually typed) clears it, so tapping in to search doesn't
/// require first deleting that text.
class WeatherSearchBar extends ConsumerStatefulWidget {
  const WeatherSearchBar({super.key});

  @override
  ConsumerState<WeatherSearchBar> createState() => _WeatherSearchBarState();
}

class _WeatherSearchBarState extends ConsumerState<WeatherSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

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
    if (_focusNode.hasFocus) {
      final activeCity = ref.read(activeCityProvider);
      if (_controller.text.isNotEmpty && _controller.text == activeCity?.name) {
        _controller.clear();
      }
    }
    setState(() {});
  }

  void _selectCity(CitySuggestion city) {
    ref.read(selectedCityProvider.notifier).select(city);
    _controller.text = city.name;
    ref.read(citySearchProvider.notifier).clear();
    _focusNode.unfocus();
  }

  void _useMyLocation() {
    ref.read(selectedCityProvider.notifier).useDeviceLocation();
    _controller.clear();
    ref.read(citySearchProvider.notifier).clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // Fills the field with the active city's name whenever it's otherwise
    // empty — reading the provider reactively (rather than only reacting to
    // its future transitions via `ref.listen`) so this also covers the
    // common case where the provider already resolved before this widget
    // was first built (e.g. on initial app load, since `HomeScreen` starts
    // resolving it well before the weather finishes loading and this widget
    // ever mounts).
    final activeCity = ref.watch(activeCityProvider);
    if (_controller.text.isEmpty && !_focusNode.hasFocus && activeCity != null) {
      _controller.text = activeCity.name;
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
