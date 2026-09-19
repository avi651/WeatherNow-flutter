import 'package:flutter/material.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/temperature_unit.dart';
import '../utils/daily_forecast_aggregator.dart';
import '../utils/day_period_grouper.dart';
import '../utils/format_temperature.dart';
import '../utils/weather_condition_icon.dart';
import '../widgets/weather_detail_tile.dart';

/// Detail view for one day of the forecast, broken into morning,
/// afternoon and evening. Built purely from the [summary] the Home screen
/// already holds (its 3-hour entries), so opening it never refetches.
class ForecastDetailScreen extends StatelessWidget {
  const ForecastDetailScreen({
    required this.summary,
    required this.label,
    this.unit = TemperatureUnit.celsius,
    this.locationName,
    super.key,
  });

  final DailyForecastSummary summary;

  /// "Today" or a weekday abbreviation, as shown on the tapped card.
  final String label;
  final TemperatureUnit unit;
  final String? locationName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periods = DayPeriodGrouper.group(summary.entries);
    final date =
        '${AppStrings.monthLabels[summary.date.month - 1]} ${summary.date.day}';

    return Scaffold(
      appBar: AppBar(title: Text('$label, $date')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (locationName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      locationName!,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                Text(
                  AppStrings.highLow(
                    formatTemperature(summary.maxTemperatureCelsius, unit),
                    formatTemperature(summary.minTemperatureCelsius, unit),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (periods.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: Text(AppStrings.noDetailedForecast)),
                  ),
                for (final period in periods) ...[
                  _PeriodCard(period: period, unit: unit),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period, required this.unit});

  final DayPeriodForecast period;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final range = period.minTemperatureCelsius == period.maxTemperatureCelsius
        ? formatTemperature(period.maxTemperatureCelsius, unit)
        : '${formatTemperature(period.minTemperatureCelsius, unit)}'
              ' – ${formatTemperature(period.maxTemperatureCelsius, unit)}';

    return Container(
      key: Key('periodCard_${period.period.name}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                weatherConditionIcon(period.condition),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  period.period.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                range,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            period.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              WeatherDetailTile(
                icon: Icons.thermostat,
                label: AppStrings.feelsLike,
                value: formatTemperature(period.averageFeelsLikeCelsius, unit),
              ),
              WeatherDetailTile(
                icon: Icons.water_drop_outlined,
                label: AppStrings.humidity,
                value: '${period.averageHumidityPercent}%',
              ),
              WeatherDetailTile(
                icon: Icons.umbrella_outlined,
                label: AppStrings.rain,
                value: '${(period.maxPrecipitationProbability * 100).round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
