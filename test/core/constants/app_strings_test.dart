import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

void main() {
  test('rotates through the requested example cities', () {
    expect(AppStrings.searchPlaceholderPhrases, contains('Search Mumbai'));
    expect(AppStrings.searchPlaceholderPhrases, contains('Search London'));
    expect(AppStrings.searchPlaceholderPhrases, contains('Search New York'));
    expect(AppStrings.searchPlaceholderPhrases, contains('Search Tokyo'));
    expect(AppStrings.searchPlaceholderPhrases, contains('Search Paris'));
  });
}
