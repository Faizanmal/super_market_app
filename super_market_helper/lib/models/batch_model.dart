// Product Batch Model with GS1-128 Support
import 'package:json_annotation/json_annotation.dart';

part 'batch_model.g.dart';

@JsonSerializable()
class ProductBatch {
  final int id;
  
  // GS1-128 Information
  final String gtin; // AI 01
  final String batchNumber; // AI 10
  final String? gs1Barcode;
  
  // Product reference
  final int productId;
  final String productName;
  final String? productImage;
  
  // Quantity
  final int quantity;
  final int originalQuantity;
  
  // Dates
  final DateTime expiryDate; // AI 17
  final DateTime? manufactureDate; // AI 11
  final DateTime receivedDate;
  
  // Supplier & Shipment
  final int? supplierId;
  final String? supplierName;
  final String? shipmentNumber;
  final String? invoiceNumber;
  final String? purchaseOrder;
  
  // Pricing
  final double unitCost;
  final double unitSellingPrice;
  
  // Status
  final BatchStatus status;
  
  // Store
  final int storeId;
  final String storeName;
  
  // Metadata
  final int? receivedBy;
  final String? receivedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductBatch({
    required this.id,
    required this.gtin,
    required this.batchNumber,
    this.gs1Barcode,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.originalQuantity,
    required this.expiryDate,
    this.manufactureDate,
    required this.receivedDate,
    this.supplierId,
    this.supplierName,
    this.shipmentNumber,
    this.invoiceNumber,
    this.purchaseOrder,
    required this.unitCost,
    required this.unitSellingPrice,
    required this.status,
    required this.storeId,
    required this.storeName,
    this.receivedBy,
    this.receivedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductBatch.fromJson(Map<String, dynamic> json) => _$ProductBatchFromJson(json);
  Map<String, dynamic> toJson() => _$ProductBatchToJson(this);

  // Computed properties
  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  ExpiryStatus get expiryStatus {
    final days = daysUntilExpiry;
    if (days < 0) return ExpiryStatus.expired;
    if (days <= 7) return ExpiryStatus.critical;
    if (days <= 30) return ExpiryStatus.warning;
    return ExpiryStatus.fresh;
  }

  double get totalValue => quantity * unitCost;
  
  double get profitMargin {
    if (unitCost == 0) return 0;
    return ((unitSellingPrice - unitCost) / unitCost) * 100;
  }

  bool get isActive => status == BatchStatus.active;
  bool get isDepleted => quantity == 0 || status == BatchStatus.depleted;
  bool get isExpired => daysUntilExpiry < 0 || status == BatchStatus.expired;
}

enum BatchStatus {
  @JsonValue('active')
  active,
  
  @JsonValue('depleted')
  depleted,
  
  @JsonValue('expired')
  expired,
  
  @JsonValue('recalled')
  recalled,
  
  @JsonValue('damaged')
  damaged,
}

enum ExpiryStatus {
  fresh,     // 30+ days
  warning,   // 7-30 days
  critical,  // 1-7 days
  expired,   // < 0 days
}

// Extension for UI colors
extension ExpiryStatusColor on ExpiryStatus {
  String get colorHex {
    switch (this) {
      case ExpiryStatus.fresh:
        return '#4CAF50'; // Green
      case ExpiryStatus.warning:
        return '#FFC107'; // Yellow
      case ExpiryStatus.critical:
        return '#FF9800'; // Orange
      case ExpiryStatus.expired:
        return '#F44336'; // Red
    }
  }

  String get label {
    switch (this) {
      case ExpiryStatus.fresh:
        return 'Fresh';
      case ExpiryStatus.warning:
        return 'Near Expiry';
      case ExpiryStatus.critical:
        return 'Critical';
      case ExpiryStatus.expired:
        return 'Expired';
    }
  }
}
