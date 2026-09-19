import 'package:flutter/material.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/entities/current_weather.dart';
import 'weather_detail_tile.dart';

/// A row of quick stats below the hero card. Reuses [WeatherDetailTile]
/// so each stat's layout is defined once.
///
/// Shows pressure rather than UV index: no UV Index API is integrated
/// yet, and pressure is real data we already have.
class WeatherStatsRow extends StatelessWidget {
  const WeatherStatsRow({required this.weather, super.key});

  final CurrentWeather weather;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runAlignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          WeatherDetailTile(
            icon: Icons.water_drop,
            label: AppStrings.humidity,
            value: '${weather.humidityPercent}%',
          ),
          WeatherDetailTile(
            icon: Icons.air,
            label: AppStrings.wind,
            value: '${weather.windSpeedMetersPerSecond.toStringAsFixed(1)} m/s',
          ),
          WeatherDetailTile(
            icon: Icons.speed,
            label: AppStrings.pressure,
            value: '${weather.pressureHpa} hPa',
          ),
        ],
      ),
    );
  }
}
