import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../error/app_failure.dart';

/// Encrypted storage for secrets (tokens, keys). Backed by Keychain on iOS
/// and Keystore-based encryption on Android.
///
/// Implementations throw [StorageFailure] on platform errors.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) =>
      _wrap(() => _storage.read(key: key), 'read');

  @override
  Future<void> write(String key, String value) =>
      _wrap(() => _storage.write(key: key, value: value), 'write');

  @override
  Future<void> delete(String key) =>
      _wrap(() => _storage.delete(key: key), 'delete');

  Future<T> _wrap<T>(Future<T> Function() body, String op) async {
    try {
      return await body();
    } catch (error) {
      // Key names are not secret; values are never included in the message.
      throw StorageFailure('Secure storage $op failed', error);
    }
  }
}

/// Volatile implementation for tests and previews.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}
