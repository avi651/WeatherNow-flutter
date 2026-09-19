import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../../domain/entities/app_settings.dart';
import '../../providers/settings_provider.dart';
import 'settings_section_card.dart';

/// Toggles whether the app stores weather locally and falls back to it
/// when a live fetch fails — read by `HomeWeatherNotifier`/
/// `HomeForecastNotifier` (whether a fetch may cache or fall back to
/// cache) and `FavoritesSyncNotifier` (whether a sync may write at all).
class OfflineDataSection extends ConsumerWidget {
  const OfflineDataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(settingsProvider).value?.offlineDataEnabled ??
        AppSettings.defaults.offlineDataEnabled;

    return SettingsSectionCard(
      title: AppStrings.offlineData,
      icon: Icons.cloud_download_outlined,
      children: [
        SwitchListTile(
          key: const Key('offlineDataSwitch'),
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.offlineDataToggleTitle),
          subtitle: const Text(AppStrings.offlineDataToggleSubtitle),
          value: enabled,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setOfflineDataEnabled(value);
          },
        ),
      ],
    );
  }
}
