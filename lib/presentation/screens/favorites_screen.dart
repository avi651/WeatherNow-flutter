import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/entities/city_suggestion.dart';
import '../providers/favorite_provider.dart';
import '../widgets/favorite_city_tile.dart';
import '../widgets/weather_error_view.dart';
import '../widgets/weather_loading_view.dart';

/// Lists the user's saved favorite cities, loaded from local storage, each
/// showing its last-cached weather (so it still means something offline)
/// and a way to remove it.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({this.onCitySelected, super.key});

  /// Called when a favorite is tapped — e.g. to switch back to the Home
  /// tab showing that city. Optional so the screen is usable standalone.
  final ValueChanged<CitySuggestion>? onCitySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
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

          return ListView.separated(
            key: const Key('favoritesList'),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: favorites.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final city = favorites[index];

              return FavoriteCityTile(
                city: city,
                onTap: onCitySelected == null ? null : () => onCitySelected!(city),
                onRemove: () => ref.read(favoritesProvider.notifier).remove(city),
              );
            },
          );
        },
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
            Text(
              'No favorite cities yet',
              style: theme.textTheme.titleMedium,
            ),
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
