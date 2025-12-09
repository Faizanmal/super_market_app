// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      assignedToId: (json['assignedToId'] as num).toInt(),
      assignedToName: json['assignedToName'] as String,
      assignedById: (json['assignedById'] as num?)?.toInt(),
      assignedByName: json['assignedByName'] as String?,
      storeId: (json['storeId'] as num).toInt(),
      storeName: json['storeName'] as String,
      taskType: $enumDecode(_$TaskTypeEnumMap, json['taskType']),
      priority: $enumDecode(_$TaskPriorityEnumMap, json['priority']),
      shelfLocationId: (json['shelfLocationId'] as num?)?.toInt(),
      locationCode: json['locationCode'] as String?,
      batchId: (json['batchId'] as num?)?.toInt(),
      batchNumber: json['batchNumber'] as String?,
      alertId: (json['alertId'] as num?)?.toInt(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: $enumDecode(_$TaskStatusEnumMap, json['status']),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      completionNotes: json['completionNotes'] as String?,
      completionPhoto: json['completionPhoto'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'assignedToId': instance.assignedToId,
      'assignedToName': instance.assignedToName,
      'assignedById': instance.assignedById,
      'assignedByName': instance.assignedByName,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'taskType': _$TaskTypeEnumMap[instance.taskType]!,
      'priority': _$TaskPriorityEnumMap[instance.priority]!,
      'shelfLocationId': instance.shelfLocationId,
      'locationCode': instance.locationCode,
      'batchId': instance.batchId,
      'batchNumber': instance.batchNumber,
      'alertId': instance.alertId,
      'dueDate': instance.dueDate.toIso8601String(),
      'status': _$TaskStatusEnumMap[instance.status]!,
      'completedAt': instance.completedAt?.toIso8601String(),
      'completionNotes': instance.completionNotes,
      'completionPhoto': instance.completionPhoto,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$TaskTypeEnumMap = {
  TaskType.shelfCheck: 'shelf_check',
  TaskType.expiryReview: 'expiry_review',
  TaskType.restock: 'restock',
  TaskType.dispose: 'dispose',
  TaskType.discount: 'discount',
  TaskType.receive: 'receive',
  TaskType.audit: 'audit',
  TaskType.other: 'other',
};

const _$TaskPriorityEnumMap = {
  TaskPriority.urgent: 'urgent',
  TaskPriority.high: 'high',
  TaskPriority.medium: 'medium',
  TaskPriority.low: 'low',
};

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 'pending',
  TaskStatus.inProgress: 'in_progress',
  TaskStatus.completed: 'completed',
  TaskStatus.cancelled: 'cancelled',
};
