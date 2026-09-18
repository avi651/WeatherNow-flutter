import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../utils/format_time.dart';

/// Shown above the weather content when it's a cached snapshot rather than
/// a live fetch — e.g. the device is offline — so the user knows the data
/// might be stale and when it's actually from.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.fetchedAt, super.key});

  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('offlineBanner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "You're offline — showing data from "
              '${formatCacheTime(context, fetchedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
