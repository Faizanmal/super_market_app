// Receiving Log Model
import 'package:json_annotation/json_annotation.dart';

part 'receiving_log_model.g.dart';

@JsonSerializable()
class ReceivingLog {
  final int id;
  
  // Reference numbers
  final String receiptNumber;
  final String? shipmentNumber;
  final String? invoiceNumber;
  final String? purchaseOrder;
  
  // Supplier
  final int? supplierId;
  final String? supplierName;
  
  // Store
  final int storeId;
  final String storeName;
  
  // Date
  final DateTime receivedDate;
  
  // Batches
  final List<int> batchIds;
  final int batchCount;
  
  // Photos
  final String? palletPhoto;
  final String? invoicePhoto;
  
  // Validation
  final bool hasExpiryIssues;
  final String? validationNotes;
  
  // Totals
  final int totalItems;
  final double totalValue;
  
  // Status
  final ReceivingStatus status;
  
  // Staff
  final int? receivedById;
  final String? receivedByName;
  final int? approvedById;
  final String? approvedByName;
  
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReceivingLog({
    required this.id,
    required this.receiptNumber,
    this.shipmentNumber,
    this.invoiceNumber,
    this.purchaseOrder,
    this.supplierId,
    this.supplierName,
    required this.storeId,
    required this.storeName,
    required this.receivedDate,
    required this.batchIds,
    required this.batchCount,
    this.palletPhoto,
    this.invoicePhoto,
    required this.hasExpiryIssues,
    this.validationNotes,
    required this.totalItems,
    required this.totalValue,
    required this.status,
    this.receivedById,
    this.receivedByName,
    this.approvedById,
    this.approvedByName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReceivingLog.fromJson(Map<String, dynamic> json) => 
      _$ReceivingLogFromJson(json);
  Map<String, dynamic> toJson() => _$ReceivingLogToJson(this);

  bool get isPending => status == ReceivingStatus.pending;
  bool get isApproved => status == ReceivingStatus.approved;
  bool get hasIssues => hasExpiryIssues || status == ReceivingStatus.rejected;
}

enum ReceivingStatus {
  @JsonValue('pending')
  pending,
  
  @JsonValue('approved')
  approved,
  
  @JsonValue('partial')
  partial,
  
  @JsonValue('rejected')
  rejected,
}

extension ReceivingStatusExtension on ReceivingStatus {
  String get label {
    switch (this) {
      case ReceivingStatus.pending:
        return 'Pending Review';
      case ReceivingStatus.approved:
        return 'Approved';
      case ReceivingStatus.partial:
        return 'Partially Accepted';
      case ReceivingStatus.rejected:
        return 'Rejected';
    }
  }

  String get colorHex {
    switch (this) {
      case ReceivingStatus.pending:
        return '#FFC107'; // Yellow
      case ReceivingStatus.approved:
        return '#4CAF50'; // Green
      case ReceivingStatus.partial:
        return '#FF9800'; // Orange
      case ReceivingStatus.rejected:
        return '#F44336'; // Red
    }
  }
}

// Photo Evidence Model
@JsonSerializable()
class PhotoEvidence {
  final int id;
  final String image;
  final String? caption;
  final String? description;
  
  final PhotoType photoType;
  
  // References
  final int? batchId;
  final int? receivingLogId;
  final int? auditId;
  final int? taskId;
  final int? shelfLocationId;
  
  // Metadata
  final int storeId;
  final int? uploadedById;
  final String? uploadedByName;
  final DateTime uploadedAt;
  
  // GPS
  final double? latitude;
  final double? longitude;

  PhotoEvidence({
    required this.id,
    required this.image,
    this.caption,
    this.description,
    required this.photoType,
    this.batchId,
    this.receivingLogId,
    this.auditId,
    this.taskId,
    this.shelfLocationId,
    required this.storeId,
    this.uploadedById,
    this.uploadedByName,
    required this.uploadedAt,
    this.latitude,
    this.longitude,
  });

  factory PhotoEvidence.fromJson(Map<String, dynamic> json) => 
      _$PhotoEvidenceFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoEvidenceToJson(this);

  bool get hasLocation => latitude != null && longitude != null;
}

enum PhotoType {
  @JsonValue('receiving')
  receiving,
  
  @JsonValue('shelf_placement')
  shelfPlacement,
  
  @JsonValue('audit')
  audit,
  
  @JsonValue('task_completion')
  taskCompletion,
  
  @JsonValue('expiry_issue')
  expiryIssue,
  
  @JsonValue('damage')
  damage,
  
  @JsonValue('other')
  other,
}
