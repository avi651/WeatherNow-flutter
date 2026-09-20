import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// The Hive encryption key plus whether this call had to generate it.
///
/// [wasCreated] matters to the caller: if a key was just created, any box
/// previously marked as encrypted was encrypted with a key that no longer
/// exists (e.g. the Keychain/Keystore was wiped) and cannot be read.
class HiveEncryptionKey {
  const HiveEncryptionKey({required this.bytes, required this.wasCreated});

  final List<int> bytes;
  final bool wasCreated;

  HiveAesCipher get cipher => HiveAesCipher(bytes);
}

/// Generates, stores and retrieves the Hive AES key using
/// `flutter_secure_storage` (iOS Keychain / Android Keystore-backed
/// EncryptedSharedPreferences). The key is generated on the device with a
/// cryptographically secure RNG the first time it is needed; nothing is
/// hardcoded or shipped with the app.
class HiveEncryptionKeyStore {
  HiveEncryptionKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? defaultStorage;

  /// `first_unlock_this_device` keeps the key out of iCloud/device
  /// backups and still lets the app read it after the first unlock.
  static const defaultStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const storageKey = 'weather_now_hive_encryption_key';
  static const _keyLength = 32;

  final FlutterSecureStorage _storage;

  /// Returns the stored key, or generates and persists a new one. Throws
  /// if secure storage is unavailable — callers must handle that (see
  /// `SecureHiveInitializer`).
  Future<HiveEncryptionKey> loadOrCreate() async {
    final stored = await _storage.read(key: storageKey);
    final existing = _decode(stored);
    if (existing != null) {
      return HiveEncryptionKey(bytes: existing, wasCreated: false);
    }

    final fresh = Hive.generateSecureKey();
    await _storage.write(key: storageKey, value: base64Url.encode(fresh));
    return HiveEncryptionKey(bytes: fresh, wasCreated: true);
  }

  static List<int>? _decode(String? value) {
    if (value == null) return null;
    try {
      final bytes = base64Url.decode(value);
      return bytes.length == _keyLength ? Uint8List.fromList(bytes) : null;
    } on FormatException {
      return null;
    }
  }
}
