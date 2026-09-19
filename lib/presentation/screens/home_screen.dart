import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/active_city_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/home_forecast_provider.dart';
import '../providers/home_weather_exception.dart';
import '../providers/home_weather_provider.dart';
import '../providers/temperature_unit_provider.dart';
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
    final weatherState = ref.watch(homeWeatherProvider);
    final forecastState = ref.watch(homeForecastProvider);
    final isFavorite = ref.watch(isFavoriteProvider);
    final activeCity = ref.watch(activeCityProvider);
    final temperatureUnit = ref.watch(temperatureUnitProvider);
    // Current weather and forecast are fetched independently and can each
    // fall back to cache on their own, so their freshness is tracked
    // separately too — this surfaces the banner whenever either one is
    // stale, instead of one's live fetch masking the other's cached
    // fallback.
    final currentWeatherFreshness = ref.watch(currentWeatherFreshnessProvider);
    final forecastFreshness = ref.watch(forecastFreshnessProvider);
    final cachedFreshness = currentWeatherFreshness?.isFromCache == true
        ? currentWeatherFreshness
        : (forecastFreshness?.isFromCache == true ? forecastFreshness : null);

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
    final hasDisplayableWeather = weatherState.hasValue && forecastState.hasValue;

    Widget body;
    if ((weatherState.isLoading || forecastState.isLoading) && !hasDisplayableWeather) {
      body = const WeatherLoadingView();
    } else if ((weatherState.hasError || forecastState.hasError) && !hasDisplayableWeather) {
      final error = weatherState.error ?? forecastState.error;
      body = WeatherErrorView(
        message: error is HomeWeatherFailureException
            ? error.message
            : 'Something went wrong. Please try again.',
        onRetry: () {
          ref.read(homeWeatherProvider.notifier).retry();
          ref.read(homeForecastProvider.notifier).retry();
        },
      );
    } else {
      final weather = weatherState.value!;
      final forecast = forecastState.value!;
      final dailySummaries = DailyForecastAggregator.aggregate(forecast.entries);

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
                constraints:
                    const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
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
                      if (cachedFreshness != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        OfflineBanner(fetchedAt: cachedFreshness.fetchedAt),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      CurrentWeatherHeroCard(
                        weather: weather,
                        locationName: activeCity?.name ?? 'Current Location',
                        country: activeCity?.country ?? '',
                        isFavorite: isFavorite,
                        onFavoriteToggle: () {
                          if (activeCity != null) {
                            ref.read(favoritesProvider.notifier).toggle(activeCity);
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
                            '5 Day Forecast',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DailyForecastStrip(days: dailySummaries, unit: temperatureUnit),
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
              colors: [
                colorScheme.surfaceContainerLow,
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(child: body),
        ),
        bottomNavigationBar: BottomNavBar(
          onDestinationSelected: (index) => _onDestinationSelected(context, ref, index),
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
