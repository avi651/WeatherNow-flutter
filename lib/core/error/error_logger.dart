import 'package:flutter/foundation.dart' show debugPrint;

/// Receives every error reported through [logError].
typedef ErrorLogSink =
    void Function(String context, Object error, StackTrace? stackTrace);

/// The production sink: prints via `debugPrint`.
void debugPrintErrorLogSink(
  String context,
  Object error,
  StackTrace? stackTrace,
) {
  debugPrint('WeatherNow: $context: $error');
  if (stackTrace != null) debugPrint('$stackTrace');
}

/// Where [logError] sends its reports. Defaults to `debugPrint`; tests
/// replace it (see `test/flutter_test_config.dart`) so expected, handled
/// failures are captured and can be asserted on instead of polluting the
/// test output.
ErrorLogSink errorLogSink = debugPrintErrorLogSink;

/// Logs the original [error] for debugging. Failure messages are shown in
/// the UI, so technical details must go here rather than into them.
void logError(String context, Object error, [StackTrace? stackTrace]) {
  errorLogSink(context, error, stackTrace);
}
