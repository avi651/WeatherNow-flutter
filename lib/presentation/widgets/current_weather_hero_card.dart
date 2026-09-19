import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/current_weather.dart';
import '../providers/temperature_unit_provider.dart';
import '../utils/format_temperature.dart';
import '../utils/weather_condition_icon.dart';
import 'favorite_star_button.dart';

/// The main current-weather display: location, temperature, condition,
/// and a favorite toggle, over a gradient background evoking the sky.
class CurrentWeatherHeroCard extends ConsumerWidget {
  const CurrentWeatherHeroCard({
    required this.weather,
    required this.locationName,
    required this.country,
    required this.isFavorite,
    required this.onFavoriteToggle,
    super.key,
  });

  final CurrentWeather weather;
  final String locationName;
  final String country;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(temperatureUnitProvider);
    final sizeClass = AppBreakpoints.classify(MediaQuery.sizeOf(context).width);
    final padding = switch (sizeClass) {
      ScreenSizeClass.compact => AppSpacing.md,
      ScreenSizeClass.medium => AppSpacing.lg,
      ScreenSizeClass.expanded => AppSpacing.xl,
    };

    const onCard = Colors.white;

    return Container(
      key: const Key('currentWeatherHeroCard'),
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
            theme.colorScheme.tertiaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              weatherConditionIcon(weather.condition),
              size: 150,
              color: onCard.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: onCard.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                locationName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: onCard,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (country.isNotEmpty)
                          Padding(
                            // Indented to sit under the city name, past the
                            // icon + gap that precede it above.
                            padding: const EdgeInsets.only(
                              left: 18 + AppSpacing.xs,
                            ),
                            child: Text(
                              country,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onCard.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  FavoriteStarButton(
                    isFavorite: isFavorite,
                    onPressed: onFavoriteToggle,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      formatTemperature(weather.temperatureCelsius, unit),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Tight leading so the glyphs' own bounds — not the
                      // font's extra line-height padding — drive the
                      // Row's crossAxisAlignment.center, keeping the icon
                      // pixel-aligned with the numeral instead of
                      // appearing to sit a few pixels low.
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: onCard,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    weatherConditionIcon(weather.condition),
                    size: 44,
                    color: onCard,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: onCard.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: Text(
                  weather.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: onCard,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.thermostat,
                    size: 16,
                    color: onCard.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      AppStrings.feelsLikeValue(
                        formatTemperature(weather.feelsLikeCelsius, unit),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onCard.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
