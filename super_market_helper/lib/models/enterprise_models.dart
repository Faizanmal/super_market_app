/// Inventory Adjustment model
class InventoryAdjustmentModel {
  final int id;
  final String adjustmentNumber;
  final int productId;
  final String? productName;
  final int quantityBefore;
  final int quantityAfter;
  final int adjustmentQuantity;
  final String reason;
  final String reasonDisplay;
  final String? notes;
  final String status;
  final String statusDisplay;
  final int createdById;
  final String? createdByName;
  final int? approvedById;
  final String? approvedByName;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? photoEvidence;

  InventoryAdjustmentModel({
    required this.id,
    required this.adjustmentNumber,
    required this.productId,
    this.productName,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.adjustmentQuantity,
    required this.reason,
    required this.reasonDisplay,
    this.notes,
    required this.status,
    required this.statusDisplay,
    required this.createdById,
    this.createdByName,
    this.approvedById,
    this.approvedByName,
    required this.createdAt,
    this.approvedAt,
    this.photoEvidence,
  });

  factory InventoryAdjustmentModel.fromJson(Map<String, dynamic> json) {
    return InventoryAdjustmentModel(
      id: json['id'],
      adjustmentNumber: json['adjustment_number'],
      productId: json['product'],
      productName: json['product_detail']?['name'],
      quantityBefore: json['quantity_before'],
      quantityAfter: json['quantity_after'],
      adjustmentQuantity: json['adjustment_quantity'],
      reason: json['reason'],
      reasonDisplay: json['reason_display'],
      notes: json['notes'],
      status: json['status'],
      statusDisplay: json['status_display'],
      createdById: json['created_by'],
      createdByName: json['created_by_name'],
      approvedById: json['approved_by'],
      approvedByName: json['approved_by_name'],
      createdAt: DateTime.parse(json['created_at']),
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      photoEvidence: json['photo_evidence'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'quantity_before': quantityBefore,
      'quantity_after': quantityAfter,
      'adjustment_quantity': adjustmentQuantity,
      'reason': reason,
      'notes': notes,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';

  bool get isIncrease => adjustmentQuantity > 0;
  bool get isDecrease => adjustmentQuantity < 0;
}

/// Store Transfer model
class StoreTransferModel {
  final int id;
  final String transferNumber;
  final int fromStoreId;
  final String? fromStoreName;
  final int toStoreId;
  final String? toStoreName;
  final int productId;
  final String? productName;
  final int quantity;
  final String status;
  final String statusDisplay;
  final String? notes;
  final int initiatedById;
  final String? initiatedByName;
  final int? receivedById;
  final String? receivedByName;
  final DateTime createdAt;
  final DateTime initiatedAt;
  final DateTime? shippedAt;
  final DateTime? receivedAt;
  final DateTime? expectedArrival;
  final String createdBy;
  final DateTime? estimatedArrival;

  StoreTransferModel({
    required this.id,
    required this.transferNumber,
    required this.fromStoreId,
    this.fromStoreName,
    required this.toStoreId,
    this.toStoreName,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.status,
    required this.statusDisplay,
    this.notes,
    required this.initiatedById,
    this.initiatedByName,
    this.receivedById,
    this.receivedByName,
    required this.createdAt,
    required this.initiatedAt,
    this.shippedAt,
    this.receivedAt,
    this.expectedArrival,
    required this.createdBy,
    this.estimatedArrival,
  });

  factory StoreTransferModel.fromJson(Map<String, dynamic> json) {
    return StoreTransferModel(
      id: json['id'],
      transferNumber: json['transfer_number'],
      fromStoreId: json['from_store'],
      fromStoreName: json['from_store_detail']?['name'],
      toStoreId: json['to_store'],
      toStoreName: json['to_store_detail']?['name'],
      productId: json['product'],
      productName: json['product_detail']?['name'],
      quantity: json['quantity'],
      status: json['status'],
      statusDisplay: json['status_display'],
      notes: json['notes'],
      initiatedById: json['initiated_by'],
      initiatedByName: json['initiated_by_name'],
      receivedById: json['received_by'],
      receivedByName: json['received_by_name'],
      createdAt: DateTime.parse(json['created_at'] ?? json['initiated_at']),
      initiatedAt: DateTime.parse(json['initiated_at']),
      shippedAt: json['shipped_at'] != null ? DateTime.parse(json['shipped_at']) : null,
      receivedAt: json['received_at'] != null ? DateTime.parse(json['received_at']) : null,
      expectedArrival: json['expected_arrival'] != null ? DateTime.parse(json['expected_arrival']) : null,
      createdBy: json['created_by']?.toString() ?? json['initiated_by']?.toString() ?? '',
      estimatedArrival: json['estimated_arrival'] != null ? DateTime.parse(json['estimated_arrival']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_store': fromStoreId,
      'to_store': toStoreId,
      'product': productId,
      'quantity': quantity,
      'notes': notes,
      'expected_arrival': expectedArrival?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isInTransit => status == 'in_transit';
  bool get isReceived => status == 'received';
  bool get isCancelled => status == 'cancelled';

  int? get daysUntilArrival {
    if (expectedArrival == null) return null;
    return expectedArrival!.difference(DateTime.now()).inDays;
  }
}

/// Price History model
class PriceHistoryModel {
  final int id;
  final int productId;
  final String? productName;
  final double oldCostPrice;
  final double newCostPrice;
  final double oldSellingPrice;
  final double newSellingPrice;
  final double costPriceChange;
  final double sellingPriceChange;
  final String? reason;
  final int? changedById;
  final String? changedByName;
  final DateTime changedAt;

  PriceHistoryModel({
    required this.id,
    required this.productId,
    this.productName,
    required this.oldCostPrice,
    required this.newCostPrice,
    required this.oldSellingPrice,
    required this.newSellingPrice,
    required this.costPriceChange,
    required this.sellingPriceChange,
    this.reason,
    this.changedById,
    this.changedByName,
    required this.changedAt,
  });

  factory PriceHistoryModel.fromJson(Map<String, dynamic> json) {
    return PriceHistoryModel(
      id: json['id'],
      productId: json['product'],
      productName: json['product_detail']?['name'],
      oldCostPrice: double.parse(json['old_cost_price'].toString()),
      newCostPrice: double.parse(json['new_cost_price'].toString()),
      oldSellingPrice: double.parse(json['old_selling_price'].toString()),
      newSellingPrice: double.parse(json['new_selling_price'].toString()),
      costPriceChange: double.parse(json['cost_price_change'].toString()),
      sellingPriceChange: double.parse(json['selling_price_change'].toString()),
      reason: json['reason'],
      changedById: json['changed_by'],
      changedByName: json['changed_by_name'],
      changedAt: DateTime.parse(json['changed_at']),
    );
  }

  bool get costIncreased => costPriceChange > 0;
  bool get costDecreased => costPriceChange < 0;
  bool get sellingIncreased => sellingPriceChange > 0;
  bool get sellingDecreased => sellingPriceChange < 0;
}

/// Audit Log model
class AuditLogModel {
  final int id;
  final int? userId;
  final String? userName;
  final String action;
  final String actionDisplay;
  final DateTime timestamp;
  final String modelName;
  final String? objectId;
  final String? objectRepr;
  final Map<String, dynamic> changes;
  final String? ipAddress;
  final String? userAgent;
  final bool success;
  final String? errorMessage;
  final String? contentType;

  AuditLogModel({
    required this.id,
    this.userId,
    this.userName,
    required this.action,
    required this.actionDisplay,
    required this.timestamp,
    required this.modelName,
    this.objectId,
    this.objectRepr,
    required this.changes,
    this.ipAddress,
    this.userAgent,
    required this.success,
    this.errorMessage,
    this.contentType,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'],
      userId: json['user'],
      userName: json['user_name'],
      action: json['action'],
      actionDisplay: json['action_display'],
      timestamp: DateTime.parse(json['timestamp']),
      modelName: json['model_name'],
      objectId: json['object_id'],
      objectRepr: json['object_repr'],
      changes: json['changes'] ?? {},
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      success: json['success'],
      errorMessage: json['error_message'],
      contentType: json['content_type'] ?? json['model_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'user_name': userName,
      'action': action,
      'action_display': actionDisplay,
      'timestamp': timestamp.toIso8601String(),
      'model_name': modelName,
      'object_id': objectId,
      'object_repr': objectRepr,
      'changes': changes,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'success': success,
      'error_message': errorMessage,
      'content_type': contentType,
    };
  }
}
