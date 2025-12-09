// Store/Branch Model
import 'package:json_annotation/json_annotation.dart';

part 'store_model.g.dart';

@JsonSerializable()
class Store {
  final int id;
  final String name;
  final String code;
  final String address;
  final String city;
  final String? state;
  final String? postalCode;
  final String? phone;
  final String? email;
  final int? managerId;
  final String? managerName;
  final Map<String, dynamic>? layoutData;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Store({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.city,
    this.state,
    this.postalCode,
    this.phone,
    this.email,
    this.managerId,
    this.managerName,
    this.layoutData,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);
  Map<String, dynamic> toJson() => _$StoreToJson(this);

  String get fullAddress {
    final parts = [address, city, state, postalCode];
    return parts.where((p) => p != null && p.isNotEmpty).join(', ');
  }
}

// User Model with Roles
@JsonSerializable()
class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? companyName;
  final String? address;
  
  // Role and permissions
  final UserRole role;
  final int? storeId;
  final String? storeName;
  final String? employeeId;
  
  // Permissions
  final bool canReceiveStock;
  final bool canAudit;
  final bool canManageStaff;
  final bool canViewAnalytics;
  
  final String? profilePicture;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.companyName,
    this.address,
    required this.role,
    this.storeId,
    this.storeName,
    this.employeeId,
    required this.canReceiveStock,
    required this.canAudit,
    required this.canManageStaff,
    required this.canViewAnalytics,
    this.profilePicture,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get fullName => '$firstName $lastName'.trim();
  
  String get roleDisplayName {
    switch (role) {
      case UserRole.storeManager:
        return 'Store Manager';
      case UserRole.stockReceiver:
        return 'Stock Receiver';
      case UserRole.shelfStaff:
        return 'Shelf Staff';
      case UserRole.auditor:
        return 'Auditor/QA';
      case UserRole.headOffice:
        return 'Head Office Admin';
    }
  }
}

enum UserRole {
  @JsonValue('store_manager')
  storeManager,
  
  @JsonValue('stock_receiver')
  stockReceiver,
  
  @JsonValue('shelf_staff')
  shelfStaff,
  
  @JsonValue('auditor')
  auditor,
  
  @JsonValue('head_office')
  headOffice,
}
