// Expiry & Shelf Management System - Data Models
// Complete models for batch tracking, receiving, audits, alerts, and tasks

import 'package:json_annotation/json_annotation.dart';

part 'expiry_models.g.dart';

// ==================== USER & AUTHENTICATION ====================

@JsonSerializable()
class User {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String fullName;
  final String? phoneNumber;
  final String? companyName;
  final String? address;
  final String? profilePicture;
  final String? dateOfBirth;
  final String role;
  final String roleDisplay;
  final int? store;
  final String? storeName;
  final String? employeeId;
  final bool canReceiveStock;
  final bool canAudit;
  final bool canManageStaff;
  final bool canViewAnalytics;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.fullName,
    this.phoneNumber,
    this.companyName,
    this.address,
    this.profilePicture,
    this.dateOfBirth,
    required this.role,
    required this.roleDisplay,
    this.store,
    this.storeName,
    this.employeeId,
    required this.canReceiveStock,
    required this.canAudit,
    required this.canManageStaff,
    required this.canViewAnalytics,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final String access;
  final String refresh;
  final User user;

  LoginResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

// ==================== STORE & LOCATION ====================

@JsonSerializable()
class Store {
  final int id;
  final String name;
  final String code;
  final String address;
  final String? phone;
  final String? email;
  final bool isActive;
  final String? timezone;

  Store({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    this.phone,
    this.email,
    required this.isActive,
    this.timezone,
  });

  factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);
  Map<String, dynamic> toJson() => _$StoreToJson(this);
}

@JsonSerializable()
class ShelfLocation {
  final int id;
  final int store;
  final String aisle;
  final String section;
  final String? position;
  final String locationCode;
  final String? qrCode;
  final String? qrCodeImage;
  final int? capacity;
  final String? description;
  final double? xCoordinate;
  final double? yCoordinate;
  final bool isActive;
  final String fullLocation;

  ShelfLocation({
    required this.id,
    required this.store,
    required this.aisle,
    required this.section,
    this.position,
    required this.locationCode,
    this.qrCode,
    this.qrCodeImage,
    this.capacity,
    this.description,
    this.xCoordinate,
    this.yCoordinate,
    required this.isActive,
    required this.fullLocation,
  });

  factory ShelfLocation.fromJson(Map<String, dynamic> json) => _$ShelfLocationFromJson(json);
  Map<String, dynamic> toJson() => _$ShelfLocationToJson(this);
}

// ==================== PRODUCT & BATCH ====================

@JsonSerializable()
class Product {
  final int id;
  final String name;
  final String? description;
  final String barcode;
  final String? sku;
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final int minStockLevel;
  final String? image;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.barcode,
    this.sku,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.minStockLevel,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

@JsonSerializable()
class ProductBatch {
  final int id;
  final String gtin;
  final String batchNumber;
  final String? gs1Barcode;
  final int product;
  final String productName;
  final int quantity;
  final int originalQuantity;
  final String expiryDate;
  final String? manufactureDate;
  final String status;
  final int? supplier;
  final String? supplierName;
  final String? shipmentNumber;
  final String? invoiceNumber;
  final double unitCost;
  final double unitSellingPrice;
  final int store;
  final String storeName;
  final int daysUntilExpiry;
  final String expiryStatus;
  final double totalValue;
  final DateTime createdAt;

  ProductBatch({
    required this.id,
    required this.gtin,
    required this.batchNumber,
    this.gs1Barcode,
    required this.product,
    required this.productName,
    required this.quantity,
    required this.originalQuantity,
    required this.expiryDate,
    this.manufactureDate,
    required this.status,
    this.supplier,
    this.supplierName,
    this.shipmentNumber,
    this.invoiceNumber,
    required this.unitCost,
    required this.unitSellingPrice,
    required this.store,
    required this.storeName,
    required this.daysUntilExpiry,
    required this.expiryStatus,
    required this.totalValue,
    required this.createdAt,
  });

  factory ProductBatch.fromJson(Map<String, dynamic> json) => _$ProductBatchFromJson(json);
  Map<String, dynamic> toJson() => _$ProductBatchToJson(this);
}

// ==================== RECEIVING ====================

@JsonSerializable()
class ReceivingLog {
  final int id;
  final String receiptNumber;
  final String? shipmentNumber;
  final String? invoiceNumber;
  final String? purchaseOrder;
  final int? supplier;
  final String? supplierName;
  final int store;
  final String storeName;
  final DateTime receivedDate;
  final int totalItems;
  final double totalValue;
  final String status;
  final bool hasExpiryIssues;
  final String? validationNotes;
  final String? palletPhoto;
  final String? invoicePhoto;

