import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/selected_city_provider.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';

/// Bottom-tab indexes shared by every screen's `BottomNavBar`.
const homeTabIndex = 0;
const favoritesTabIndex = 1;
const settingsTabIndex = 2;

/// Switches from the tab at [from] to the tab at [to] without leaving a
/// growing back stack — there are no back buttons, so the tab bar is the
/// only way around. Home is the root route: going there pops everything
/// above it; Favorites and Settings replace each other, and are pushed
/// over Home when coming from it.
void navigateToTab(
  BuildContext context,
  WidgetRef ref, {
  required int from,
  required int to,
}) {
  if (from == to) return;

  final navigator = Navigator.of(context);
  if (to == homeTabIndex) {
    navigator.popUntil((route) => route.isFirst);
    return;
  }

  final route = MaterialPageRoute<void>(
    builder: (_) => to == favoritesTabIndex
        ? FavoritesScreen(
            onCitySelected: (city) {
              ref.read(selectedCityProvider.notifier).select(city);
              navigator.popUntil((route) => route.isFirst);
            },
          )
        : const SettingsScreen(),
  );

  if (from == homeTabIndex) {
    navigator.push(route);
  } else {
    navigator.pushReplacement(route);
  }
}
