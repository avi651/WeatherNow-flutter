import 'package:flutter/material.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

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
      tooltip: isFavorite
          ? AppStrings.removeFromFavorites
          : AppStrings.addToFavorites,
    );
  }
}
