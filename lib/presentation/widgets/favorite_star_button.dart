import 'package:flutter/material.dart';

/// A star-icon toggle reflecting and controlling favorite status.
class FavoriteStarButton extends StatelessWidget {
  const FavoriteStarButton({
    required this.isFavorite,
    required this.onPressed,
    super.key,
  });

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: onPressed,
      icon: Icon(isFavorite ? Icons.star : Icons.star_border),
      color: isFavorite ? Colors.amber : theme.colorScheme.onSurfaceVariant,
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
    );
  }
}
