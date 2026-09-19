import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../navigation/tab_navigation.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/settings/about_section.dart';
import '../widgets/settings/appearance_section.dart';
import '../widgets/settings/location_permissions_section.dart';
import '../widgets/settings/offline_data_section.dart';
import '../widgets/settings/units_section.dart';

/// App-wide preferences: units, location permission,
/// offline data, appearance, and About — each section persists through
/// its own provider and takes effect wherever the app reads it (e.g.
/// `temperatureUnitProvider`, `themeModeProvider`).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sizeClass = AppBreakpoints.classify(constraints.maxWidth);
          final horizontalPadding = AppBreakpoints.spacingForSizeClass(sizeClass);

          return Center(
            child: ConstrainedBox(
              key: const Key('settingsContentConstraint'),
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.contentMaxWidth,
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.md,
                  horizontalPadding,
                  AppSpacing.xl,
                ),
                children: const [
                  UnitsSection(),
                  SizedBox(height: AppSpacing.md),
                  AppearanceSection(),
                  SizedBox(height: AppSpacing.md),
                  LocationPermissionsSection(),
                  SizedBox(height: AppSpacing.md),
                  OfflineDataSection(),
                  SizedBox(height: AppSpacing.md),
                  AboutSection(),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onDestinationSelected: (index) => navigateToTab(
          context,
          ref,
          from: settingsTabIndex,
          to: index,
        ),
      ),
    );
  }
}
