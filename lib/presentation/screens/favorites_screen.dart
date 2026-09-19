import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/city_suggestion.dart';
import '../providers/favorite_cached_weather_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/favorites_sync_provider.dart';
import '../navigation/tab_navigation.dart';
import '../utils/format_time.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/favorite_city_tile.dart';
import '../widgets/weather_error_view.dart';
import '../widgets/weather_loading_view.dart';

/// Lists the user's saved favorite cities, loaded from local storage, each
/// showing its last-cached weather (so it still means something offline)
/// and a way to remove it. An "Offline Access" section above the list
/// reports when that cached data is from and lets the user refresh it.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({this.onCitySelected, super.key});

  /// Called when a favorite is tapped — e.g. to switch back to the Home
  /// tab showing that city. Optional so the screen is usable standalone.
  final ValueChanged<CitySuggestion>? onCitySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Favorites'),
      ),
      body: favoritesState.when(
        loading: () => const WeatherLoadingView(),
        error: (error, _) => WeatherErrorView(
          message: 'Failed to load favorites.',
          onRetry: () => ref.invalidate(favoritesProvider),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return const _EmptyFavorites();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final sizeClass = AppBreakpoints.classify(constraints.maxWidth);
              final horizontalPadding = AppBreakpoints.spacingForSizeClass(
                sizeClass,
              );

              return Center(
                child: ConstrainedBox(
                  key: const Key('favoritesContentConstraint'),
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.contentMaxWidth,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.md,
                          horizontalPadding,
                          0,
                        ),
                        child: _OfflineAccessSection(favorites: favorites),
                      ),
                      Expanded(
                        child: ListView.separated(
                          key: const Key('favoritesList'),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            AppSpacing.md,
                            horizontalPadding,
                            AppSpacing.xl,
                          ),
                          itemCount: favorites.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final city = favorites[index];

                            return FavoriteCityTile(
                              city: city,
                              onTap: onCitySelected == null
                                  ? null
                                  : () => onCitySelected!(city),
                              onRemove: () => ref
                                  .read(favoritesProvider.notifier)
                                  .remove(city),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onDestinationSelected: (index) =>
            navigateToTab(context, ref, from: favoritesTabIndex, to: index),
      ),
    );
  }
}

/// Reports when the favorites' cached weather was last refreshed and lets
/// the user force a refresh via [favoritesSyncProvider] — the app's only
/// explicit "go fetch live data for everything I've saved" action, since
/// otherwise a favorite's cache is only ever updated incidentally (by
/// visiting Home for that city).
class _OfflineAccessSection extends ConsumerWidget {
  const _OfflineAccessSection({required this.favorites});

  final List<CitySuggestion> favorites;

  DateTime? _latestFetchedAt(WidgetRef ref) {
    DateTime? latest;
    for (final city in favorites) {
      final cached = ref.watch(favoriteCachedWeatherProvider(city)).value;
      if (cached == null) continue;
      if (latest == null || cached.fetchedAt.isAfter(latest)) {
        latest = cached.fetchedAt;
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final syncState = ref.watch(favoritesSyncProvider);
    final isSyncing = syncState.isLoading;
    final lastUpdated = _latestFetchedAt(ref);

    return Container(
      key: const Key('offlineAccessSection'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_done_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Offline Access',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                key: const Key('syncFavoritesButton'),
                onPressed: isSyncing
                    ? null
                    : () => ref.read(favoritesSyncProvider.notifier).sync(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                icon: isSyncing
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.sync, size: 16),
                label: Text(isSyncing ? 'Syncing…' : 'Sync Now'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            lastUpdated == null
                ? 'Your favorites will be cached here for offline access.'
                : 'Last updated ${formatCacheTime(context, lastUpdated)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (syncState.hasError) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_off, size: 14, color: theme.colorScheme.error),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    "You're offline — showing your last saved weather.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_border,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No favorite cities yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap the star on a city\'s weather to save it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
