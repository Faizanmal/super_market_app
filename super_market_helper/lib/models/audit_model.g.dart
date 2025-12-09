// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShelfAudit _$ShelfAuditFromJson(Map<String, dynamic> json) => ShelfAudit(
      id: (json['id'] as num).toInt(),
      auditNumber: json['auditNumber'] as String,
      auditDate: DateTime.parse(json['auditDate'] as String),
      storeId: (json['storeId'] as num).toInt(),
      storeName: json['storeName'] as String,
      shelfLocationId: (json['shelfLocationId'] as num?)?.toInt(),
      locationCode: json['locationCode'] as String?,
      scope: $enumDecode(_$AuditScopeEnumMap, json['scope']),
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
      itemsChecked: (json['itemsChecked'] as num).toInt(),
      itemsExpired: (json['itemsExpired'] as num).toInt(),
      itemsNearExpiry: (json['itemsNearExpiry'] as num).toInt(),
      itemsDamaged: (json['itemsDamaged'] as num).toInt(),
      itemsMisplaced: (json['itemsMisplaced'] as num).toInt(),
      auditPhotos: (json['auditPhotos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: $enumDecode(_$AuditStatusEnumMap, json['status']),
      auditorId: (json['auditorId'] as num?)?.toInt(),
      auditorName: json['auditorName'] as String?,
      notes: json['notes'] as String?,
      actionRequired: json['actionRequired'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ShelfAuditToJson(ShelfAudit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'auditNumber': instance.auditNumber,
      'auditDate': instance.auditDate.toIso8601String(),
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'shelfLocationId': instance.shelfLocationId,
      'locationCode': instance.locationCode,
      'scope': _$AuditScopeEnumMap[instance.scope]!,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'itemsChecked': instance.itemsChecked,
      'itemsExpired': instance.itemsExpired,
      'itemsNearExpiry': instance.itemsNearExpiry,
      'itemsDamaged': instance.itemsDamaged,
      'itemsMisplaced': instance.itemsMisplaced,
      'auditPhotos': instance.auditPhotos,
      'status': _$AuditStatusEnumMap[instance.status]!,
      'auditorId': instance.auditorId,
      'auditorName': instance.auditorName,
      'notes': instance.notes,
      'actionRequired': instance.actionRequired,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$AuditScopeEnumMap = {
  AuditScope.fullStore: 'full_store',
  AuditScope.category: 'category',
  AuditScope.location: 'location',
  AuditScope.random: 'random',
};

const _$AuditStatusEnumMap = {
  AuditStatus.inProgress: 'in_progress',
  AuditStatus.completed: 'completed',
  AuditStatus.flagged: 'flagged',
};

AuditItem _$AuditItemFromJson(Map<String, dynamic> json) => AuditItem(
      id: (json['id'] as num).toInt(),
      auditId: (json['auditId'] as num).toInt(),
      batchId: (json['batchId'] as num).toInt(),
      productName: json['productName'] as String,
      batchNumber: json['batchNumber'] as String,
      quantityFound: (json['quantityFound'] as num).toInt(),
      quantityExpected: (json['quantityExpected'] as num?)?.toInt(),
      status: $enumDecode(_$AuditItemStatusEnumMap, json['status']),
      photo: json['photo'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AuditItemToJson(AuditItem instance) => <String, dynamic>{
      'id': instance.id,
      'auditId': instance.auditId,
      'batchId': instance.batchId,
      'productName': instance.productName,
      'batchNumber': instance.batchNumber,
      'quantityFound': instance.quantityFound,
      'quantityExpected': instance.quantityExpected,
      'status': _$AuditItemStatusEnumMap[instance.status]!,
      'photo': instance.photo,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$AuditItemStatusEnumMap = {
  AuditItemStatus.ok: 'ok',
  AuditItemStatus.expired: 'expired',
  AuditItemStatus.nearExpiry: 'near_expiry',
  AuditItemStatus.damaged: 'damaged',
  AuditItemStatus.misplaced: 'misplaced',
};
