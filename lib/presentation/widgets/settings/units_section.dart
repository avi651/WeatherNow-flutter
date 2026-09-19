import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/temperature_unit.dart';
import '../../providers/settings_provider.dart';
import 'settings_section_card.dart';

/// Lets the user pick Celsius or Fahrenheit — read everywhere the app
/// shows a temperature via `temperatureUnitProvider`.
class UnitsSection extends ConsumerWidget {
  const UnitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit =
        ref.watch(settingsProvider).value?.temperatureUnit ??
        AppSettings.defaults.temperatureUnit;

    return SettingsSectionCard(
      title: AppStrings.units,
      icon: Icons.thermostat_outlined,
      children: [
        SegmentedButton<TemperatureUnit>(
          key: const Key('temperatureUnitSegmented'),
          segments: const [
            ButtonSegment(
              value: TemperatureUnit.celsius,
              label: Text(AppStrings.celsius),
            ),
            ButtonSegment(
              value: TemperatureUnit.fahrenheit,
              label: Text(AppStrings.fahrenheit),
            ),
          ],
          selected: {unit},
          onSelectionChanged: (selection) {
            ref
                .read(settingsProvider.notifier)
                .setTemperatureUnit(selection.first);
          },
        ),
      ],
    );
  }
}
