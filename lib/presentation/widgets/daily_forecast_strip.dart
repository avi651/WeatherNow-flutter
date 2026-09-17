import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_spacing.dart';
import '../utils/daily_forecast_aggregator.dart';
import '../utils/weather_condition_icon.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// A horizontally scrolling strip of daily forecast cards. The first
/// entry is always labeled "Today" regardless of the actual weekday.
///
/// Card size is computed from the available width via [LayoutBuilder]
/// rather than fixed — more cards' worth of width are targeted as visible
/// on wider screens, clamped to a sane min/max so cards never get
/// illegibly small or absurdly large.
class DailyForecastStrip extends StatelessWidget {
  const DailyForecastStrip({required this.days, super.key});

  final List<DailyForecastSummary> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = AppBreakpoints.classify(constraints.maxWidth);
        final targetVisibleCards = switch (sizeClass) {
          ScreenSizeClass.compact => 3.5,
          ScreenSizeClass.medium => 4.5,
          ScreenSizeClass.expanded => 6.5,
        };

        final cardWidth = (constraints.maxWidth / targetVisibleCards).clamp(
          AppDimensions.forecastCardMinWidth,
          AppDimensions.forecastCardMaxWidth,
        );
        final cardHeight = cardWidth / AppDimensions.forecastCardAspectRatio;

        return SizedBox(
          key: const Key('dailyForecastStripSize'),
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final day = days[index];
              final label =
                  index == 0 ? 'Today' : _weekdayLabels[day.date.weekday - 1];

              return _DayCard(
                label: label,
                isSelected: index == 0,
                summary: day,
                width: cardWidth,
              );
            },
          ),
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.label,
    required this.isSelected,
    required this.summary,
    required this.width,
  });

  final String label;
  final bool isSelected;
  final DailyForecastSummary summary;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSelected = theme.colorScheme.onPrimary;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.75),
                ],
              )
            : null,
        color: isSelected ? null : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: isSelected
            ? null
            : Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? onSelected : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(
            weatherConditionIcon(summary.condition),
            color: isSelected
                ? onSelected
                : theme.colorScheme.onSurfaceVariant,
          ),
          Text(
            '${summary.maxTemperatureCelsius.round()}°',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected ? onSelected : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${summary.minTemperatureCelsius.round()}°',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? onSelected.withValues(alpha: 0.85)
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
