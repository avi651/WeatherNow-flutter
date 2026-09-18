import 'package:flutter/material.dart';

/// Bottom navigation switching between Home, Favorites, and Settings.
///
/// [selectedIndex] and [onDestinationSelected] default to "Home, static"
/// so this remains usable (and testable) on its own without a parent
/// managing navigation state.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    this.selectedIndex = 0,
    this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected ?? (_) {},
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.star_border),
              selectedIcon: Icon(Icons.star),
              label: 'Favorites',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
