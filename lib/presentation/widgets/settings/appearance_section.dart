import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/app_theme_mode.dart';
import '../../providers/settings_provider.dart';
import 'settings_section_card.dart';

/// Lets the user pick System Default, Light, or Dark — persisted via
/// [settingsProvider] and applied app-wide through `themeModeProvider`,
/// which [App] passes straight to `MaterialApp.themeMode`.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode =
        ref.watch(settingsProvider).value?.themeMode ??
        AppSettings.defaults.themeMode;

    return SettingsSectionCard(
      title: AppStrings.appearance,
      icon: Icons.palette_outlined,
      children: [
        SegmentedButton<AppThemeMode>(
          key: const Key('themeModeSegmented'),
          segments: const [
            ButtonSegment(
              value: AppThemeMode.system,
              label: Text(AppStrings.themeSystem),
              icon: Icon(Icons.brightness_auto, size: 16),
            ),
            ButtonSegment(
              value: AppThemeMode.light,
              label: Text(AppStrings.themeLight),
              icon: Icon(Icons.light_mode_outlined, size: 16),
            ),
            ButtonSegment(
              value: AppThemeMode.dark,
              label: Text(AppStrings.themeDark),
              icon: Icon(Icons.dark_mode_outlined, size: 16),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) {
            ref.read(settingsProvider.notifier).setThemeMode(selection.first);
          },
        ),
      ],
    );
  }
}
