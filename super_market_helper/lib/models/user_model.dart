import 'package:hive/hive.dart';
import '../config/constants.dart';
import 'store_models.dart';

part 'user_model.g.dart';

/// User model for authentication and user management
/// Stores user credentials and profile information
@HiveType(typeId: AppConstants.userTypeId)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  String password; // In production, this should be hashed

  @HiveField(3)
  String fullName;

  @HiveField(4)
  String? phoneNumber;

  @HiveField(5)
  String role; // e.g., 'admin', 'manager', 'staff'

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime lastLogin;

  @HiveField(8)
  bool isActive;

  @HiveField(9)
  String? profileImageUrl;

  @HiveField(10)
  Store? store;

  @HiveField(11)
  bool canAudit = false;

  @HiveField(12)
  bool canReceiveStock = false;

  @HiveField(13)
  bool canManageStaff = false;

  @HiveField(14)
  bool canViewAnalytics = false;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    this.phoneNumber,
    this.role = 'staff',
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
    this.profileImageUrl,
    this.store,
    this.canAudit = false,
    this.canReceiveStock = false,
    this.canManageStaff = false,
    this.canViewAnalytics = false,
  });

  /// Create a copy of the user with updated fields
  User copyWith({
    String? id,
    String? email,
    String? password,
    String? fullName,
    String? phoneNumber,
    String? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    String? profileImageUrl,
    Store? store,
    bool? canAudit,
    bool? canReceiveStock,
    bool? canManageStaff,
    bool? canViewAnalytics,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      store: store ?? this.store,
      canAudit: canAudit ?? this.canAudit,
      canReceiveStock: canReceiveStock ?? this.canReceiveStock,
      canManageStaff: canManageStaff ?? this.canManageStaff,
      canViewAnalytics: canViewAnalytics ?? this.canViewAnalytics,
    );
  }

  /// Convert user to JSON map (excluding password for security)
  Map<String, dynamic> toJson({bool includePassword = false}) {
    final map = {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'store': store?.toJson(),
    };
    
    if (includePassword) {
      map['password'] = password;
    }
    
    return map;
  }

  /// Create user from JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String? ?? 'staff',
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      isActive: json['isActive'] as bool? ?? true,
      profileImageUrl: json['profileImageUrl'] as String?,
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: $role)';
  }
}
