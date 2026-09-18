import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/presentation/widgets/search/search_placeholder_phrases.dart';

void main() {
  test('rotates through the requested example cities', () {
    expect(kSearchPlaceholderPhrases, contains('Search Mumbai'));
    expect(kSearchPlaceholderPhrases, contains('Search London'));
    expect(kSearchPlaceholderPhrases, contains('Search New York'));
    expect(kSearchPlaceholderPhrases, contains('Search Tokyo'));
    expect(kSearchPlaceholderPhrases, contains('Search Paris'));
  });
}
