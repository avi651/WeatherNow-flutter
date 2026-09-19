import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/entities/cached_current_weather.dart';
import '../../domain/entities/city_suggestion.dart';
import '../providers/favorite_cached_weather_provider.dart';
import '../providers/temperature_unit_provider.dart';
import '../utils/format_temperature.dart';
import '../utils/format_time.dart';
import '../utils/weather_condition_icon.dart';
import 'favorite_star_button.dart';

/// Actions offered by [FavoriteCityTile]'s three-dot menu.
enum _FavoriteTileAction { setAsHome, remove }

/// One card in [FavoritesScreen]: a saved city's icon, name, state, and
/// last-cached weather, with a star to remove it and a menu for other
/// actions. Tapping the card (when [onTap] is given) views it.
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
    final unit = ref.watch(temperatureUnitProvider);
    final subtitle = (city.state != null && city.state!.isNotEmpty)
        ? city.state!
        : city.country;

    return Material(
      key: Key('favoriteTile_${city.name}_${city.country}'),
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ConditionBadge(cachedWeather: cachedWeather),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FavoriteStarButton(
                    key: Key('removeFavorite_${city.name}_${city.country}'),
                    isFavorite: true,
                    onPressed: onRemove,
                  ),
                  PopupMenuButton<_FavoriteTileAction>(
                    key: Key('favoriteMenu_${city.name}_${city.country}'),
                    tooltip: 'More actions',
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _FavoriteTileAction.setAsHome:
                          onTap?.call();
                        case _FavoriteTileAction.remove:
                          onRemove();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onTap != null)
                        const PopupMenuItem(
                          value: _FavoriteTileAction.setAsHome,
                          child: Text('Set as Home location'),
                        ),
                      const PopupMenuItem(
                        value: _FavoriteTileAction.remove,
                        child: Text('Remove from Favorites'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              cachedWeather.when(
                data: (cached) => cached == null
                    ? Text(
                        'No cached weather yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatTemperature(cached.weather.temperatureCelsius, unit),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cached.weather.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  'cached ${formatCacheTime(context, cached.fetchedAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                loading: () => Row(
                  children: [
                    SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Loading weather…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
      ),
    );
  }
}

/// A small circular badge showing the cached weather's condition icon —
/// or a plain location pin before there's anything cached to show one
/// for.
class _ConditionBadge extends StatelessWidget {
  const _ConditionBadge({required this.cachedWeather});

  final AsyncValue<CachedCurrentWeather?> cachedWeather;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = cachedWeather.when(
      data: (cached) => cached == null
          ? Icons.location_city
          : weatherConditionIcon(cached.weather.condition),
      loading: () => Icons.location_city,
      error: (_, _) => Icons.location_city,
    );

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
