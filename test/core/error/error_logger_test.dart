import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/error/error_logger.dart';

import '../../support/captured_error_logs.dart';

void main() {
  test('logError forwards context, error and stack trace to the sink', () {
    final stack = StackTrace.current;

    logError('Something failed', StateError('boom'), stack);

    expect(capturedErrorLogs, hasLength(1));
    expect(capturedErrorLogs.single.context, 'Something failed');
    expect(capturedErrorLogs.single.error, isA<StateError>());
    expect(capturedErrorLogs.single.stackTrace, stack);
  });

  test('the production sink prints the context and error via debugPrint', () {
    restoreErrorLogSink();
    addTearDown(captureErrorLogs);
    final printed = <String?>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message);
    addTearDown(() => debugPrint = original);

    logError('Something failed', 'boom');

    expect(printed, ['WeatherNow: Something failed: boom']);
  });
}
