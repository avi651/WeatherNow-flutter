import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// An in-memory [FlutterSecureStorage] for tests. Set [failReads] to
/// simulate an unavailable Keychain/Keystore.
class FakeSecureStorage {
  FakeSecureStorage() {
    when(() => mock.read(key: any(named: 'key'))).thenAnswer((i) async {
      if (failReads) throw Exception('keystore unavailable');
      return values[i.namedArguments[#key] as String];
    });
    when(
      () => mock.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((i) async {
      values[i.namedArguments[#key] as String] =
          i.namedArguments[#value] as String;
    });
    when(() => mock.delete(key: any(named: 'key'))).thenAnswer((i) async {
      values.remove(i.namedArguments[#key] as String);
    });
  }

  final mock = _MockSecureStorage();
  final values = <String, String>{};
  bool failReads = false;
}
