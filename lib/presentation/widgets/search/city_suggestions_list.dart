import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/city_suggestion.dart';
import '../../providers/city_search_provider.dart';

/// Renders [state] as one of: nothing (no active query), a loading
/// indicator, an error message, an empty-results message, or the list of
/// matching cities — tapping one calls [onSelected].
class CitySuggestionsList extends StatelessWidget {
  const CitySuggestionsList({
    required this.state,
    required this.onSelected,
    super.key,
  });

  final CitySearchState state;
  final ValueChanged<CitySuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    if (!state.hasQuery) return const SizedBox.shrink();

    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                state.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.isEmptyResult) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Text(
          'No cities found for "${state.query.trim()}"',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('citySuggestionsList'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: state.results.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
      itemBuilder: (context, index) {
        final city = state.results[index];

        return ListTile(
          dense: true,
          leading: Icon(Icons.location_city, color: theme.colorScheme.primary),
          title: Text(city.displayLabel),
          onTap: () => onSelected(city),
        );
      },
    );
  }
}
