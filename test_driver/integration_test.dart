import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final out = <String, dynamic>{};
    for (final entry in data.entries) {
      final summary = TimelineSummary.summarize(
        Timeline.fromJson(entry.value as Map<String, dynamic>),
      );
      out[entry.key] = summary.summaryJson;
    }
    await File('build/perf_result.json').writeAsString(jsonEncode(out));
  },
);
