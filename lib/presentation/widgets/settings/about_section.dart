import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_version_provider.dart';
import 'settings_section_card.dart';

/// Shows the installed app version.
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);

    return SettingsSectionCard(
      title: 'About',
      icon: Icons.info_outline,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('App Version'),
          trailing: Text(
            versionAsync.value ?? '—',
            key: const Key('appVersionValue'),
          ),
        ),
      ],
    );
  }
}
