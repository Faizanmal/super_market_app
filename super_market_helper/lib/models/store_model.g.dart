// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Store _$StoreFromJson(Map<String, dynamic> json) => Store(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      managerId: (json['managerId'] as num?)?.toInt(),
      managerName: json['managerName'] as String?,
      layoutData: json['layoutData'] as Map<String, dynamic>?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$StoreToJson(Store instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'postalCode': instance.postalCode,
      'phone': instance.phone,
      'email': instance.email,
      'managerId': instance.managerId,
      'managerName': instance.managerName,
      'layoutData': instance.layoutData,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      companyName: json['companyName'] as String?,
      address: json['address'] as String?,
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
      storeId: (json['storeId'] as num?)?.toInt(),
      storeName: json['storeName'] as String?,
      employeeId: json['employeeId'] as String?,
      canReceiveStock: json['canReceiveStock'] as bool,
      canAudit: json['canAudit'] as bool,
      canManageStaff: json['canManageStaff'] as bool,
      canViewAnalytics: json['canViewAnalytics'] as bool,
      profilePicture: json['profilePicture'] as String?,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'phoneNumber': instance.phoneNumber,
      'companyName': instance.companyName,
      'address': instance.address,
      'role': _$UserRoleEnumMap[instance.role]!,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'employeeId': instance.employeeId,
      'canReceiveStock': instance.canReceiveStock,
      'canAudit': instance.canAudit,
      'canManageStaff': instance.canManageStaff,
      'canViewAnalytics': instance.canViewAnalytics,
      'profilePicture': instance.profilePicture,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.storeManager: 'store_manager',
  UserRole.stockReceiver: 'stock_receiver',
  UserRole.shelfStaff: 'shelf_staff',
  UserRole.auditor: 'auditor',
  UserRole.headOffice: 'head_office',
};
