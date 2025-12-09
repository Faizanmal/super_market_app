// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shelf_location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShelfLocation _$ShelfLocationFromJson(Map<String, dynamic> json) =>
    ShelfLocation(
      id: (json['id'] as num).toInt(),
      storeId: (json['storeId'] as num).toInt(),
      storeName: json['storeName'] as String,
      aisle: json['aisle'] as String,
      section: json['section'] as String,
      position: json['position'] as String?,
      locationCode: json['locationCode'] as String,
      qrCode: json['qrCode'] as String?,
      qrCodeImage: json['qrCodeImage'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      currentOccupancy: (json['currentOccupancy'] as num?)?.toInt(),
      description: json['description'] as String?,
      xCoordinate: (json['xCoordinate'] as num?)?.toDouble(),
      yCoordinate: (json['yCoordinate'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool,
      createdBy: (json['createdBy'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ShelfLocationToJson(ShelfLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'aisle': instance.aisle,
      'section': instance.section,
      'position': instance.position,
      'locationCode': instance.locationCode,
      'qrCode': instance.qrCode,
      'qrCodeImage': instance.qrCodeImage,
      'capacity': instance.capacity,
      'currentOccupancy': instance.currentOccupancy,
      'description': instance.description,
      'xCoordinate': instance.xCoordinate,
      'yCoordinate': instance.yCoordinate,
      'isActive': instance.isActive,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

BatchLocation _$BatchLocationFromJson(Map<String, dynamic> json) =>
    BatchLocation(
      id: (json['id'] as num).toInt(),
      batchId: (json['batchId'] as num).toInt(),
      shelfLocationId: (json['shelfLocationId'] as num).toInt(),
      locationCode: json['locationCode'] as String,
      quantity: (json['quantity'] as num).toInt(),
      placedAt: DateTime.parse(json['placedAt'] as String),
      placedBy: (json['placedBy'] as num?)?.toInt(),
      placedByName: json['placedByName'] as String?,
      placementPhoto: json['placementPhoto'] as String?,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$BatchLocationToJson(BatchLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batchId': instance.batchId,
      'shelfLocationId': instance.shelfLocationId,
      'locationCode': instance.locationCode,
      'quantity': instance.quantity,
      'placedAt': instance.placedAt.toIso8601String(),
      'placedBy': instance.placedBy,
      'placedByName': instance.placedByName,
      'placementPhoto': instance.placementPhoto,
      'notes': instance.notes,
      'isActive': instance.isActive,
    };
