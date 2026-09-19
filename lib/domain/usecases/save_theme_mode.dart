import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/settings_repository.dart';

/// Persists the user's chosen app theme.
class SaveThemeMode {
  const SaveThemeMode(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, Unit>> call(AppThemeMode mode) {
    return _repository.saveThemeMode(mode);
  }
}
