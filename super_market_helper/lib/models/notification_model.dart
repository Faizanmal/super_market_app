/// Notification model for real-time notifications
class NotificationModel {
  final int id;
  final String notificationType;
  final String notificationTypeDisplay;
  final String priority;
  final String priorityDisplay;
  final String title;
  final String message;
  final int? productId;
  final String? productName;
  final int? purchaseOrderId;
  final String? orderNumber;
  final bool isRead;
  final DateTime? readAt;
  final String? actionUrl;
  final DateTime createdAt;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.notificationType,
    required this.notificationTypeDisplay,
    required this.priority,
    required this.priorityDisplay,
    required this.title,
    required this.message,
    this.productId,
    this.productName,
    this.purchaseOrderId,
    this.orderNumber,
    required this.isRead,
    this.readAt,
    this.actionUrl,
    required this.createdAt,
    this.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      notificationType: json['notification_type'],
      notificationTypeDisplay: json['notification_type_display'],
      priority: json['priority'],
      priorityDisplay: json['priority_display'],
      title: json['title'],
      message: json['message'],
      productId: json['product'],
      productName: json['product_name'],
      purchaseOrderId: json['purchase_order'],
      orderNumber: json['order_number'],
      isRead: json['is_read'],
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      actionUrl: json['action_url'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_type': notificationType,
      'priority': priority,
      'title': title,
      'message': message,
      'product': productId,
      'purchase_order': purchaseOrderId,
      'is_read': isRead,
      'action_url': actionUrl,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? notificationType,
    String? notificationTypeDisplay,
    String? priority,
    String? priorityDisplay,
    String? title,
    String? message,
    int? productId,
    String? productName,
    int? purchaseOrderId,
    String? orderNumber,
    bool? isRead,
    DateTime? readAt,
    String? actionUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      notificationType: notificationType ?? this.notificationType,
      notificationTypeDisplay: notificationTypeDisplay ?? this.notificationTypeDisplay,
      priority: priority ?? this.priority,
      priorityDisplay: priorityDisplay ?? this.priorityDisplay,
      title: title ?? this.title,
      message: message ?? this.message,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      orderNumber: orderNumber ?? this.orderNumber,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isCritical => priority == 'critical';
  bool get isHigh => priority == 'high';
  bool get isMedium => priority == 'medium';
  bool get isLow => priority == 'low';

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class NotificationSummary {
  final int totalCount;
  final int unreadCount;
  final int criticalCount;
  final List<Map<String, dynamic>> byType;
  final List<Map<String, dynamic>> byPriority;

  NotificationSummary({
    required this.totalCount,
    required this.unreadCount,
    required this.criticalCount,
    required this.byType,
    required this.byPriority,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      totalCount: json['total'] ?? json['total_count'] ?? 0,
      unreadCount: json['unread'] ?? json['unread_count'] ?? 0,
      criticalCount: json['critical_unread'] ?? json['critical_count'] ?? 0,
      byType: List<Map<String, dynamic>>.from(json['by_type'] ?? []),
      byPriority: List<Map<String, dynamic>>.from(json['by_priority'] ?? []),
    );
  }

  // Legacy getters for backward compatibility
  int get total => totalCount;
  int get unread => unreadCount;
  int get criticalUnread => criticalCount;
}
