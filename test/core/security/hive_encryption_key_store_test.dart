import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_now_flutter/core/security/hive_encryption_key_store.dart';

import '../../support/fake_secure_storage.dart';

void main() {
  late FakeSecureStorage fake;
  late HiveEncryptionKeyStore store;

  setUp(() {
    fake = FakeSecureStorage();
    store = HiveEncryptionKeyStore(storage: fake.mock);
  });

  test('generates and persists a 32-byte key on first use', () async {
    final key = await store.loadOrCreate();

    expect(key.wasCreated, isTrue);
    expect(key.bytes, hasLength(32));
    expect(
      base64Url.decode(fake.values[HiveEncryptionKeyStore.storageKey]!),
      key.bytes,
    );
  });

  test('returns the same key on later calls without regenerating', () async {
    final first = await store.loadOrCreate();
    final second = await store.loadOrCreate();

    expect(second.wasCreated, isFalse);
    expect(second.bytes, first.bytes);
  });

  test('replaces a corrupt stored key', () async {
    fake.values[HiveEncryptionKeyStore.storageKey] = 'not-a-valid-key';

    final key = await store.loadOrCreate();

    expect(key.wasCreated, isTrue);
    expect(key.bytes, hasLength(32));
  });

  test('propagates secure storage failures to the caller', () async {
    fake.failReads = true;

    expect(store.loadOrCreate(), throwsException);
  });
}
