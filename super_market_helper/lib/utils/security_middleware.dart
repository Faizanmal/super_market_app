import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../config/api_config.dart';

/// Security middleware for authentication, authorization, and data protection
class SecurityMiddleware {
  static final SecurityMiddleware _instance = SecurityMiddleware._internal();
  factory SecurityMiddleware() => _instance;
  SecurityMiddleware._internal();

  final _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // === BIOMETRIC AUTHENTICATION ===

  /// Check if biometric authentication is available on device
  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate user with biometrics
  Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access the app',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
      );
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  // === SECURE STORAGE ===

  /// Save encrypted data to secure storage
  Future<void> saveSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('Error saving to secure storage: $e');
      rethrow;
    }
  }

  /// Read encrypted data from secure storage
  Future<String?> readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('Error reading from secure storage: $e');
      return null;
    }
  }

  /// Delete data from secure storage
  Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('Error deleting from secure storage: $e');
    }
  }

  /// Clear all secure storage
  Future<void> clearAllSecure() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing secure storage: $e');
    }
  }

  // === TOKEN MANAGEMENT ===

  /// Save authentication tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveSecure(ApiConfig.storageKeyAccessToken, accessToken);
    await saveSecure(ApiConfig.storageKeyRefreshToken, refreshToken);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await readSecure(ApiConfig.storageKeyAccessToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await readSecure(ApiConfig.storageKeyRefreshToken);
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    await deleteSecure(ApiConfig.storageKeyAccessToken);
    await deleteSecure(ApiConfig.storageKeyRefreshToken);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Decode JWT token
  Map<String, dynamic>? decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded);
    } catch (e) {
      debugPrint('Error decoding JWT: $e');
      return null;
    }
  }

  /// Check if token is expired
  bool isTokenExpired(String token) {
    final payload = decodeJwt(token);
    if (payload == null) return true;

    final exp = payload['exp'];
    if (exp == null) return true;

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final now = DateTime.now();
    
    // Check if token expires within threshold
    final threshold = Duration(seconds: ApiConfig.tokenRefreshThreshold);
    return expiryDate.isBefore(now.add(threshold));
  }

  // === USER DATA MANAGEMENT ===

  /// Save user data
  Future<void> saveUserData({
    required int userId,
    required String username,
    required String email,
    String? role,
  }) async {
    await saveSecure(ApiConfig.storageKeyUserId, userId.toString());
    await saveSecure(ApiConfig.storageKeyUsername, username);
    await saveSecure(ApiConfig.storageKeyEmail, email);
    if (role != null) {
      await saveSecure(ApiConfig.storageKeyUserRole, role);
    }
  }

  /// Get user ID
  Future<int?> getUserId() async {
    final userIdStr = await readSecure(ApiConfig.storageKeyUserId);
    return userIdStr != null ? int.tryParse(userIdStr) : null;
  }

  /// Get username
  Future<String?> getUsername() async {
    return await readSecure(ApiConfig.storageKeyUsername);
  }

  /// Get email
  Future<String?> getEmail() async {
    return await readSecure(ApiConfig.storageKeyEmail);
  }

  /// Get user role
  Future<String?> getUserRole() async {
    return await readSecure(ApiConfig.storageKeyUserRole);
  }

  /// Clear user data
  Future<void> clearUserData() async {
    await deleteSecure(ApiConfig.storageKeyUserId);
    await deleteSecure(ApiConfig.storageKeyUsername);
    await deleteSecure(ApiConfig.storageKeyEmail);
    await deleteSecure(ApiConfig.storageKeyUserRole);
  }

  // === ENCRYPTION & HASHING ===

  /// Generate SHA-256 hash
  String generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate SHA-256 hash from JSON data
  String generateJsonHash(Map<String, dynamic> data) {
    final jsonString = json.encode(data);
    return generateHash(jsonString);
  }

  /// Generate request signature
  String generateRequestSignature({
    required String method,
    required String path,
    required String timestamp,
    String? body,
  }) {
    final components = [method, path, timestamp];
    if (body != null && body.isNotEmpty) {
      components.add(body);
    }
    final message = components.join('|');
    return generateHash(message);
  }

  /// Verify response signature
  bool verifyResponseSignature({
    required String responseBody,
    required String signature,
  }) {
    final expectedSignature = generateHash(responseBody);
    return expectedSignature == signature;
  }

  // === PASSWORD SECURITY ===

  /// Validate password strength
  Map<String, dynamic> validatePasswordStrength(String password) {
    final feedback = <String>[];
    final result = {
      'isValid': false,
      'score': 0,
      'feedback': feedback,
    };

    if (password.length < 8) {
      feedback.add('Password must be at least 8 characters long');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      feedback.add('Password must contain at least one uppercase letter');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      feedback.add('Password must contain at least one lowercase letter');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      feedback.add('Password must contain at least one number');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      feedback.add('Password must contain at least one special character');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    result['isValid'] = (result['score'] as int) >= 4;
    return result;
  }

  /// Hash password (for local verification only - never send to server)
  String hashPassword(String password) {
    return generateHash(password);
  }

  // === SESSION MANAGEMENT ===

  /// Save session data
  Future<void> saveSession(Map<String, dynamic> sessionData) async {
    await saveSecure('session_data', json.encode(sessionData));
  }

  /// Get session data
  Future<Map<String, dynamic>?> getSession() async {
    final sessionStr = await readSecure('session_data');
    if (sessionStr == null) return null;
    return json.decode(sessionStr);
  }

  /// Clear session
  Future<void> clearSession() async {
    await deleteSecure('session_data');
  }

  /// Generate session ID
  String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return generateHash('$timestamp-$random');
  }

  // === PERMISSION CHECKS ===

  /// Check if user has required role
  Future<bool> hasRole(String requiredRole) async {
    final userRole = await getUserRole();
    if (userRole == null) return false;

    // Role hierarchy: admin > manager > staff > user
    const roleHierarchy = ['admin', 'manager', 'staff', 'user'];
    final userRoleIndex = roleHierarchy.indexOf(userRole.toLowerCase());
    final requiredRoleIndex = roleHierarchy.indexOf(requiredRole.toLowerCase());

    if (userRoleIndex == -1 || requiredRoleIndex == -1) return false;
    return userRoleIndex <= requiredRoleIndex;
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role?.toLowerCase() == 'admin';
  }

  /// Check if user is manager
  Future<bool> isManager() async {
    final role = await getUserRole();
    return role?.toLowerCase() == 'manager' || await isAdmin();
  }

  // === SECURITY UTILITIES ===

  /// Generate random string for nonce/salt
  String generateRandomString(int length) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final hash = generateHash('$timestamp-$random');
    return hash.substring(0, length.clamp(1, hash.length));
  }

  /// Generate request ID for tracking
  String generateRequestId() {
    return generateRandomString(32);
  }

  /// Get current timestamp in ISO 8601 format
  String getCurrentTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  /// Sanitize input (prevent XSS)
  String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number format
  bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  // === LOGOUT & CLEANUP ===

  /// Complete logout (clear all sensitive data)
  Future<void> logout() async {
    await clearTokens();
    await clearUserData();
    await clearSession();
    debugPrint('User logged out, all secure data cleared');
  }

  /// Emergency wipe (clear all app data)
  Future<void> emergencyWipe() async {
    await clearAllSecure();
    debugPrint('Emergency wipe completed');
  }
}