  ReceivingLog({
    required this.id,
    required this.receiptNumber,
    this.shipmentNumber,
    this.invoiceNumber,
    this.purchaseOrder,
    this.supplier,
    this.supplierName,
    required this.store,
    required this.storeName,
    required this.receivedDate,
    required this.totalItems,
    required this.totalValue,
    required this.status,
    required this.hasExpiryIssues,
    this.validationNotes,
    this.palletPhoto,
    this.invoicePhoto,
  });

  factory ReceivingLog.fromJson(Map<String, dynamic> json) => _$ReceivingLogFromJson(json);
  Map<String, dynamic> toJson() => _$ReceivingLogToJson(this);
}

// ==================== AUDIT ====================

@JsonSerializable()
class ShelfAudit {
  final int id;
  final String auditNumber;
  final DateTime auditDate;
  final int store;
  final String storeName;
  final int? shelfLocation;
  final String? locationCode;
  final String scope;
  final int? category;
  final int itemsChecked;
  final int itemsExpired;
  final int itemsNearExpiry;
  final int itemsDamaged;
  final int itemsMisplaced;
  final String status;
  final String? notes;
  final String? actionRequired;

  ShelfAudit({
    required this.id,
    required this.auditNumber,
    required this.auditDate,
    required this.store,
    required this.storeName,
    this.shelfLocation,
    this.locationCode,
    required this.scope,
    this.category,
    required this.itemsChecked,
    required this.itemsExpired,
    required this.itemsNearExpiry,
    required this.itemsDamaged,
    required this.itemsMisplaced,
    required this.status,
    this.notes,
    this.actionRequired,
  });

  factory ShelfAudit.fromJson(Map<String, dynamic> json) => _$ShelfAuditFromJson(json);
  Map<String, dynamic> toJson() => _$ShelfAuditToJson(this);

  // Compatibility getters
  String get auditType => scope;
  DateTime get createdAt => auditDate; // Assuming auditDate is creation date
  int get itemsAudited => itemsChecked;
}

@JsonSerializable()
class AuditItem {
  final int id;
  final int audit;
  final int batch;
  final String productName;
  final String batchNumber;
  final int quantityFound;
  final int? quantityExpected;
  final String status;
  final String? photo;
  final String? notes;

  AuditItem({
    required this.id,
    required this.audit,
    required this.batch,
    required this.productName,
    required this.batchNumber,
    required this.quantityFound,
    this.quantityExpected,
    required this.status,
    this.photo,
    this.notes,
  });

  factory AuditItem.fromJson(Map<String, dynamic> json) => _$AuditItemFromJson(json);
  Map<String, dynamic> toJson() => _$AuditItemToJson(this);
}

// ==================== EXPIRY ALERTS ====================

@JsonSerializable()
class ExpiryAlert {
  final int id;
  final int batch;
  final ProductBatch? batchDetails;
  final int store;
  final String storeName;
  final int? shelfLocation;
  final String? locationCode;
  final String severity;
  final int daysUntilExpiry;
  final int quantityAtRisk;
  final double estimatedLoss;
  final String suggestedAction;
  final double? suggestedDiscount;
  final bool isAcknowledged;
  final String? acknowledgedByName;
  final DateTime? acknowledgedAt;
  final bool isResolved;
  final String? resolutionAction;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final String? productName;
  final String? batchNumber;
  final int? currentQuantity;
  final String? resolutionNotes;

  ExpiryAlert({
    required this.id,
    required this.batch,
    this.batchDetails,
    required this.store,
    required this.storeName,
    this.shelfLocation,
    this.locationCode,
    required this.severity,
    required this.daysUntilExpiry,
    required this.quantityAtRisk,
    required this.estimatedLoss,
    required this.suggestedAction,
    this.suggestedDiscount,
    required this.isAcknowledged,
    this.acknowledgedByName,
    this.acknowledgedAt,
    required this.isResolved,
    this.resolutionAction,
    this.resolvedByName,
    this.resolvedAt,
    required this.createdAt,
    this.productName,
    this.batchNumber,
    this.currentQuantity,
    this.resolutionNotes,
  });

  factory ExpiryAlert.fromJson(Map<String, dynamic> json) => _$ExpiryAlertFromJson(json);
  Map<String, dynamic> toJson() => _$ExpiryAlertToJson(this);

