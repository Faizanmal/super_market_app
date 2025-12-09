class Supplier {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String contactPerson;
  final List<String> productCategories;
  final bool isActive;
  final bool isPreferred;
  final bool hasPortalAccess;
  final int leadTimeDays;
  final double minOrderValue;
  final int paymentTermsDays;
  final double? performanceScore;
  final String? website;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.contactPerson,
    required this.productCategories,
    required this.isActive,
    required this.isPreferred,
    required this.hasPortalAccess,
    required this.leadTimeDays,
    required this.minOrderValue,
    required this.paymentTermsDays,
    this.performanceScore,
    this.website,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      contactPerson: json['contact_person'],
      productCategories: List<String>.from(json['product_categories'] ?? []),
      isActive: json['is_active'] ?? true,
      isPreferred: json['is_preferred'] ?? false,
      hasPortalAccess: json['has_portal_access'] ?? false,
      leadTimeDays: json['lead_time_days'],
      minOrderValue: (json['min_order_value'] as num).toDouble(),
      paymentTermsDays: json['payment_terms_days'],
      performanceScore: json['performance_score'] != null
          ? (json['performance_score'] as num).toDouble()
          : null,
      website: json['website'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'contact_person': contactPerson,
      'product_categories': productCategories,
      'is_active': isActive,
      'is_preferred': isPreferred,
      'has_portal_access': hasPortalAccess,
      'lead_time_days': leadTimeDays,
      'min_order_value': minOrderValue,
      'payment_terms_days': paymentTermsDays,
      'performance_score': performanceScore,
      'website': website,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SupplierPerformance {
  final int id;
  final int supplierId;
  final String supplierName;
  final double overallScore;
  final double qualityScore;
  final double deliveryScore;
  final double communicationScore;
  final double priceCompetitiveness;
  final int totalOrders;
  final int onTimeDeliveries;
  final int qualityIssues;
  final double averageResponseTime;
  final double defectRate;
  final DateTime evaluationDate;

  SupplierPerformance({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.overallScore,
    required this.qualityScore,
    required this.deliveryScore,
    required this.communicationScore,
    required this.priceCompetitiveness,
    required this.totalOrders,
    required this.onTimeDeliveries,
    required this.qualityIssues,
    required this.averageResponseTime,
    required this.defectRate,
    required this.evaluationDate,
  });

  factory SupplierPerformance.fromJson(Map<String, dynamic> json) {
    return SupplierPerformance(
      id: json['id'],
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'],
      overallScore: (json['overall_score'] as num).toDouble(),
      qualityScore: (json['quality_score'] as num).toDouble(),
      deliveryScore: (json['delivery_score'] as num).toDouble(),
      communicationScore: (json['communication_score'] as num).toDouble(),
      priceCompetitiveness: (json['price_competitiveness'] as num).toDouble(),
      totalOrders: json['total_orders'],
      onTimeDeliveries: json['on_time_deliveries'],
      qualityIssues: json['quality_issues'],
      averageResponseTime: (json['average_response_time'] as num).toDouble(),
      defectRate: (json['defect_rate'] as num).toDouble(),
      evaluationDate: DateTime.parse(json['evaluation_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'overall_score': overallScore,
      'quality_score': qualityScore,
      'delivery_score': deliveryScore,
      'communication_score': communicationScore,
      'price_competitiveness': priceCompetitiveness,
      'total_orders': totalOrders,
      'on_time_deliveries': onTimeDeliveries,
      'quality_issues': qualityIssues,
      'average_response_time': averageResponseTime,
      'defect_rate': defectRate,
      'evaluation_date': evaluationDate.toIso8601String(),
    };
  }

  double get onTimeDeliveryRate =>
      totalOrders > 0 ? (onTimeDeliveries / totalOrders) * 100 : 0;
}

class AutomatedReorderRule {
  final int id;
  final int productId;
  final String? productName;
  final int supplierId;
  final String? supplierName;
  final int reorderPoint;
  final int reorderQuantity;
  final int leadTimeBufferDays;
  final int? maxStockLevel;
  final bool isActive;
  final DateTime? lastTriggeredAt;
  final DateTime nextCheckAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AutomatedReorderRule({
    required this.id,
    required this.productId,
    this.productName,
    required this.supplierId,
    this.supplierName,
    required this.reorderPoint,
    required this.reorderQuantity,
    required this.leadTimeBufferDays,
    this.maxStockLevel,
    required this.isActive,
    this.lastTriggeredAt,
    required this.nextCheckAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AutomatedReorderRule.fromJson(Map<String, dynamic> json) {
    return AutomatedReorderRule(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'],
      reorderPoint: json['reorder_point'],
      reorderQuantity: json['reorder_quantity'],
      leadTimeBufferDays: json['lead_time_buffer_days'],
      maxStockLevel: json['max_stock_level'],
      isActive: json['is_active'] ?? true,
      lastTriggeredAt: json['last_triggered_at'] != null
          ? DateTime.parse(json['last_triggered_at'])
          : null,
      nextCheckAt: DateTime.parse(json['next_check_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'reorder_point': reorderPoint,
      'reorder_quantity': reorderQuantity,
      'lead_time_buffer_days': leadTimeBufferDays,
      'max_stock_level': maxStockLevel,
      'is_active': isActive,
      'last_triggered_at': lastTriggeredAt?.toIso8601String(),
      'next_check_at': nextCheckAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SupplierContract {
  final int id;
  final int supplierId;
  final String supplierName;
  final String contractType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalValue;
  final String terms;
  final bool autoRenew;
  final int renewalNoticeDays;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierContract({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.contractType,
    required this.startDate,
    required this.endDate,
    required this.totalValue,
    required this.terms,
    required this.autoRenew,
    required this.renewalNoticeDays,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierContract.fromJson(Map<String, dynamic> json) {
    return SupplierContract(
      id: json['id'],
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'],
      contractType: json['contract_type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalValue: (json['total_value'] as num).toDouble(),
      terms: json['terms'],
      autoRenew: json['auto_renew'] ?? false,
      renewalNoticeDays: json['renewal_notice_days'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'contract_type': contractType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_value': totalValue,
      'terms': terms,
      'auto_renew': autoRenew,
      'renewal_notice_days': renewalNoticeDays,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isExpiringSoon {
    final daysUntilExpiry = endDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= renewalNoticeDays && daysUntilExpiry > 0;
  }
}
