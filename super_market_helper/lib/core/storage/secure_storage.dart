import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data like tokens.
/// Uses platform-specific secure storage (Keychain on iOS, Keystore on Android).
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Write a value to secure storage
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value from secure storage
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete a value from secure storage
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Delete all values
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Read all values
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
