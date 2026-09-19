import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../core/location/device_location.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/city_suggestion.dart';
import '../providers/active_city_provider.dart';
import '../providers/city_search_provider.dart';
import '../providers/current_location_provider.dart';
import '../providers/home_weather_exception.dart';
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
    ref.read(selectedCityProvider.notifier).select(city, remember: true);
    _controller.text = city.name;
    ref.read(citySearchProvider.notifier).clear();
    _focusNode.unfocus();
  }

  void _useMyLocation() {
    // Guards against a duplicate request landing before the rebuild that
    // disables the button (below) takes effect — e.g. two taps in the
    // same frame.
    if (ref.read(selectedCityProvider) == null &&
        ref.read(currentLocationProvider).isLoading) {
      return;
    }

    // [currentLocationProvider] resolves once and caches the result (it
    // opts out of Riverpod's auto-retry, same as this app's other location
    // reads), so without invalidating it here, tapping this button after
    // the very first resolution would silently reuse that stale result —
    // never re-requesting permission, never asking the device for a fresh
    // GPS fix. Invalidating it lets every tap re-check permission and
    // re-fetch a current fix; [currentLocationCityProvider],
    // [activeLocationProvider], [activeCityProvider], and — because
    // `HomeWeatherNotifier`/`HomeForecastNotifier` watch
    // [activeLocationProvider]'s future — the weather/forecast fetch
    // itself all react to that automatically, the same way selecting a
    // searched city already does without this widget needing to know
    // about weather-fetching at all.
    ref.invalidate(currentLocationProvider);
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
    if (_controller.text.isEmpty &&
        !_focusNode.hasFocus &&
        activeCity != null) {
      _controller.text = activeCity.name;
    }

    // Also resyncs on every subsequent change, even when the field already
    // shows a *different*, non-empty city name — otherwise a selection made
    // outside this widget (e.g. tapping a favorite, which sets
    // `selectedCityProvider` directly from `HomeScreen`) would leave the
    // field stuck showing whichever city was selected here last.
    ref.listen<CitySuggestion?>(activeCityProvider, (previous, next) {
      if (!_focusNode.hasFocus) {
        _controller.text = next?.name ?? '';
      }
    });

    // Drives the location button's own loading/disabled state — kept
    // separate from `homeWeatherProvider`/`homeForecastProvider`'s broader
    // loading (which also covers e.g. the full error view's Retry) so the
    // button only reacts to *this* request.
    // A selected city short-circuits the provider (see
    // [LocationNotNeededException]); its brief re-evaluation isn't
    // "locating", so it must not flash the spinner or disable the button.
    final isLocating =
        ref.watch(selectedCityProvider) == null &&
        ref.watch(currentLocationProvider).isLoading;

    // A failed fetch (permission denied, GPS unavailable, etc.) is reported
    // here — a transient snackbar — rather than through the big
    // full-screen error view: the rest of the app (previously-loaded
    // weather, the search bar itself) stays visible and interactive.
    ref.listen<AsyncValue<DeviceLocation>>(currentLocationProvider, (
      previous,
      next,
    ) {
      if (!next.hasError || next.isLoading) return;
      if (next.error is LocationNotNeededException) return;

      final error = next.error;
      final message = error is HomeWeatherFailureException
          ? error.message
          : AppStrings.currentLocationError;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

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
                  onTap: isLocating ? null : _useMyLocation,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: isLocating
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Icon(
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
                child: CitySuggestionsList(
                  state: searchState,
                  onSelected: _selectCity,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
