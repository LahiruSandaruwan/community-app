import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'logger.dart';

/// Secure storage service for sensitive data
/// Uses platform-specific secure storage (Keychain on iOS, KeyStore on Android)
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final Logger _logger = Logger.forClass(SecureStorage);

  // Storage instance with configuration
  late final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Storage keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyFcmToken = 'fcm_token';

  /// Write a value to secure storage
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      _logger.debug('Wrote value to secure storage: $key');
    } catch (e) {
      _logger.error('Failed to write to secure storage: $key', error: e);
      rethrow;
    }
  }

  /// Read a value from secure storage
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      _logger.debug('Read value from secure storage: $key');
      return value;
    } catch (e) {
      _logger.error('Failed to read from secure storage: $key', error: e);
      return null;
    }
  }

  /// Delete a value from secure storage
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      _logger.debug('Deleted value from secure storage: $key');
    } catch (e) {
      _logger.error('Failed to delete from secure storage: $key', error: e);
      rethrow;
    }
  }

  /// Delete all values from secure storage
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _logger.info('Cleared all secure storage');
    } catch (e) {
      _logger.error('Failed to clear secure storage', error: e);
      rethrow;
    }
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      _logger.error('Failed to check key in secure storage: $key', error: e);
      return false;
    }
  }

  // ========== Authentication Token Methods ==========

  /// Save authentication token securely
  Future<void> saveAuthToken(String token) async {
    await write(_keyAuthToken, token);
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await read(_keyAuthToken);
  }

  /// Delete authentication token
  Future<void> deleteAuthToken() async {
    await delete(_keyAuthToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await write(_keyRefreshToken, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await read(_keyRefreshToken);
  }

  // ========== User Data Methods ==========

  /// Save user ID securely
  Future<void> saveUserId(String userId) async {
    await write(_keyUserId, userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await read(_keyUserId);
  }

  /// Save user email
  Future<void> saveUserEmail(String email) async {
    await write(_keyUserEmail, email);
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    return await read(_keyUserEmail);
  }

  // ========== FCM Token Methods ==========

  /// Save FCM token
  Future<void> saveFcmToken(String token) async {
    await write(_keyFcmToken, token);
  }

  /// Get FCM token
  Future<String?> getFcmToken() async {
    return await read(_keyFcmToken);
  }

  /// Delete FCM token
  Future<void> deleteFcmToken() async {
    await delete(_keyFcmToken);
  }

  // ========== Session Management ==========

  /// Save complete user session
  Future<void> saveUserSession({
    required String userId,
    required String email,
    String? authToken,
    String? refreshToken,
  }) async {
    await Future.wait([
      saveUserId(userId),
      saveUserEmail(email),
      if (authToken != null) saveAuthToken(authToken),
      if (refreshToken != null) saveRefreshToken(refreshToken),
    ]);
    _logger.info('User session saved securely');
  }

  /// Clear user session (logout)
  Future<void> clearUserSession() async {
    await Future.wait([
      deleteAuthToken(),
      delete(_keyUserId),
      delete(_keyUserEmail),
      delete(_keyRefreshToken),
    ]);
    _logger.info('User session cleared');
  }

  /// Check if user session exists
  Future<bool> hasUserSession() async {
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }
}
