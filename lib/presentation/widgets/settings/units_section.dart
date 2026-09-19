import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final unit = ref.watch(settingsProvider).value?.temperatureUnit ??
        AppSettings.defaults.temperatureUnit;

    return SettingsSectionCard(
      title: 'Units',
      icon: Icons.thermostat_outlined,
      children: [
        SegmentedButton<TemperatureUnit>(
          key: const Key('temperatureUnitSegmented'),
          segments: const [
            ButtonSegment(value: TemperatureUnit.celsius, label: Text('Celsius (°C)')),
            ButtonSegment(value: TemperatureUnit.fahrenheit, label: Text('Fahrenheit (°F)')),
          ],
          selected: {unit},
          onSelectionChanged: (selection) {
            ref.read(settingsProvider.notifier).setTemperatureUnit(selection.first);
          },
        ),
      ],
    );
  }
}
