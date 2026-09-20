import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/error/error_logger.dart';
import '../../core/security/hive_encryption_key_store.dart';
import 'hive_boxes.dart';

/// Opens every [HiveBoxes] box AES-encrypted, migrating existing
/// unencrypted boxes without losing data. Box names, keys and values are
/// unchanged. Hive itself (`Hive.init`/`initFlutter`) must already have run.
///
/// Hive cannot encrypt a box in place, and opening a box with the wrong
/// cipher can make Hive's crash recovery truncate the file. So the state of
/// each box is tracked explicitly in secure storage rather than guessed:
///
/// * `hive_box_encrypted_<box>` — the box file is encrypted.
/// * `hive_box_staged_<box>` — a complete encrypted copy of the plaintext
///   data exists in `<box>_migration`.
///
/// Migration per plaintext box (each step is safe to repeat after a crash):
/// 1. copy every entry into the encrypted `<box>_migration` box, verify it,
///    set *staged* (the plaintext file is still untouched);
/// 2. delete the plaintext box, copy the staged data into the encrypted
///    box, verify it, set *encrypted*;
/// 3. delete the staging box and the *staged* marker.
///
/// If anything fails for a box, the disk is left as it is (so the next
/// launch retries) and the box is opened as an empty in-memory box for this
/// session — the app keeps working and no stored data is overwritten.
class SecureHiveInitializer {
  SecureHiveInitializer({
    HiveEncryptionKeyStore? keyStore,
    FlutterSecureStorage? storage,
    List<String>? boxNames,
  }) : _storage = storage ?? HiveEncryptionKeyStore.defaultStorage,
       _boxNames = boxNames ?? HiveBoxes.names {
    _keyStore = keyStore ?? HiveEncryptionKeyStore(storage: _storage);
  }

  final FlutterSecureStorage _storage;
  late final HiveEncryptionKeyStore _keyStore;
  final List<String> _boxNames;

  static String encryptedFlagKey(String box) => 'hive_box_encrypted_$box';
  static String stagedFlagKey(String box) => 'hive_box_staged_$box';
  static String stagingBoxName(String box) => '${box}_migration';

  /// Never throws.
  Future<void> openAll() async {
    HiveEncryptionKey? key;
    try {
      key = await _keyStore.loadOrCreate();
    } catch (e, st) {
      logError('Hive encryption key unavailable', e, st);
    }

    for (final name in _boxNames) {
      try {
        if (key == null) {
          throw StateError('no encryption key');
        }
        await _openEncrypted(name, key);
      } catch (e, st) {
        logError('Hive box "$name" opened in memory only', e, st);
        await _openInMemory(name);
      }
    }
  }

  Future<void> _openInMemory(String name) async {
    if (Hive.isBoxOpen(name)) await Hive.box<dynamic>(name).close();
    await Hive.openBox<dynamic>(name, bytes: Uint8List(0));
  }

  Future<bool> _flag(String key) async =>
      (await _storage.read(key: key)) == 'true';

  Future<void> _openEncrypted(String name, HiveEncryptionKey key) async {
    final cipher = key.cipher;
    final encryptedKey = encryptedFlagKey(name);
    final stagedKey = stagedFlagKey(name);
    final stagingName = stagingBoxName(name);

    var encrypted = await _flag(encryptedKey);

    if (encrypted && key.wasCreated) {
      // The key this box was encrypted with is gone, so its contents are
      // unrecoverable. Start clean instead of failing on every launch.
      logError(
        'Hive box "$name"',
        'Encryption key was lost; discarding unreadable encrypted data.',
      );
      await Hive.deleteBoxFromDisk(name);
      await _storage.delete(key: encryptedKey);
      encrypted = false;
    }

    if (encrypted) {
      await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
      // Finish cleanup if a previous launch stopped after step 2.
      if (await Hive.boxExists(stagingName)) {
        await Hive.deleteBoxFromDisk(stagingName);
      }
      await _storage.delete(key: stagedKey);
      return;
    }

    final staged = await _flag(stagedKey);
    if (!staged) {
      if (!await Hive.boxExists(name)) {
        // Fresh install (or box discarded above): create it encrypted.
        await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
        await _storage.write(key: encryptedKey, value: 'true');
        return;
      }
      await _stage(name, stagingName, cipher);
      await _storage.write(key: stagedKey, value: 'true');
    }

    // Step 2: replace the plaintext box with the encrypted one.
    await Hive.deleteBoxFromDisk(name);
    final target = await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    final staging = await Hive.openBox<dynamic>(
      stagingName,
      encryptionCipher: cipher,
    );
    final data = Map<dynamic, dynamic>.from(staging.toMap());
    await target.putAll(data);
    _verify(target, data);
    await _storage.write(key: encryptedKey, value: 'true');

    // Step 3: cleanup.
    await staging.close();
    await Hive.deleteBoxFromDisk(stagingName);
    await _storage.delete(key: stagedKey);
  }

  /// Step 1: copies the plaintext box into an encrypted staging box.
  Future<void> _stage(
    String name,
    String stagingName,
    HiveCipher cipher,
  ) async {
    final plain = await Hive.openBox<dynamic>(name);
    final data = Map<dynamic, dynamic>.from(plain.toMap());
    await plain.close();

    if (await Hive.boxExists(stagingName)) {
      await Hive.deleteBoxFromDisk(stagingName); // stale partial copy
    }
    final staging = await Hive.openBox<dynamic>(
      stagingName,
      encryptionCipher: cipher,
    );
    await staging.putAll(data);
    _verify(staging, data);
    await staging.close();
  }

  void _verify(Box<dynamic> box, Map<dynamic, dynamic> expected) {
    if (box.length != expected.length ||
        !expected.keys.every(box.containsKey)) {
      throw StateError('Encrypted copy of "${box.name}" does not match source');
    }
  }
}
