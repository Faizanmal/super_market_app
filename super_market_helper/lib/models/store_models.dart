class Store {
  final String id;
  final String name;
  final String code;
  final String storeType;
  final String status;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? managerId;
  final String? managerName;
  final Map<String, dynamic>? openingHours;
  final String timezone;
  final String currency;
  final bool autoReorderEnabled;
  final bool interStoreTransfersEnabled;
  final bool centralizedInventory;
  final int totalProducts;
  final double totalStockValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  Store({
    required this.id,
    required this.name,
    required this.code,
    required this.storeType,
    required this.status,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.managerId,
    this.managerName,
    this.openingHours,
    required this.timezone,
    required this.currency,
    required this.autoReorderEnabled,
    required this.interStoreTransfersEnabled,
    required this.centralizedInventory,
    required this.totalProducts,
    required this.totalStockValue,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      storeType: json['store_type'] ?? 'branch',
      status: json['status'] ?? 'active',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? 'USA',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      phone: json['phone'],
      email: json['email'],
      managerId: json['manager']?.toString(),
      managerName: json['manager_name'],
      openingHours: json['opening_hours'],
      timezone: json['timezone'] ?? 'UTC',
      currency: json['currency'] ?? 'USD',
      autoReorderEnabled: json['auto_reorder_enabled'] ?? true,
      interStoreTransfersEnabled: json['inter_store_transfers_enabled'] ?? true,
      centralizedInventory: json['centralized_inventory'] ?? false,
      totalProducts: json['total_products'] ?? 0,
      totalStockValue: (json['total_stock_value'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'store_type': storeType,
      'status': status,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'manager': managerId,
      'opening_hours': openingHours,
      'timezone': timezone,
      'currency': currency,
      'auto_reorder_enabled': autoReorderEnabled,
      'inter_store_transfers_enabled': interStoreTransfersEnabled,
      'centralized_inventory': centralizedInventory,
      'created_by': createdBy,
    };
  }

  static Store empty() {
    return Store(
      id: '',
      name: '',
      code: '',
      storeType: 'branch',
      status: 'active',
      address: '',
      city: '',
      state: '',
      postalCode: '',
      country: 'USA',
      timezone: 'UTC',
      currency: 'USD',
      autoReorderEnabled: true,
      interStoreTransfersEnabled: true,
      centralizedInventory: false,
      totalProducts: 0,
      totalStockValue: 0.0,
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String get displayName => '$name ($code)';
  String get fullAddress => '$address, $city, $state $postalCode';
  
  String get storeTypeDisplay {
    switch (storeType) {
      case 'main':
        return 'Main Store';
      case 'branch':
        return 'Branch Store';
      case 'warehouse':
        return 'Warehouse';
      case 'franchise':
        return 'Franchise';
      default:
        return storeType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'maintenance':
        return 'Under Maintenance';
      case 'closed':
        return 'Permanently Closed';
      default:
        return status;
    }
  }
}

class StoreInventory {
  final String id;
  final String storeId;
  final Store? store;
  final String productId;
  final Product? product;
  final int currentStock;
  final int minStockLevel;
  final int maxStockLevel;
  final int reorderPoint;
  final int reorderQuantity;
  final double? storeCostPrice;
  final double? storeSellingPrice;
  final String? aisle;
  final String? shelf;
  final String? binLocation;
  final String locationDisplay;
  final bool isActive;
  final bool autoReorder;
  final DateTime? lastReorderDate;
  final double stockPercentage;
  final bool needsReorder;
  final bool isOverstocked;
  final bool isUnderstocked;
  final double totalValue;
  final String stockStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoreInventory({
    required this.id,
    required this.storeId,
    this.store,
    required this.productId,
    this.product,
    required this.currentStock,
    required this.minStockLevel,
    required this.maxStockLevel,
    required this.reorderPoint,
    required this.reorderQuantity,
    this.storeCostPrice,
    this.storeSellingPrice,
    this.aisle,
    this.shelf,
    this.binLocation,
    required this.locationDisplay,
    required this.isActive,
    required this.autoReorder,
    this.lastReorderDate,
    required this.stockPercentage,
    required this.needsReorder,
    required this.isOverstocked,
    required this.isUnderstocked,
    required this.totalValue,
    required this.stockStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreInventory.fromJson(Map<String, dynamic> json) {
    return StoreInventory(
      id: json['id']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      productId: json['product_id']?.toString() ?? '',
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      currentStock: json['current_stock'] ?? 0,
      minStockLevel: json['min_stock_level'] ?? 0,
      maxStockLevel: json['max_stock_level'] ?? 100,
      reorderPoint: json['reorder_point'] ?? 10,
      reorderQuantity: json['reorder_quantity'] ?? 50,
      storeCostPrice: json['store_cost_price']?.toDouble(),
      storeSellingPrice: json['store_selling_price']?.toDouble(),
      aisle: json['aisle'],
      shelf: json['shelf'],
      binLocation: json['bin_location'],
      locationDisplay: json['location_display'] ?? 'Not specified',
      isActive: json['is_active'] ?? true,
      autoReorder: json['auto_reorder'] ?? true,
      lastReorderDate: json['last_reorder_date'] != null 
          ? DateTime.parse(json['last_reorder_date']) 
          : null,
      stockPercentage: (json['stock_percentage'] ?? 0).toDouble(),
      needsReorder: json['needs_reorder'] ?? false,
      isOverstocked: json['is_overstocked'] ?? false,
      isUnderstocked: json['is_understocked'] ?? false,
      totalValue: (json['total_value'] ?? 0).toDouble(),
      stockStatus: json['stock_status'] ?? 'optimal',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'product_id': productId,
      'current_stock': currentStock,
      'min_stock_level': minStockLevel,
      'max_stock_level': maxStockLevel,
      'reorder_point': reorderPoint,
      'reorder_quantity': reorderQuantity,
      'store_cost_price': storeCostPrice,
      'store_selling_price': storeSellingPrice,
      'aisle': aisle,
      'shelf': shelf,
      'bin_location': binLocation,
      'is_active': isActive,
      'auto_reorder': autoReorder,
    };
  }

  String get stockStatusDisplay {
    switch (stockStatus) {
      case 'out_of_stock':
        return 'Out of Stock';
      case 'low_stock':
        return 'Low Stock';
      case 'overstocked':
        return 'Overstocked';
      case 'understocked':
        return 'Understocked';
      case 'optimal':
        return 'Optimal';
      default:
        return stockStatus;
    }
  }

  String get priorityLevel {
    if (currentStock == 0) return 'critical';
    if (needsReorder && currentStock < reorderPoint * 0.5) return 'high';
    if (needsReorder) return 'medium';
    return 'low';
  }
}

class Product {
  final String id;
  final String name;
  final String? barcode;
  final double? costPrice;
  final double? sellingPrice;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.costPrice,
    this.sellingPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      barcode: json['barcode'],
      costPrice: json['cost_price']?.toDouble(),
      sellingPrice: json['selling_price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
    };
  }
}

class InterStoreTransfer {
  final String id;
  final String transferNumber;
  final String fromStoreId;
  final Store? fromStore;
  final String toStoreId;
  final Store? toStore;
  final String productId;
  final Product? product;
  final int requestedQuantity;
  final int? approvedQuantity;
  final int? receivedQuantity;
  final String status;
  final String statusDisplay;
  final String reason;
  final String reasonDisplay;
  final String? notes;
  final DateTime requestedDate;
  final DateTime? approvedDate;
  final DateTime? shippedDate;
  final DateTime? receivedDate;
  final DateTime? expectedDelivery;
  final String? requestedById;
  final String? requestedByName;
  final String? approvedById;
  final String? approvedByName;
  final String? receivedById;
  final String? receivedByName;
  final double transferCost;
  final double? unitCost;
  final bool isPendingApproval;
  final bool isInProgress;
  final bool isCompleted;
  final double totalValue;
  final int? daysInTransit;

  InterStoreTransfer({
    required this.id,
    required this.transferNumber,
    required this.fromStoreId,
    this.fromStore,
    required this.toStoreId,
    this.toStore,
    required this.productId,
    this.product,
    required this.requestedQuantity,
    this.approvedQuantity,
    this.receivedQuantity,
    required this.status,
    required this.statusDisplay,
    required this.reason,
    required this.reasonDisplay,
    this.notes,
    required this.requestedDate,
    this.approvedDate,
    this.shippedDate,
    this.receivedDate,
    this.expectedDelivery,
    this.requestedById,
    this.requestedByName,
    this.approvedById,
    this.approvedByName,
    this.receivedById,
    this.receivedByName,
    required this.transferCost,
    this.unitCost,
    required this.isPendingApproval,
    required this.isInProgress,
    required this.isCompleted,
    required this.totalValue,
    this.daysInTransit,
  });

  factory InterStoreTransfer.fromJson(Map<String, dynamic> json) {
    return InterStoreTransfer(
      id: json['id']?.toString() ?? '',
      transferNumber: json['transfer_number'] ?? '',
      fromStoreId: json['from_store_id']?.toString() ?? '',
      fromStore: json['from_store'] != null ? Store.fromJson(json['from_store']) : null,
      toStoreId: json['to_store_id']?.toString() ?? '',
      toStore: json['to_store'] != null ? Store.fromJson(json['to_store']) : null,
      productId: json['product_id']?.toString() ?? '',
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      requestedQuantity: json['requested_quantity'] ?? 0,
      approvedQuantity: json['approved_quantity'],
      receivedQuantity: json['received_quantity'],
      status: json['status'] ?? 'pending',
      statusDisplay: json['status_display'] ?? '',
      reason: json['reason'] ?? 'rebalancing',
      reasonDisplay: json['reason_display'] ?? '',
      notes: json['notes'],
      requestedDate: DateTime.parse(json['requested_date'] ?? DateTime.now().toIso8601String()),
      approvedDate: json['approved_date'] != null ? DateTime.parse(json['approved_date']) : null,
      shippedDate: json['shipped_date'] != null ? DateTime.parse(json['shipped_date']) : null,
      receivedDate: json['received_date'] != null ? DateTime.parse(json['received_date']) : null,
      expectedDelivery: json['expected_delivery'] != null ? DateTime.parse(json['expected_delivery']) : null,
      requestedById: json['requested_by']?.toString(),
      requestedByName: json['requested_by_name'],
      approvedById: json['approved_by']?.toString(),
      approvedByName: json['approved_by_name'],
      receivedById: json['received_by']?.toString(),
      receivedByName: json['received_by_name'],
      transferCost: (json['transfer_cost'] ?? 0).toDouble(),
      unitCost: json['unit_cost']?.toDouble(),
      isPendingApproval: json['is_pending_approval'] ?? false,
      isInProgress: json['is_in_progress'] ?? false,
      isCompleted: json['is_completed'] ?? false,
      totalValue: (json['total_value'] ?? 0).toDouble(),
      daysInTransit: json['days_in_transit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_store_id': fromStoreId,
      'to_store_id': toStoreId,
      'product_id': productId,
      'requested_quantity': requestedQuantity,
      'reason': reason,
      'notes': notes,
      'expected_delivery': expectedDelivery?.toIso8601String(),
      'transfer_cost': transferCost,
      'unit_cost': unitCost,
    };
  }

  String get displayRoute => '${fromStore?.name ?? 'Unknown'} → ${toStore?.name ?? 'Unknown'}';
  
  String get urgencyLevel {
    if (status == 'pending' && DateTime.now().difference(requestedDate).inDays > 3) {
      return 'overdue';
    }
    if (reason == 'emergency') return 'urgent';
    if (status == 'in_transit' && expectedDelivery != null && 
        DateTime.now().isAfter(expectedDelivery!)) {
      return 'delayed';
    }
    return 'normal';
  }
}

class StorePerformanceMetrics {
  final String id;
  final Store? store;
  final DateTime date;
  final double totalSales;
  final int totalTransactions;
  final double averageTransactionValue;
  final int totalProducts;
  final double totalStockValue;
  final int productsOutOfStock;
  final int productsLowStock;
  final int productsOverstocked;
  final int productsExpired;
  final double wastageValue;
  final int transfersSent;
  final int transfersReceived;
  final double inventoryTurnover;
  final double stockAccuracy;
  final double stockHealthScore;
  final double? salesGrowth;
  final double efficiencyScore;
  final String inventoryHealth;

  StorePerformanceMetrics({
    required this.id,
    this.store,
    required this.date,
    required this.totalSales,
    required this.totalTransactions,
    required this.averageTransactionValue,
    required this.totalProducts,
    required this.totalStockValue,
    required this.productsOutOfStock,
    required this.productsLowStock,
    required this.productsOverstocked,
    required this.productsExpired,
    required this.wastageValue,
    required this.transfersSent,
    required this.transfersReceived,
    required this.inventoryTurnover,
    required this.stockAccuracy,
    required this.stockHealthScore,
    this.salesGrowth,
    required this.efficiencyScore,
    required this.inventoryHealth,
  });

  factory StorePerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return StorePerformanceMetrics(
      id: json['id']?.toString() ?? '',
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      totalSales: (json['total_sales'] ?? 0).toDouble(),
      totalTransactions: json['total_transactions'] ?? 0,
      averageTransactionValue: (json['average_transaction_value'] ?? 0).toDouble(),
      totalProducts: json['total_products'] ?? 0,
      totalStockValue: (json['total_stock_value'] ?? 0).toDouble(),
      productsOutOfStock: json['products_out_of_stock'] ?? 0,
      productsLowStock: json['products_low_stock'] ?? 0,
      productsOverstocked: json['products_overstocked'] ?? 0,
      productsExpired: json['products_expired'] ?? 0,
      wastageValue: (json['wastage_value'] ?? 0).toDouble(),
      transfersSent: json['transfers_sent'] ?? 0,
      transfersReceived: json['transfers_received'] ?? 0,
      inventoryTurnover: (json['inventory_turnover'] ?? 0).toDouble(),
      stockAccuracy: (json['stock_accuracy'] ?? 100).toDouble(),
      stockHealthScore: (json['stock_health_score'] ?? 0).toDouble(),
      salesGrowth: json['sales_growth']?.toDouble(),
      efficiencyScore: (json['efficiency_score'] ?? 0).toDouble(),
      inventoryHealth: json['inventory_health'] ?? 'no_data',
    );
  }

  String get inventoryHealthDisplay {
    switch (inventoryHealth) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      case 'critical':
        return 'Critical';
      case 'no_data':
        return 'No Data';
      default:
        return inventoryHealth;
    }
  }

  String get performanceGrade {
    if (efficiencyScore >= 90) return 'A+';
    if (efficiencyScore >= 85) return 'A';
    if (efficiencyScore >= 80) return 'B+';
    if (efficiencyScore >= 75) return 'B';
    if (efficiencyScore >= 70) return 'C+';
    if (efficiencyScore >= 65) return 'C';
    if (efficiencyScore >= 60) return 'D';
    return 'F';
  }

  double get wastagePercentage {
    if (totalStockValue > 0) {
      return (wastageValue / totalStockValue) * 100;
    }
    return 0.0;
  }

  int get netTransfers => transfersReceived - transfersSent;
}

class StoreComparison {
  final String id;
  final List<Store> stores;
  final DateTime comparisonDate;
  final String period;
  final Map<String, dynamic> metricsData;
  final Store? bestPerformingStore;
  final Store? worstPerformingStore;
  final String? insights;
  final String? recommendations;
  final DateTime createdAt;
  final String? createdBy;
  final String? createdByName;

  StoreComparison({
    required this.id,
    required this.stores,
    required this.comparisonDate,
    required this.period,
    required this.metricsData,
    this.bestPerformingStore,
    this.worstPerformingStore,
    this.insights,
    this.recommendations,
    required this.createdAt,
    this.createdBy,
    this.createdByName,
  });

  factory StoreComparison.fromJson(Map<String, dynamic> json) {
    return StoreComparison(
      id: json['id']?.toString() ?? '',
      stores: (json['stores'] as List? ?? [])
          .map((store) => Store.fromJson(store))
          .toList(),
      comparisonDate: DateTime.parse(json['comparison_date'] ?? DateTime.now().toIso8601String()),
      period: json['period'] ?? 'daily',
      metricsData: json['metrics_data'] ?? {},
      bestPerformingStore: json['best_performing_store'] != null 
          ? Store.fromJson(json['best_performing_store']) 
          : null,
      worstPerformingStore: json['worst_performing_store'] != null 
          ? Store.fromJson(json['worst_performing_store']) 
          : null,
      insights: json['insights'],
      recommendations: json['recommendations'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['created_by']?.toString(),
      createdByName: json['created_by_name'],
    );
  }

  String get periodDisplay {
    switch (period) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return period;
    }
  }
}

class StoreUser {
  final String id;
  final User user;
  final List<Store> assignedStores;
  final Store? primaryStore;
  final List<Store> accessibleStores;
  final bool canManageInventory;
  final bool canApproveTransfers;
  final bool canViewAnalytics;
  final bool canManageUsers;
  final String defaultStoreView;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoreUser({
    required this.id,
    required this.user,
    required this.assignedStores,
    this.primaryStore,
    required this.accessibleStores,
    required this.canManageInventory,
    required this.canApproveTransfers,
    required this.canViewAnalytics,
    required this.canManageUsers,
    required this.defaultStoreView,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreUser.fromJson(Map<String, dynamic> json) {
    return StoreUser(
      id: json['id']?.toString() ?? '',
      user: User.fromJson(json['user'] ?? {}),
      assignedStores: (json['assigned_stores'] as List? ?? [])
          .map((store) => Store.fromJson(store))
          .toList(),
      primaryStore: json['primary_store'] != null 
          ? Store.fromJson(json['primary_store']) 
          : null,
      accessibleStores: (json['accessible_stores'] as List? ?? [])
          .map((store) => Store.fromJson(store))
          .toList(),
      canManageInventory: json['can_manage_inventory'] ?? true,
      canApproveTransfers: json['can_approve_transfers'] ?? false,
      canViewAnalytics: json['can_view_analytics'] ?? true,
      canManageUsers: json['can_manage_users'] ?? false,
      defaultStoreView: json['default_store_view'] ?? 'single',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user.id,
      'assigned_store_ids': assignedStores.map((store) => store.id).toList(),
      'primary_store_id': primaryStore?.id,
      'can_manage_inventory': canManageInventory,
      'can_approve_transfers': canApproveTransfers,
      'can_view_analytics': canViewAnalytics,
      'can_manage_users': canManageUsers,
      'default_store_view': defaultStoreView,
    };
  }

  String get defaultStoreViewDisplay {
    switch (defaultStoreView) {
      case 'single':
        return 'Single Store';
      case 'multi':
        return 'Multi Store';
      case 'comparison':
        return 'Store Comparison';
      default:
        return defaultStoreView;
    }
  }

  List<String> get permissions {
    List<String> perms = [];
    if (canManageInventory) perms.add('Manage Inventory');
    if (canApproveTransfers) perms.add('Approve Transfers');
    if (canViewAnalytics) perms.add('View Analytics');
    if (canManageUsers) perms.add('Manage Users');
    return perms;
  }
}

class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}