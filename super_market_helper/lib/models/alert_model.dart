// Expiry Alert Model
import 'package:json_annotation/json_annotation.dart';

part 'alert_model.g.dart';

@JsonSerializable()
class ExpiryAlert {
  final int id;
  final int batchId;
  final String productName;
  final String batchNumber;
  final int storeId;
  final String storeName;
  final int? shelfLocationId;
  final String? locationCode;
  
  // Alert details
  final AlertSeverity severity;
  final int daysUntilExpiry;
  final int quantityAtRisk;
  final int currentQuantity;
  final double estimatedLoss;
  
  // Suggested actions
  final SuggestedAction suggestedAction;
  final double? suggestedDiscount;
  
  // Status
  final bool isAcknowledged;
  final int? acknowledgedBy;
  final String? acknowledgedByName;
  final DateTime? acknowledgedAt;
  
  final bool isResolved;
  final SuggestedAction? resolutionAction;
  final int? resolvedBy;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpiryAlert({
    required this.id,
    required this.batchId,
    required this.productName,
    required this.batchNumber,
    required this.storeId,
    required this.storeName,
    this.shelfLocationId,
    this.locationCode,
    required this.severity,
    required this.daysUntilExpiry,
    required this.quantityAtRisk,
    required this.currentQuantity,
    required this.estimatedLoss,
    required this.suggestedAction,
    this.suggestedDiscount,
    required this.isAcknowledged,
    this.acknowledgedBy,
    this.acknowledgedByName,
    this.acknowledgedAt,
    required this.isResolved,
    this.resolutionAction,
    this.resolvedBy,
    this.resolvedByName,
    this.resolvedAt,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpiryAlert.fromJson(Map<String, dynamic> json) => 
      _$ExpiryAlertFromJson(json);
  Map<String, dynamic> toJson() => _$ExpiryAlertToJson(this);

  bool get isPending => !isAcknowledged && !isResolved;
  bool get isActionable => isAcknowledged && !isResolved;
}

enum AlertSeverity {
  @JsonValue('critical')
  critical, // < 7 days
  
  @JsonValue('high')
  high, // 7-15 days
  
  @JsonValue('medium')
  medium, // 15-30 days
  
  @JsonValue('low')
  low, // 30+ days
}

enum SuggestedAction {
  @JsonValue('discount')
  discount,
  
  @JsonValue('clearance')
  clearance,
  
  @JsonValue('return')
  returnToSupplier,
  
  @JsonValue('dispose')
  dispose,
  
  @JsonValue('none')
  none,
}

extension AlertSeverityExtension on AlertSeverity {
  String get label {
    switch (this) {
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.low:
        return 'Low';
    }
  }

  String get colorHex {
    switch (this) {
      case AlertSeverity.critical:
        return '#F44336'; // Red
      case AlertSeverity.high:
        return '#FF9800'; // Orange
      case AlertSeverity.medium:
        return '#FFC107'; // Yellow
      case AlertSeverity.low:
        return '#4CAF50'; // Green
    }
  }

  int get priority {
    switch (this) {
      case AlertSeverity.critical:
        return 4;
      case AlertSeverity.high:
        return 3;
      case AlertSeverity.medium:
        return 2;
      case AlertSeverity.low:
        return 1;
    }
  }
}

extension SuggestedActionExtension on SuggestedAction {
  String get label {
    switch (this) {
      case SuggestedAction.discount:
        return 'Apply Discount';
      case SuggestedAction.clearance:
        return 'Move to Clearance';
      case SuggestedAction.returnToSupplier:
        return 'Return to Supplier';
      case SuggestedAction.dispose:
        return 'Dispose';
      case SuggestedAction.none:
        return 'No Action';
    }
  }

  String get icon {
    switch (this) {
      case SuggestedAction.discount:
        return '💰';
      case SuggestedAction.clearance:
        return '🏷️';
      case SuggestedAction.returnToSupplier:
        return '↩️';
      case SuggestedAction.dispose:
        return '🗑️';
      case SuggestedAction.none:
        return '✓';
    }
  }
}
