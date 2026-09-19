import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../repositories/settings_repository.dart';

/// Persists whether the app may store and fall back to cached weather
/// data for offline access.
class SaveOfflineDataEnabled {
  const SaveOfflineDataEnabled(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, Unit>> call(bool enabled) {
    return _repository.saveOfflineDataEnabled(enabled);
  }
}
