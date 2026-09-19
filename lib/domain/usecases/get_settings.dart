import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

/// Loads the user's saved app-wide preferences.
class GetSettings {
  const GetSettings(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, AppSettings>> call() {
    return _repository.getSettings();
  }
}
