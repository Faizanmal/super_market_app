// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receiving_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceivingLog _$ReceivingLogFromJson(Map<String, dynamic> json) => ReceivingLog(
      id: (json['id'] as num).toInt(),
      receiptNumber: json['receiptNumber'] as String,
      shipmentNumber: json['shipmentNumber'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      purchaseOrder: json['purchaseOrder'] as String?,
      supplierId: (json['supplierId'] as num?)?.toInt(),
      supplierName: json['supplierName'] as String?,
      storeId: (json['storeId'] as num).toInt(),
      storeName: json['storeName'] as String,
      receivedDate: DateTime.parse(json['receivedDate'] as String),
      batchIds: (json['batchIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      batchCount: (json['batchCount'] as num).toInt(),
      palletPhoto: json['palletPhoto'] as String?,
      invoicePhoto: json['invoicePhoto'] as String?,
      hasExpiryIssues: json['hasExpiryIssues'] as bool,
      validationNotes: json['validationNotes'] as String?,
      totalItems: (json['totalItems'] as num).toInt(),
      totalValue: (json['totalValue'] as num).toDouble(),
      status: $enumDecode(_$ReceivingStatusEnumMap, json['status']),
      receivedById: (json['receivedById'] as num?)?.toInt(),
      receivedByName: json['receivedByName'] as String?,
      approvedById: (json['approvedById'] as num?)?.toInt(),
      approvedByName: json['approvedByName'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ReceivingLogToJson(ReceivingLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'receiptNumber': instance.receiptNumber,
      'shipmentNumber': instance.shipmentNumber,
      'invoiceNumber': instance.invoiceNumber,
      'purchaseOrder': instance.purchaseOrder,
      'supplierId': instance.supplierId,
      'supplierName': instance.supplierName,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'receivedDate': instance.receivedDate.toIso8601String(),
      'batchIds': instance.batchIds,
      'batchCount': instance.batchCount,
      'palletPhoto': instance.palletPhoto,
      'invoicePhoto': instance.invoicePhoto,
      'hasExpiryIssues': instance.hasExpiryIssues,
      'validationNotes': instance.validationNotes,
      'totalItems': instance.totalItems,
      'totalValue': instance.totalValue,
      'status': _$ReceivingStatusEnumMap[instance.status]!,
      'receivedById': instance.receivedById,
      'receivedByName': instance.receivedByName,
      'approvedById': instance.approvedById,
      'approvedByName': instance.approvedByName,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ReceivingStatusEnumMap = {
  ReceivingStatus.pending: 'pending',
  ReceivingStatus.approved: 'approved',
  ReceivingStatus.partial: 'partial',
  ReceivingStatus.rejected: 'rejected',
};

PhotoEvidence _$PhotoEvidenceFromJson(Map<String, dynamic> json) =>
    PhotoEvidence(
      id: (json['id'] as num).toInt(),
      image: json['image'] as String,
      caption: json['caption'] as String?,
      description: json['description'] as String?,
      photoType: $enumDecode(_$PhotoTypeEnumMap, json['photoType']),
      batchId: (json['batchId'] as num?)?.toInt(),
      receivingLogId: (json['receivingLogId'] as num?)?.toInt(),
      auditId: (json['auditId'] as num?)?.toInt(),
      taskId: (json['taskId'] as num?)?.toInt(),
      shelfLocationId: (json['shelfLocationId'] as num?)?.toInt(),
      storeId: (json['storeId'] as num).toInt(),
      uploadedById: (json['uploadedById'] as num?)?.toInt(),
      uploadedByName: json['uploadedByName'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PhotoEvidenceToJson(PhotoEvidence instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image': instance.image,
      'caption': instance.caption,
      'description': instance.description,
      'photoType': _$PhotoTypeEnumMap[instance.photoType]!,
      'batchId': instance.batchId,
      'receivingLogId': instance.receivingLogId,
      'auditId': instance.auditId,
      'taskId': instance.taskId,
      'shelfLocationId': instance.shelfLocationId,
      'storeId': instance.storeId,
      'uploadedById': instance.uploadedById,
      'uploadedByName': instance.uploadedByName,
      'uploadedAt': instance.uploadedAt.toIso8601String(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

const _$PhotoTypeEnumMap = {
  PhotoType.receiving: 'receiving',
  PhotoType.shelfPlacement: 'shelf_placement',
  PhotoType.audit: 'audit',
  PhotoType.taskCompletion: 'task_completion',
  PhotoType.expiryIssue: 'expiry_issue',
  PhotoType.damage: 'damage',
  PhotoType.other: 'other',
};
