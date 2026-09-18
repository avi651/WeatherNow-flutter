import 'failures.dart';

/// Reading from or writing to local (on-device) storage failed — a
/// corrupted Hive entry, a full disk, or similar. Kept distinct from
/// [Failure]'s other subtypes since it never originates from the network.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
