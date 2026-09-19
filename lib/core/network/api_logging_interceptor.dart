import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Logs each request's method/URL, response status, and — on failure — the
/// server's actual error body, so production issues (like a missing network
/// permission, an expired key, or a provider outage) are diagnosable from
/// the device's logs without ever printing the API key itself.
///
/// Uses [debugPrint] rather than `dart:developer.log`: the latter only
/// reaches a connected DevTools/VM-service session, so it's silent for a
/// standalone release install with no debugger attached — exactly the
/// situation this logging exists to help with. [debugPrint] is routed to
/// the platform's log output (e.g. `adb logcat`, tagged `flutter`) in both
/// debug and release builds regardless of whether a debugger is attached.
class ApiLoggingInterceptor extends Interceptor {
  const ApiLoggingInterceptor();

  static const _tag = 'ApiClient';

  /// Returns [uri] with its `appid` query parameter (the OpenWeatherMap API
  /// key) replaced by a placeholder, leaving every other parameter as-is.
  static Uri redact(Uri uri) {
    if (!uri.queryParameters.containsKey('appid')) return uri;

    final redactedParams = Map<String, dynamic>.from(uri.queryParameters)
      ..['appid'] = '***';

    return uri.replace(queryParameters: redactedParams);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('$_tag: --> ${options.method} ${redact(options.uri)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '$_tag: <-- ${response.statusCode} ${redact(response.requestOptions.uri)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '$_tag: <-- ${err.response?.statusCode ?? err.type} '
      '${redact(err.requestOptions.uri)} '
      'error response: ${err.response?.data ?? err.message}',
    );
    handler.next(err);
  }
}
