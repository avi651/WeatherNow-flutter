import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../providers/app_version_provider.dart';
import 'settings_section_card.dart';

/// Shows the installed app version.
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);

    return SettingsSectionCard(
      title: AppStrings.about,
      icon: Icons.info_outline,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.appVersion),
          trailing: Text(
            versionAsync.value ?? AppStrings.unknownValue,
            key: const Key('appVersionValue'),
          ),
        ),
      ],
    );
  }
}
