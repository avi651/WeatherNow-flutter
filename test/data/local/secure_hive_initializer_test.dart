import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:weather_now_flutter/core/security/hive_encryption_key_store.dart';
import 'package:weather_now_flutter/data/local/secure_hive_initializer.dart';

import '../../support/captured_error_logs.dart';
import '../../support/fake_secure_storage.dart';

const _box = 'sec_test_box';
final _legacy = {
  'a': {'name': 'Mumbai', 'lat': 19.07},
  'b': {'name': 'Delhi', 'lat': 28.6},
};

void main() {
  late FakeSecureStorage fake;

  SecureHiveInitializer initializer() => SecureHiveInitializer(
    storage: fake.mock,
    keyStore: HiveEncryptionKeyStore(storage: fake.mock),
    boxNames: const [_box],
  );

  Future<void> seedPlaintext() async {
    final box = await Hive.openBox<dynamic>(_box);
    await box.putAll(_legacy);
    await box.close();
  }

  Future<Box<dynamic>> reopenEncrypted() async {
    final key = await HiveEncryptionKeyStore(storage: fake.mock).loadOrCreate();
    return Hive.openBox<dynamic>(_box, encryptionCipher: key.cipher);
  }

  setUp(() async {
    fake = FakeSecureStorage();
    for (final n in [_box, SecureHiveInitializer.stagingBoxName(_box)]) {
      if (Hive.isBoxOpen(n)) await Hive.box<dynamic>(n).close();
      await Hive.deleteBoxFromDisk(n);
    }
  });

  test('fresh install creates an encrypted box and marks it', () async {
    await initializer().openAll();
    await Hive.box<dynamic>(_box).put('k', 'v');
    await Hive.box<dynamic>(_box).close();

    expect(fake.values[SecureHiveInitializer.encryptedFlagKey(_box)], 'true');
    expect((await reopenEncrypted()).get('k'), 'v');
  });

  test('migrates an existing plaintext box without losing data', () async {
    await seedPlaintext();

    await initializer().openAll();

    final box = Hive.box<dynamic>(_box);
    expect(Map<dynamic, dynamic>.from(box.toMap()), _legacy);
    expect(fake.values[SecureHiveInitializer.encryptedFlagKey(_box)], 'true');
    expect(
      fake.values.containsKey(SecureHiveInitializer.stagedFlagKey(_box)),
      isFalse,
    );
    expect(
      await Hive.boxExists(SecureHiveInitializer.stagingBoxName(_box)),
      isFalse,
    );

    // The file on disk is genuinely encrypted: readable with the key.
    await box.close();
    expect((await reopenEncrypted()).get('a'), _legacy['a']);
  });

  test('is idempotent across launches', () async {
    await seedPlaintext();
    await initializer().openAll();
    await Hive.box<dynamic>(_box).close();

    await initializer().openAll();

    expect(
      Map<dynamic, dynamic>.from(Hive.box<dynamic>(_box).toMap()),
      _legacy,
    );
  });

  test('resumes after a crash between staging and replacement', () async {
    await seedPlaintext();
    // Simulate a crash after step 1: staged copy exists, marker set,
    // plaintext file still present.
    final key = await HiveEncryptionKeyStore(storage: fake.mock).loadOrCreate();
    final staging = await Hive.openBox<dynamic>(
      SecureHiveInitializer.stagingBoxName(_box),
      encryptionCipher: key.cipher,
    );
    await staging.putAll(_legacy);
    await staging.close();
    fake.values[SecureHiveInitializer.stagedFlagKey(_box)] = 'true';

    await initializer().openAll();

    expect(
      Map<dynamic, dynamic>.from(Hive.box<dynamic>(_box).toMap()),
      _legacy,
    );
    expect(fake.values[SecureHiveInitializer.encryptedFlagKey(_box)], 'true');
  });

  test('resumes after a crash with a partial staging copy', () async {
    await seedPlaintext();
    final key = await HiveEncryptionKeyStore(storage: fake.mock).loadOrCreate();
    final staging = await Hive.openBox<dynamic>(
      SecureHiveInitializer.stagingBoxName(_box),
      encryptionCipher: key.cipher,
    );
    await staging.put('a', _legacy['a']); // partial, no staged marker
    await staging.close();

    await initializer().openAll();

    expect(
      Map<dynamic, dynamic>.from(Hive.box<dynamic>(_box).toMap()),
      _legacy,
    );
  });

  test('unavailable secure storage: in-memory box, disk untouched', () async {
    await seedPlaintext();
    fake.failReads = true;

    await initializer().openAll();

    final box = Hive.box<dynamic>(_box);
    expect(box.isEmpty, isTrue);
    await box.put('x', 1); // app keeps working this session
    expect(capturedErrorLogs, isNotEmpty);
    await box.close();

    fake.failReads = false;
    await initializer().openAll();
    expect(
      Map<dynamic, dynamic>.from(Hive.box<dynamic>(_box).toMap()),
      _legacy,
    );
  });

  test('lost key: unreadable encrypted box is reset, not crashed on', () async {
    await initializer().openAll();
    await Hive.box<dynamic>(_box).put('k', 'v');
    await Hive.box<dynamic>(_box).close();
    fake.values.remove(HiveEncryptionKeyStore.storageKey); // keystore wiped

    await initializer().openAll();

    expect(Hive.box<dynamic>(_box).isEmpty, isTrue);
    expect(capturedErrorLogs.any((l) => l.context.contains(_box)), isTrue);
  });

  test('no secrets or box contents are logged', () async {
    await seedPlaintext();
    fake.failReads = true;
    await initializer().openAll();

    final logged = capturedErrorLogs.map((l) => '$l').join();
    expect(logged, isNot(contains('Mumbai')));
  });
}
