import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/active_city_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/home_forecast_provider.dart';
import '../providers/home_weather_exception.dart';
import '../providers/home_weather_provider.dart';
import '../providers/selected_city_provider.dart';
import '../providers/temperature_unit_provider.dart';
import '../providers/weather_refresh_provider.dart';
import '../providers/weather_freshness_provider.dart';
import '../navigation/tab_navigation.dart';
import '../utils/daily_forecast_aggregator.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/current_weather_hero_card.dart';
import '../widgets/daily_forecast_strip.dart';
import '../widgets/home_header.dart';
import '../widgets/offline_banner.dart';
import '../widgets/weather_error_view.dart';
import '../widgets/weather_loading_view.dart';
import '../widgets/weather_search_bar.dart';
import '../widgets/weather_stats_row.dart';

/// The Home screen: current weather and a 5-day forecast for the
/// (currently placeholder) location, with loading, success, and
/// error/retry states.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Coming back online: fetch live data so it replaces whatever is on
    // screen (cached or not) and re-caches it. Only a real offline → online
    // transition triggers this; the startup reading has no `previous`.
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (previous?.value == false && next.value == true) {
        ref.read(refreshWeatherProvider)();
      }
    });

    final weatherState = ref.watch(homeWeatherProvider);
    final forecastState = ref.watch(homeForecastProvider);
    final isFavorite = ref.watch(isFavoriteProvider);
    final activeCity = ref.watch(activeCityProvider);
    final temperatureUnit = ref.watch(temperatureUnitProvider);
    // The banner follows connectivity itself, not the outcome of a fetch,
    // so it appears the instant the connection drops and disappears the
    // instant it returns. The timestamp is when the data on screen was
    // actually retrieved.
    final isOnline = ref.watch(isOnlineProvider);
    final dataFetchedAt =
        ref.watch(currentWeatherFreshnessProvider)?.fetchedAt ??
        ref.watch(forecastFreshnessProvider)?.fetchedAt;

    // Once there's data to show, a background refresh — e.g. the search
    // bar's locate-me button invalidating the location and letting
    // `HomeWeatherNotifier`/`HomeForecastNotifier` transparently refetch —
    // must not blank the screen. Only the very first load (nothing fetched
    // yet, from either provider) earns the full-screen loading/error
    // treatment; once both have resolved at least once, `AsyncValue`
    // preserves that previous data through a later loading or error state
    // (`copyWithPrevious`), so a refresh keeps showing it while it updates
    // or reports a problem elsewhere (see the search bar's own feedback
    // for its button) instead of here.
    final hasDisplayableWeather =
        weatherState.hasValue && forecastState.hasValue;

    Widget body;
    if ((weatherState.isLoading || forecastState.isLoading) &&
        !hasDisplayableWeather) {
      body = const WeatherLoadingView();
    } else if ((weatherState.hasError || forecastState.hasError) &&
        !hasDisplayableWeather) {
      final error = weatherState.error ?? forecastState.error;
      final message = error is HomeWeatherFailureException
          ? error.message
          : AppStrings.genericError;
      void retry() {
        ref.read(homeWeatherProvider.notifier).retry();
        ref.read(homeForecastProvider.notifier).retry();
      }

      // With no city chosen the failure is (almost always) the device
      // location; keep the search bar on screen so the user can search
      // instead of being stuck behind a lone Retry button.
      body = ref.watch(selectedCityProvider) == null
          ? _LocationFailedState(message: message, onRetry: retry)
          : WeatherErrorView(message: message, onRetry: retry);
    } else {
      final weather = weatherState.value!;
      final forecast = forecastState.value!;
      final dailySummaries = DailyForecastAggregator.aggregate(
        forecast.entries,
      );

      body = LayoutBuilder(
        builder: (context, constraints) {
          final sizeClass = AppBreakpoints.classify(constraints.maxWidth);
          final horizontalPadding = switch (sizeClass) {
            ScreenSizeClass.compact => AppSpacing.sm,
            ScreenSizeClass.medium => AppSpacing.md,
            ScreenSizeClass.expanded => AppSpacing.xl,
          };

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                key: const Key('homeContentConstraint'),
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HomeHeader(),
                      const SizedBox(height: AppSpacing.lg),
                      const WeatherSearchBar(),
                      if (!isOnline) ...[
                        const SizedBox(height: AppSpacing.lg),
                        OfflineBanner(
                          fetchedAt: dataFetchedAt ?? DateTime.now(),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      CurrentWeatherHeroCard(
                        weather: weather,
                        locationName:
                            activeCity?.name ?? AppStrings.currentLocation,
                        country: activeCity?.country ?? '',
                        isFavorite: isFavorite,
                        onFavoriteToggle: () {
                          if (activeCity != null) {
                            ref
                                .read(favoritesProvider.notifier)
                                .toggle(activeCity);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      WeatherStatsRow(weather: weather),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            AppStrings.fiveDayForecast,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DailyForecastStrip(
                        days: dailySummaries,
                        unit: temperatureUnit,
                        locationName:
                            activeCity?.name ?? AppStrings.currentLocation,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorScheme.surfaceContainerLow, colorScheme.surface],
            ),
          ),
          child: SafeArea(child: body),
        ),
        bottomNavigationBar: BottomNavBar(
          onDestinationSelected: (index) =>
              _onDestinationSelected(context, ref, index),
        ),
      ),
    );
  }

  /// Home is already showing; Favorites and Settings are pushed over it
  /// (see [navigateToTab]).
  void _onDestinationSelected(BuildContext context, WidgetRef ref, int index) {
    navigateToTab(context, ref, from: homeTabIndex, to: index);
  }
}

/// Shown when nothing is selected and the device location couldn't be
/// resolved (denied, disabled, timed out): the failure message with Retry,
/// plus the search bar so a city can be searched instead.
class _LocationFailedState extends StatelessWidget {
  const _LocationFailedState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('locationFailedState'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeHeader(),
          const SizedBox(height: AppSpacing.lg),
          const WeatherSearchBar(),
          const SizedBox(height: AppSpacing.xl),
          Icon(
            Icons.location_off_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ),
        ],
      ),
    );
  }
}