  // Getters for backward compatibility
  String get message => suggestedAction;
}

// ==================== TASKS ====================

@JsonSerializable()
class Task {
  final int id;
  final String title;
  final String description;
  final int assignedTo;
  final String assignedToName;
  final int? assignedBy;
  final String? assignedByName;
  final int store;
  final String storeName;
  final String taskType;
  final String priority;
  final int? shelfLocation;
  final String? locationCode;
  final int? batch;
  final String? batchNumber;
  final int? alert;
  final DateTime dueDate;
  final DateTime? startedAt;
  final String status;
  final DateTime? completedAt;
  final String? completionNotes;
  final String? completionPhoto;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedToName,
    this.assignedBy,
    this.assignedByName,
    required this.store,
    required this.storeName,
    required this.taskType,
    required this.priority,
    this.shelfLocation,
    this.locationCode,
    this.batch,
    this.batchNumber,
    this.alert,
    required this.dueDate,
    this.startedAt,
    required this.status,
    this.completedAt,
    this.completionNotes,
    this.completionPhoto,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}

// ==================== ANALYTICS ====================

@JsonSerializable()
class DashboardSummary {
  final int totalProducts;
  final int totalBatches;
  final int criticalAlerts;
  final int pendingTasks;
  final double wastageThisMonth;
  final double revenueRecovered;
  final List<ProductBatch> topExpiring;
  final List<ShelfAudit> recentAudits;

  DashboardSummary({
    required this.totalProducts,
    required this.totalBatches,
    required this.criticalAlerts,
    required this.pendingTasks,
    required this.wastageThisMonth,
    required this.revenueRecovered,
    required this.topExpiring,
    required this.recentAudits,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => _$DashboardSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardSummaryToJson(this);

  // Getters for backward compatibility
  int get totalCriticalAlerts => criticalAlerts;
  int get totalExpiringSoon => topExpiring.length;
  int get totalPendingTasks => pendingTasks;
}

@JsonSerializable()
class ExpiryAnalytics {
  final int totalBatches;
  final int expiringCritical;
  final int expiringHigh;
  final int expiringMedium;
  final double totalAtRiskValue;
  final List<ProductBatch> topExpiringProducts;

  ExpiryAnalytics({
    required this.totalBatches,
    required this.expiringCritical,
    required this.expiringHigh,
    required this.expiringMedium,
    required this.totalAtRiskValue,
    required this.topExpiringProducts,
  });

  factory ExpiryAnalytics.fromJson(Map<String, dynamic> json) => _$ExpiryAnalyticsFromJson(json);
  Map<String, dynamic> toJson() => _$ExpiryAnalyticsToJson(this);
}

// ==================== DYNAMIC PRICING ====================

@JsonSerializable()
class DynamicPricing {
  final int id;
  final int batch;
  final ProductBatch? batchDetails;
  final int store;
  final String storeName;
  final double originalPrice;
  final double discountPercentage;
  final double discountedPrice;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final String reason;
  final int? daysToExpiry;
  final bool isActive;
  final bool isSyncedToPos;
  final String status;
  final int quantitySold;
  final double revenueGenerated;
  final int wastePrevented;

  DynamicPricing({
    required this.id,
    required this.batch,
    this.batchDetails,
    required this.store,
    required this.storeName,
    required this.originalPrice,
    required this.discountPercentage,
    required this.discountedPrice,
    required this.effectiveFrom,
    this.effectiveUntil,
    required this.reason,
    this.daysToExpiry,
    required this.isActive,
    required this.isSyncedToPos,
    required this.status,
    required this.quantitySold,
    required this.revenueGenerated,
    required this.wastePrevented,
  });

  factory DynamicPricing.fromJson(Map<String, dynamic> json) => _$DynamicPricingFromJson(json);
  Map<String, dynamic> toJson() => _$DynamicPricingToJson(this);
}

// ==================== WASTAGE REPORTING ====================

@JsonSerializable()
class WastageReport {
  final int id;
  final String reportNumber;
  final DateTime reportDate;
  final int store;
  final String storeName;
  final String periodStart;
  final String periodEnd;
  final int totalItemsWasted;
  final double totalMonetaryLoss;
  final String status;
  final String? notes;

  WastageReport({
    required this.id,
    required this.reportNumber,
    required this.reportDate,
    required this.store,
    required this.storeName,
    required this.periodStart,
    required this.periodEnd,
    required this.totalItemsWasted,
    required this.totalMonetaryLoss,
    required this.status,
    this.notes,
  });

  factory WastageReport.fromJson(Map<String, dynamic> json) => _$WastageReportFromJson(json);
  Map<String, dynamic> toJson() => _$WastageReportToJson(this);
}
