/// Local storage utilities
/// Provides simple key-value storage using SharedPreferences
library;

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  /// Initialize storage
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get string value
  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Set string value
  static Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  /// Get int value
  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// Set int value
  static Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  /// Get bool value
  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  /// Set bool value
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  /// Get double value
  static double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  /// Set double value
  static Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  /// Remove value
  static Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  /// Clear all data
  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  /// Check if key exists
  static bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
}