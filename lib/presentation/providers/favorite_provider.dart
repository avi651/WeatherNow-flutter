import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the currently displayed location is marked as a favorite.
///
/// UI-only for now — nothing persists this across app restarts. If that's
/// needed later, this is the one place that would change (e.g. reading
/// from and writing to local storage in [build] and [toggle]).
class FavoriteNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final isFavoriteProvider = NotifierProvider<FavoriteNotifier, bool>(
  FavoriteNotifier.new,
);
