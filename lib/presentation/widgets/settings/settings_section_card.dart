import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// A rounded, titled card wrapping one Settings section's controls —
/// shared across every section so the screen reads as one consistent
/// system: same corner radius, padding, and title treatment throughout.
///
/// Built on [Material] (with a matching [RoundedRectangleBorder] for the
/// border) rather than a plain [Container] with a [BoxDecoration] — a
/// `ListTile` inside (see `AboutSection`) paints its own background and
/// ink splashes on the nearest `Material` ancestor, and a `DecoratedBox`
/// in between hides those effects.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.title,
    required this.icon,
    required this.children,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}
