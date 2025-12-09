// Audit Models
import 'package:json_annotation/json_annotation.dart';

part 'audit_model.g.dart';

@JsonSerializable()
class ShelfAudit {
  final int id;
  final String auditNumber;
  final DateTime auditDate;
  
  // Location
  final int storeId;
  final String storeName;
  final int? shelfLocationId;
  final String? locationCode;
  
  // Scope
  final AuditScope scope;
  final int? categoryId;
  final String? categoryName;
  
  // Findings
  final int itemsChecked;
  final int itemsExpired;
  final int itemsNearExpiry;
  final int itemsDamaged;
  final int itemsMisplaced;
  
  // Photos
  final List<String>? auditPhotos;
  
  // Status
  final AuditStatus status;
  
  // Staff
  final int? auditorId;
  final String? auditorName;
  
  // Notes
  final String? notes;
  final String? actionRequired;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  ShelfAudit({
    required this.id,
    required this.auditNumber,
    required this.auditDate,
    required this.storeId,
    required this.storeName,
    this.shelfLocationId,
    this.locationCode,
    required this.scope,
    this.categoryId,
    this.categoryName,
    required this.itemsChecked,
    required this.itemsExpired,
    required this.itemsNearExpiry,
    required this.itemsDamaged,
    required this.itemsMisplaced,
    this.auditPhotos,
    required this.status,
    this.auditorId,
    this.auditorName,
    this.notes,
    this.actionRequired,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShelfAudit.fromJson(Map<String, dynamic> json) => 
      _$ShelfAuditFromJson(json);
  Map<String, dynamic> toJson() => _$ShelfAuditToJson(this);

  int get totalIssues => itemsExpired + itemsNearExpiry + itemsDamaged + itemsMisplaced;
  bool get hasIssues => totalIssues > 0;
  double get complianceRate {
    if (itemsChecked == 0) return 100.0;
    return ((itemsChecked - totalIssues) / itemsChecked) * 100;
  }

  // Compatibility getters
  String get auditType => scope.name;
  int? get itemsAudited => itemsChecked;
}

@JsonSerializable()
class AuditItem {
  final int id;
  final int auditId;
  final int batchId;
  final String productName;
  final String batchNumber;
  
  // Findings
  final int quantityFound;
  final int? quantityExpected;
  final AuditItemStatus status;
  
  final String? photo;
  final String? notes;
  final DateTime createdAt;

  AuditItem({
    required this.id,
    required this.auditId,
    required this.batchId,
    required this.productName,
    required this.batchNumber,
    required this.quantityFound,
    this.quantityExpected,
    required this.status,
    this.photo,
    this.notes,
    required this.createdAt,
  });

  factory AuditItem.fromJson(Map<String, dynamic> json) => 
      _$AuditItemFromJson(json);
  Map<String, dynamic> toJson() => _$AuditItemToJson(this);

  bool get hasDiscrepancy {
    if (quantityExpected == null) return false;
    return quantityFound != quantityExpected;
  }

  int get discrepancy {
    if (quantityExpected == null) return 0;
    return quantityFound - quantityExpected!;
  }
}

enum AuditScope {
  @JsonValue('full_store')
  fullStore,
  
  @JsonValue('category')
  category,
  
  @JsonValue('location')
  location,
  
  @JsonValue('random')
  random,
}

enum AuditStatus {
  @JsonValue('in_progress')
  inProgress,
  
  @JsonValue('completed')
  completed,
  
  @JsonValue('flagged')
  flagged,
}

enum AuditItemStatus {
  @JsonValue('ok')
  ok,
  
  @JsonValue('expired')
  expired,
  
  @JsonValue('near_expiry')
  nearExpiry,
  
  @JsonValue('damaged')
  damaged,
  
  @JsonValue('misplaced')
  misplaced,
}

extension AuditScopeExtension on AuditScope {
  String get label {
    switch (this) {
      case AuditScope.fullStore:
        return 'Full Store Audit';
      case AuditScope.category:
        return 'Category Audit';
      case AuditScope.location:
        return 'Location Audit';
      case AuditScope.random:
        return 'Random Spot Check';
    }
  }
}

extension AuditItemStatusExtension on AuditItemStatus {
  String get label {
    switch (this) {
      case AuditItemStatus.ok:
        return 'OK';
      case AuditItemStatus.expired:
        return 'Expired';
      case AuditItemStatus.nearExpiry:
        return 'Near Expiry';
      case AuditItemStatus.damaged:
        return 'Damaged';
      case AuditItemStatus.misplaced:
        return 'Misplaced';
    }
  }

  String get colorHex {
    switch (this) {
      case AuditItemStatus.ok:
        return '#4CAF50'; // Green
      case AuditItemStatus.expired:
        return '#F44336'; // Red
      case AuditItemStatus.nearExpiry:
        return '#FF9800'; // Orange
      case AuditItemStatus.damaged:
        return '#9C27B0'; // Purple
      case AuditItemStatus.misplaced:
        return '#2196F3'; // Blue
    }
  }
}
