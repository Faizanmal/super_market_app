import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../config/constants.dart';
import 'package:uuid/uuid.dart';

/// Authentication provider for state management
/// Manages user authentication and session
class AuthProvider extends ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  
  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthenticated => _isLoggedIn; // Alias for compatibility
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isHeadOffice => _currentUser?.role == 'admin' || _currentUser?.role == 'manager'; // Assuming admin/manager are head office
  bool get canAudit => _currentUser?.canAudit ?? false;

  /// Initialize auth provider
  Future<void> init() async {
    await _checkLoginStatus();
  }

  /// Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;

    if (_isLoggedIn) {
      final userId = prefs.getString(AppConstants.keyCurrentUserId);
      if (userId != null) {
        _currentUser = _storageService.getUser(userId);
        if (_currentUser == null) {
          // User not found, logout
          await logout();
        }
      }
    }

    notifyListeners();
  }

  /// Login user
  Future<LoginResult> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Authenticate user
      final user = _storageService.authenticateUser(email, password);

      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return LoginResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      if (!user.isActive) {
        _isLoading = false;
        notifyListeners();
        return LoginResult(
          success: false,
          message: 'Your account has been deactivated',
        );
      }

      // Update last login
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      await _storageService.updateUser(updatedUser);

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyCurrentUserId, user.id);

      _currentUser = updatedUser;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();

      return LoginResult(
        success: true,
        message: 'Login successful',
        user: updatedUser,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Login error: $e');
      return LoginResult(
        success: false,
        message: 'An error occurred during login',
      );
    }
  }

  /// Register new user
  Future<RegisterResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if email already exists
      if (_storageService.emailExists(email)) {
        _isLoading = false;
        notifyListeners();
        return RegisterResult(
          success: false,
          message: 'Email already exists',
        );
      }

      // Create new user
      final newUser = User(
        id: const Uuid().v4(),
        email: email,
        password: password, // In production, hash this
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: 'staff', // Default role
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        isActive: true,
      );

      // Save user
      await _storageService.addUser(newUser);

      _isLoading = false;
      notifyListeners();

      return RegisterResult(
        success: true,
        message: 'Registration successful',
        user: newUser,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Registration error: $e');
      return RegisterResult(
        success: false,
        message: 'An error occurred during registration',
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyCurrentUserId);

    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
      );

      await _storageService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    try {
      // Verify current password
      if (_currentUser!.password != currentPassword) {
        return false;
      }

      // Update password
      final updatedUser = _currentUser!.copyWith(password: newPassword);
      await _storageService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error changing password: $e');
      return false;
    }
  }

  /// Get all users (admin only)
  List<User> getAllUsers() {
    if (!isAdmin) return [];
    return _storageService.getAllUsers();
  }

  /// Delete user (admin only)
  Future<bool> deleteUser(String userId) async {
    if (!isAdmin) return false;

    try {
      await _storageService.deleteUser(userId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  /// Toggle user active status (admin only)
  Future<bool> toggleUserStatus(String userId) async {
    if (!isAdmin) return false;

    try {
      final user = _storageService.getUser(userId);
      if (user == null) return false;

      final updatedUser = user.copyWith(isActive: !user.isActive);
      await _storageService.updateUser(updatedUser);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling user status: $e');
      return false;
    }
  }
}

/// Login result model
class LoginResult {
  final bool success;
  final String message;
  final User? user;

  LoginResult({
    required this.success,
    required this.message,
    this.user,
  });
}

/// Register result model
class RegisterResult {
  final bool success;
  final String message;
  final User? user;

  RegisterResult({
    required this.success,
    required this.message,
    this.user,
  });
}
