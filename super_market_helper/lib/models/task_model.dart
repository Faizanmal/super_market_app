// Task Model for Staff Management
import 'package:json_annotation/json_annotation.dart';

part 'task_model.g.dart';

@JsonSerializable()
class Task {
  final int id;
  final String title;
  final String description;
  
  // Assignment
  final int assignedToId;
  final String assignedToName;
  final int? assignedById;
  final String? assignedByName;
  final int storeId;
  final String storeName;
  
  // Type and priority
  final TaskType taskType;
  final TaskPriority priority;
  
  // References
  final int? shelfLocationId;
  final String? locationCode;
  final int? batchId;
  final String? batchNumber;
  final int? alertId;
  
  // Timing
  final DateTime dueDate;
  final DateTime? startedAt;
  
  // Status
  final TaskStatus status;
  final DateTime? completedAt;
  final String? completionNotes;
  final String? completionPhoto;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedToId,
    required this.assignedToName,
    this.assignedById,
    this.assignedByName,
    required this.storeId,
    required this.storeName,
    required this.taskType,
    required this.priority,
    this.shelfLocationId,
    this.locationCode,
    this.batchId,
    this.batchNumber,
    this.alertId,
    required this.dueDate,
    this.startedAt,
    required this.status,
    this.completedAt,
    this.completionNotes,
    this.completionPhoto,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  bool get isPending => status == TaskStatus.pending;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isCancelled => status == TaskStatus.cancelled;
  
  bool get isOverdue {
    if (isCompleted || isCancelled) return false;
    return DateTime.now().isAfter(dueDate);
  }

  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }
}

enum TaskType {
  @JsonValue('shelf_check')
  shelfCheck,
  
  @JsonValue('expiry_review')
  expiryReview,
  
  @JsonValue('restock')
  restock,
  
  @JsonValue('dispose')
  dispose,
  
  @JsonValue('discount')
  discount,
  
  @JsonValue('receive')
  receive,
  
  @JsonValue('audit')
  audit,
  
  @JsonValue('other')
  other,
}

enum TaskPriority {
  @JsonValue('urgent')
  urgent,
  
  @JsonValue('high')
  high,
  
  @JsonValue('medium')
  medium,
  
  @JsonValue('low')
  low,
}

enum TaskStatus {
  @JsonValue('pending')
  pending,
  
  @JsonValue('in_progress')
  inProgress,
  
  @JsonValue('completed')
  completed,
  
  @JsonValue('cancelled')
  cancelled,
}

extension TaskTypeExtension on TaskType {
  String get label {
    switch (this) {
      case TaskType.shelfCheck:
        return 'Shelf Check';
      case TaskType.expiryReview:
        return 'Expiry Review';
      case TaskType.restock:
        return 'Restock Items';
      case TaskType.dispose:
        return 'Dispose Items';
      case TaskType.discount:
        return 'Apply Discount';
      case TaskType.receive:
        return 'Receive Shipment';
      case TaskType.audit:
        return 'Conduct Audit';
      case TaskType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case TaskType.shelfCheck:
        return '🔍';
      case TaskType.expiryReview:
        return '📅';
      case TaskType.restock:
        return '📦';
      case TaskType.dispose:
        return '🗑️';
      case TaskType.discount:
        return '💰';
      case TaskType.receive:
        return '📥';
      case TaskType.audit:
        return '✅';
      case TaskType.other:
        return '📋';
    }
  }
}

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.urgent:
        return 'Urgent';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String get colorHex {
    switch (this) {
      case TaskPriority.urgent:
        return '#F44336'; // Red
      case TaskPriority.high:
        return '#FF9800'; // Orange
      case TaskPriority.medium:
        return '#FFC107'; // Yellow
      case TaskPriority.low:
        return '#4CAF50'; // Green
    }
  }

  int get sortValue {
    switch (this) {
      case TaskPriority.urgent:
        return 4;
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
    }
  }
}
