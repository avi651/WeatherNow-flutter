import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/entities/city_suggestion.dart';
import '../providers/favorite_cached_weather_provider.dart';
import '../utils/format_time.dart';
import '../utils/weather_condition_icon.dart';

/// One row in [FavoritesScreen]: a saved city, its last-cached weather (if
/// any), a remove button, and — when [onTap] is given — tapping the row to
/// view it.
class FavoriteCityTile extends ConsumerWidget {
  const FavoriteCityTile({
    required this.city,
    required this.onRemove,
    this.onTap,
    super.key,
  });

  final CitySuggestion city;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cachedWeather = ref.watch(favoriteCachedWeatherProvider(city));

    return Material(
      key: Key('favoriteTile_${city.name}_${city.country}'),
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              cachedWeather.when(
                data: (cached) => Icon(
                  cached == null ? Icons.location_city : weatherConditionIcon(cached.weather.condition),
                  color: theme.colorScheme.primary,
                ),
                loading: () => Icon(Icons.location_city, color: theme.colorScheme.primary),
                error: (_, _) => Icon(Icons.location_city, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    cachedWeather.when(
                      data: (cached) => Text(
                        cached == null
                            ? 'No cached weather yet'
                            : '${cached.weather.temperatureCelsius.round()}° · '
                                '${cached.weather.description} · cached '
                                '${formatCacheTime(context, cached.fetchedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      loading: () => SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      error: (_, _) => Text(
                        'No cached weather yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('removeFavorite_${city.name}_${city.country}'),
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remove from favorites',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
