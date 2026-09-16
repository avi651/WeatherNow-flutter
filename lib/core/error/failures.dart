/// Base class for representing recoverable failures across the app.
///
/// Repositories return `Failure`s (instead of throwing) so the domain
/// and presentation layers can handle errors predictably.
abstract class Failure {
  const Failure(this.message);

  final String message;
}
