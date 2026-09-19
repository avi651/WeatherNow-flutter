import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/temperature_unit.dart';
import '../repositories/settings_repository.dart';

/// Persists the user's chosen temperature display unit.
class SaveTemperatureUnit {
  const SaveTemperatureUnit(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, Unit>> call(TemperatureUnit unit) {
    return _repository.saveTemperatureUnit(unit);
  }
}
