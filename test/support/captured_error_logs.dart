import 'package:weather_now_flutter/core/error/error_logger.dart';

/// A single report received by [errorLogSink] during a test.
class CapturedErrorLog {
  const CapturedErrorLog(this.context, this.error, this.stackTrace);

  final String context;
  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() => '$context: $error';
}

/// Error reports captured since the current test started. Cleared before
/// every test by `test/flutter_test_config.dart`.
final List<CapturedErrorLog> capturedErrorLogs = [];

/// Routes [logError] into [capturedErrorLogs] instead of the console.
void captureErrorLogs() {
  capturedErrorLogs.clear();
  errorLogSink = (context, error, stackTrace) =>
      capturedErrorLogs.add(CapturedErrorLog(context, error, stackTrace));
}

/// Restores the production sink (`debugPrint`).
void restoreErrorLogSink() {
  errorLogSink = debugPrintErrorLogSink;
}
