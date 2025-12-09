// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpiryAlert _$ExpiryAlertFromJson(Map<String, dynamic> json) => ExpiryAlert(
      id: (json['id'] as num).toInt(),
      batchId: (json['batchId'] as num).toInt(),
      productName: json['productName'] as String,
      batchNumber: json['batchNumber'] as String,
      storeId: (json['storeId'] as num).toInt(),
      storeName: json['storeName'] as String,
      shelfLocationId: (json['shelfLocationId'] as num?)?.toInt(),
      locationCode: json['locationCode'] as String?,
      severity: $enumDecode(_$AlertSeverityEnumMap, json['severity']),
      daysUntilExpiry: (json['daysUntilExpiry'] as num).toInt(),
      quantityAtRisk: (json['quantityAtRisk'] as num).toInt(),
      currentQuantity: (json['currentQuantity'] as num).toInt(),
      estimatedLoss: (json['estimatedLoss'] as num).toDouble(),
      suggestedAction:
          $enumDecode(_$SuggestedActionEnumMap, json['suggestedAction']),
      suggestedDiscount: (json['suggestedDiscount'] as num?)?.toDouble(),
      isAcknowledged: json['isAcknowledged'] as bool,
      acknowledgedBy: (json['acknowledgedBy'] as num?)?.toInt(),
      acknowledgedByName: json['acknowledgedByName'] as String?,
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
      isResolved: json['isResolved'] as bool,
      resolutionAction: $enumDecodeNullable(
          _$SuggestedActionEnumMap, json['resolutionAction']),
      resolvedBy: (json['resolvedBy'] as num?)?.toInt(),
      resolvedByName: json['resolvedByName'] as String?,
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      resolutionNotes: json['resolutionNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ExpiryAlertToJson(ExpiryAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batchId': instance.batchId,
      'productName': instance.productName,
      'batchNumber': instance.batchNumber,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'shelfLocationId': instance.shelfLocationId,
      'locationCode': instance.locationCode,
      'severity': _$AlertSeverityEnumMap[instance.severity]!,
      'daysUntilExpiry': instance.daysUntilExpiry,
      'quantityAtRisk': instance.quantityAtRisk,
      'estimatedLoss': instance.estimatedLoss,
      'suggestedAction': _$SuggestedActionEnumMap[instance.suggestedAction]!,
      'suggestedDiscount': instance.suggestedDiscount,
      'isAcknowledged': instance.isAcknowledged,
      'acknowledgedBy': instance.acknowledgedBy,
      'acknowledgedByName': instance.acknowledgedByName,
      'acknowledgedAt': instance.acknowledgedAt?.toIso8601String(),
      'isResolved': instance.isResolved,
      'resolutionAction': _$SuggestedActionEnumMap[instance.resolutionAction],
      'resolvedBy': instance.resolvedBy,
      'resolvedByName': instance.resolvedByName,
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'resolutionNotes': instance.resolutionNotes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$AlertSeverityEnumMap = {
  AlertSeverity.critical: 'critical',
  AlertSeverity.high: 'high',
  AlertSeverity.medium: 'medium',
  AlertSeverity.low: 'low',
};

const _$SuggestedActionEnumMap = {
  SuggestedAction.discount: 'discount',
  SuggestedAction.clearance: 'clearance',
  SuggestedAction.returnToSupplier: 'return',
  SuggestedAction.dispose: 'dispose',
  SuggestedAction.none: 'none',
};
