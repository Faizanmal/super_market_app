// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductBatch _$ProductBatchFromJson(Map<String, dynamic> json) => ProductBatch(
      id: (json['id'] as num).toInt(),
      gtin: json['gtin'] as String,
      batchNumber: json['batchNumber'] as String,
      gs1Barcode: json['gs1Barcode'] as String?,
      productId: (json['productId'] as num).toInt(),
      productName: json['productName'] as String,
      productImage: json['productImage'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      originalQuantity: (json['originalQuantity'] as num).toInt(),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      manufactureDate: json['manufactureDate'] == null
          ? null
          : DateTime.parse(json['manufactureDate'] as String),
      receivedDate: DateTime.parse(json['receivedDate'] as String),
      supplierId: (json['supplierId'] as num?)?.toInt(),
      supplierName: json['supplierName'] as String?,
      shipmentNumber: json['shipmentNumber'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      purchaseOrder: json['purchaseOrder'] as String?,
      unitCost: (json['unitCost'] as num).toDouble(),
      unitSellingPrice: (json['unitSellingPrice'] as num).toDouble(),
      status: $enumDecode(_$BatchStatusEnumMap, json['status']),
      storeId: (json['storeId'] as num).toInt(),
      storeName: json['storeName'] as String,
      receivedBy: (json['receivedBy'] as num?)?.toInt(),
      receivedByName: json['receivedByName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ProductBatchToJson(ProductBatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gtin': instance.gtin,
      'batchNumber': instance.batchNumber,
      'gs1Barcode': instance.gs1Barcode,
      'productId': instance.productId,
      'productName': instance.productName,
      'productImage': instance.productImage,
      'quantity': instance.quantity,
      'originalQuantity': instance.originalQuantity,
      'expiryDate': instance.expiryDate.toIso8601String(),
      'manufactureDate': instance.manufactureDate?.toIso8601String(),
      'receivedDate': instance.receivedDate.toIso8601String(),
      'supplierId': instance.supplierId,
      'supplierName': instance.supplierName,
      'shipmentNumber': instance.shipmentNumber,
      'invoiceNumber': instance.invoiceNumber,
      'purchaseOrder': instance.purchaseOrder,
      'unitCost': instance.unitCost,
      'unitSellingPrice': instance.unitSellingPrice,
      'status': _$BatchStatusEnumMap[instance.status]!,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'receivedBy': instance.receivedBy,
      'receivedByName': instance.receivedByName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$BatchStatusEnumMap = {
  BatchStatus.active: 'active',
  BatchStatus.depleted: 'depleted',
  BatchStatus.expired: 'expired',
  BatchStatus.recalled: 'recalled',
  BatchStatus.damaged: 'damaged',
};
