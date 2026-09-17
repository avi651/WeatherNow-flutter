import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/theme/app_breakpoints.dart';

void main() {
  group('AppBreakpoints.classify', () {
    test('classifies widths below compact as compact', () {
      expect(AppBreakpoints.classify(320), ScreenSizeClass.compact);
      expect(
        AppBreakpoints.classify(AppBreakpoints.compact - 1),
        ScreenSizeClass.compact,
      );
    });

    test('classifies widths from compact up to tablet as medium', () {
      expect(
        AppBreakpoints.classify(AppBreakpoints.compact),
        ScreenSizeClass.medium,
      );
      expect(AppBreakpoints.classify(430), ScreenSizeClass.medium);
      expect(
        AppBreakpoints.classify(AppBreakpoints.tablet - 1),
        ScreenSizeClass.medium,
      );
    });

    test('classifies widths at or above tablet as expanded', () {
      expect(
        AppBreakpoints.classify(AppBreakpoints.tablet),
        ScreenSizeClass.expanded,
      );
      expect(AppBreakpoints.classify(1024), ScreenSizeClass.expanded);
    });
  });
}
