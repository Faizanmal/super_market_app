// Shelf Location Model
import 'package:json_annotation/json_annotation.dart';

part 'shelf_location_model.g.dart';

@JsonSerializable()
class ShelfLocation {
  final int id;
  final int storeId;
  final String storeName;
  
  // Location hierarchy
  final String aisle;
  final String section;
  final String? position;
  final String locationCode; // e.g., "A3-S2-L"
  
  // QR Code
  final String? qrCode;
  final String? qrCodeImage;
  
  // Capacity
  final int? capacity;
  final int? currentOccupancy;
  
  // Description
  final String? description;
  
  // Layout coordinates
  final double? xCoordinate;
  final double? yCoordinate;
  
  final bool isActive;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShelfLocation({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.aisle,
    required this.section,
    this.position,
    required this.locationCode,
    this.qrCode,
    this.qrCodeImage,
    this.capacity,
    this.currentOccupancy,
    this.description,
    this.xCoordinate,
    this.yCoordinate,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShelfLocation.fromJson(Map<String, dynamic> json) => 
      _$ShelfLocationFromJson(json);
  Map<String, dynamic> toJson() => _$ShelfLocationToJson(this);

  String get fullLocation {
    final parts = ['Aisle $aisle', 'Section $section'];
    if (position != null && position!.isNotEmpty) {
      parts.add(position!);
    }
    return parts.join(' → ');
  }

  double get occupancyPercentage {
    if (capacity == null || capacity == 0) return 0;
    return ((currentOccupancy ?? 0) / capacity!) * 100;
  }

  bool get isNearCapacity => occupancyPercentage > 80;
  bool get isFull => occupancyPercentage >= 100;
}

@JsonSerializable()
class BatchLocation {
  final int id;
  final int batchId;
  final int shelfLocationId;
  final String locationCode;
  final int quantity;
  final DateTime placedAt;
  final int? placedBy;
  final String? placedByName;
  final String? placementPhoto;
  final String? notes;
  final bool isActive;

  BatchLocation({
    required this.id,
    required this.batchId,
    required this.shelfLocationId,
    required this.locationCode,
    required this.quantity,
    required this.placedAt,
    this.placedBy,
    this.placedByName,
    this.placementPhoto,
    this.notes,
    required this.isActive,
  });

  factory BatchLocation.fromJson(Map<String, dynamic> json) => 
      _$BatchLocationFromJson(json);
  Map<String, dynamic> toJson() => _$BatchLocationToJson(this);
}
