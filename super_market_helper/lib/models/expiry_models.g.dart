// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expiry_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      companyName: json['companyName'] as String?,
      address: json['address'] as String?,
      profilePicture: json['profilePicture'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      role: json['role'] as String,
      roleDisplay: json['roleDisplay'] as String,
      store: (json['store'] as num?)?.toInt(),
      storeName: json['storeName'] as String?,
      employeeId: json['employeeId'] as String?,
      canReceiveStock: json['canReceiveStock'] as bool,
      canAudit: json['canAudit'] as bool,
      canManageStaff: json['canManageStaff'] as bool,
      canViewAnalytics: json['canViewAnalytics'] as bool,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'companyName': instance.companyName,
      'address': instance.address,
      'profilePicture': instance.profilePicture,
      'dateOfBirth': instance.dateOfBirth,
      'role': instance.role,
      'roleDisplay': instance.roleDisplay,
      'store': instance.store,
      'storeName': instance.storeName,
      'employeeId': instance.employeeId,
      'canReceiveStock': instance.canReceiveStock,
      'canAudit': instance.canAudit,
      'canManageStaff': instance.canManageStaff,
      'canViewAnalytics': instance.canViewAnalytics,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'access': instance.access,
      'refresh': instance.refresh,
      'user': instance.user,
    };

Store _$StoreFromJson(Map<String, dynamic> json) => Store(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['isActive'] as bool,
      timezone: json['timezone'] as String?,
    );

Map<String, dynamic> _$StoreToJson(Store instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'address': instance.address,
      'phone': instance.phone,
      'email': instance.email,
      'isActive': instance.isActive,
      'timezone': instance.timezone,
    };

ShelfLocation _$ShelfLocationFromJson(Map<String, dynamic> json) =>
    ShelfLocation(
      id: (json['id'] as num).toInt(),
      store: (json['store'] as num).toInt(),
      aisle: json['aisle'] as String,
      section: json['section'] as String,
      position: json['position'] as String?,
      locationCode: json['locationCode'] as String,
      qrCode: json['qrCode'] as String?,
      qrCodeImage: json['qrCodeImage'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      description: json['description'] as String?,
      xCoordinate: (json['xCoordinate'] as num?)?.toDouble(),
      yCoordinate: (json['yCoordinate'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool,
      fullLocation: json['fullLocation'] as String,
    );

Map<String, dynamic> _$ShelfLocationToJson(ShelfLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'store': instance.store,
      'aisle': instance.aisle,
      'section': instance.section,
      'position': instance.position,
      'locationCode': instance.locationCode,
      'qrCode': instance.qrCode,
      'qrCodeImage': instance.qrCodeImage,
      'capacity': instance.capacity,
      'description': instance.description,
      'xCoordinate': instance.xCoordinate,
      'yCoordinate': instance.yCoordinate,
      'isActive': instance.isActive,
      'fullLocation': instance.fullLocation,
    };

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      barcode: json['barcode'] as String,
      sku: json['sku'] as String?,
      costPrice: (json['costPrice'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      minStockLevel: (json['minStockLevel'] as num).toInt(),
      image: json['image'] as String?,
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'barcode': instance.barcode,
      'sku': instance.sku,
      'costPrice': instance.costPrice,
      'sellingPrice': instance.sellingPrice,
      'quantity': instance.quantity,
      'minStockLevel': instance.minStockLevel,
      'image': instance.image,
    };

ProductBatch _$ProductBatchFromJson(Map<String, dynamic> json) => ProductBatch(
      id: (json['id'] as num).toInt(),
      gtin: json['gtin'] as String,
      batchNumber: json['batchNumber'] as String,
      gs1Barcode: json['gs1Barcode'] as String?,
      product: (json['product'] as num).toInt(),
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      originalQuantity: (json['originalQuantity'] as num).toInt(),
      expiryDate: json['expiryDate'] as String,
      manufactureDate: json['manufactureDate'] as String?,
      status: json['status'] as String,
      supplier: (json['supplier'] as num?)?.toInt(),
      supplierName: json['supplierName'] as String?,
      shipmentNumber: json['shipmentNumber'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      unitCost: (json['unitCost'] as num).toDouble(),
      unitSellingPrice: (json['unitSellingPrice'] as num).toDouble(),
      store: (json['store'] as num).toInt(),
      storeName: json['storeName'] as String,
      daysUntilExpiry: (json['daysUntilExpiry'] as num).toInt(),
      expiryStatus: json['expiryStatus'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ProductBatchToJson(ProductBatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gtin': instance.gtin,
      'batchNumber': instance.batchNumber,
      'gs1Barcode': instance.gs1Barcode,
      'product': instance.product,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'originalQuantity': instance.originalQuantity,
      'expiryDate': instance.expiryDate,
      'manufactureDate': instance.manufactureDate,
      'status': instance.status,
      'supplier': instance.supplier,
      'supplierName': instance.supplierName,
      'shipmentNumber': instance.shipmentNumber,
      'invoiceNumber': instance.invoiceNumber,
      'unitCost': instance.unitCost,
      'unitSellingPrice': instance.unitSellingPrice,
      'store': instance.store,
      'storeName': instance.storeName,
      'daysUntilExpiry': instance.daysUntilExpiry,
      'expiryStatus': instance.expiryStatus,
      'totalValue': instance.totalValue,
      'createdAt': instance.createdAt.toIso8601String(),
    };

ReceivingLog _$ReceivingLogFromJson(Map<String, dynamic> json) => ReceivingLog(
      id: (json['id'] as num).toInt(),
      receiptNumber: json['receiptNumber'] as String,
      shipmentNumber: json['shipmentNumber'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      purchaseOrder: json['purchaseOrder'] as String?,
      supplier: (json['supplier'] as num?)?.toInt(),
      supplierName: json['supplierName'] as String?,
      store: (json['store'] as num).toInt(),
      storeName: json['storeName'] as String,
      receivedDate: DateTime.parse(json['receivedDate'] as String),
      totalItems: (json['totalItems'] as num).toInt(),
      totalValue: (json['totalValue'] as num).toDouble(),
      status: json['status'] as String,
      hasExpiryIssues: json['hasExpiryIssues'] as bool,
      validationNotes: json['validationNotes'] as String?,
      palletPhoto: json['palletPhoto'] as String?,
      invoicePhoto: json['invoicePhoto'] as String?,
    );

Map<String, dynamic> _$ReceivingLogToJson(ReceivingLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'receiptNumber': instance.receiptNumber,
      'shipmentNumber': instance.shipmentNumber,
      'invoiceNumber': instance.invoiceNumber,
      'purchaseOrder': instance.purchaseOrder,
      'supplier': instance.supplier,
      'supplierName': instance.supplierName,
      'store': instance.store,
      'storeName': instance.storeName,
      'receivedDate': instance.receivedDate.toIso8601String(),
      'totalItems': instance.totalItems,
      'totalValue': instance.totalValue,
      'status': instance.status,
      'hasExpiryIssues': instance.hasExpiryIssues,
      'validationNotes': instance.validationNotes,
      'palletPhoto': instance.palletPhoto,
      'invoicePhoto': instance.invoicePhoto,
    };

ShelfAudit _$ShelfAuditFromJson(Map<String, dynamic> json) => ShelfAudit(
      id: (json['id'] as num).toInt(),
      auditNumber: json['auditNumber'] as String,
      auditDate: DateTime.parse(json['auditDate'] as String),
      store: (json['store'] as num).toInt(),
      storeName: json['storeName'] as String,
      shelfLocation: (json['shelfLocation'] as num?)?.toInt(),
      locationCode: json['locationCode'] as String?,
      scope: json['scope'] as String,
      category: (json['category'] as num?)?.toInt(),
      itemsChecked: (json['itemsChecked'] as num).toInt(),
      itemsExpired: (json['itemsExpired'] as num).toInt(),
      itemsNearExpiry: (json['itemsNearExpiry'] as num).toInt(),
      itemsDamaged: (json['itemsDamaged'] as num).toInt(),
      itemsMisplaced: (json['itemsMisplaced'] as num).toInt(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      actionRequired: json['actionRequired'] as String?,
    );

Map<String, dynamic> _$ShelfAuditToJson(ShelfAudit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'auditNumber': instance.auditNumber,
      'auditDate': instance.auditDate.toIso8601String(),
      'store': instance.store,
      'storeName': instance.storeName,
      'shelfLocation': instance.shelfLocation,
      'locationCode': instance.locationCode,
      'scope': instance.scope,
      'category': instance.category,
      'itemsChecked': instance.itemsChecked,
      'itemsExpired': instance.itemsExpired,
      'itemsNearExpiry': instance.itemsNearExpiry,
      'itemsDamaged': instance.itemsDamaged,
      'itemsMisplaced': instance.itemsMisplaced,
      'status': instance.status,
      'notes': instance.notes,
      'actionRequired': instance.actionRequired,
    };

AuditItem _$AuditItemFromJson(Map<String, dynamic> json) => AuditItem(
      id: (json['id'] as num).toInt(),
      audit: (json['audit'] as num).toInt(),
      batch: (json['batch'] as num).toInt(),
      productName: json['productName'] as String,
      batchNumber: json['batchNumber'] as String,
      quantityFound: (json['quantityFound'] as num).toInt(),
      quantityExpected: (json['quantityExpected'] as num?)?.toInt(),
      status: json['status'] as String,
      photo: json['photo'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$AuditItemToJson(AuditItem instance) => <String, dynamic>{
      'id': instance.id,
      'audit': instance.audit,
      'batch': instance.batch,
      'productName': instance.productName,
      'batchNumber': instance.batchNumber,
      'quantityFound': instance.quantityFound,
      'quantityExpected': instance.quantityExpected,
      'status': instance.status,
      'photo': instance.photo,
      'notes': instance.notes,
    };

ExpiryAlert _$ExpiryAlertFromJson(Map<String, dynamic> json) => ExpiryAlert(
      id: (json['id'] as num).toInt(),
      batch: (json['batch'] as num).toInt(),
      batchDetails: json['batchDetails'] == null
          ? null
          : ProductBatch.fromJson(json['batchDetails'] as Map<String, dynamic>),
      store: (json['store'] as num).toInt(),
      storeName: json['storeName'] as String,
      shelfLocation: (json['shelfLocation'] as num?)?.toInt(),
      locationCode: json['locationCode'] as String?,
      severity: json['severity'] as String,
      daysUntilExpiry: (json['daysUntilExpiry'] as num).toInt(),
      quantityAtRisk: (json['quantityAtRisk'] as num).toInt(),
      estimatedLoss: (json['estimatedLoss'] as num).toDouble(),
      suggestedAction: json['suggestedAction'] as String,
      suggestedDiscount: (json['suggestedDiscount'] as num?)?.toDouble(),
      isAcknowledged: json['isAcknowledged'] as bool,
      acknowledgedByName: json['acknowledgedByName'] as String?,
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
      isResolved: json['isResolved'] as bool,
      resolutionAction: json['resolutionAction'] as String?,
      resolvedByName: json['resolvedByName'] as String?,
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ExpiryAlertToJson(ExpiryAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batch': instance.batch,
      'batchDetails': instance.batchDetails,
      'store': instance.store,
      'storeName': instance.storeName,
      'shelfLocation': instance.shelfLocation,
      'locationCode': instance.locationCode,
      'severity': instance.severity,
      'daysUntilExpiry': instance.daysUntilExpiry,
      'quantityAtRisk': instance.quantityAtRisk,
      'estimatedLoss': instance.estimatedLoss,
      'suggestedAction': instance.suggestedAction,
      'suggestedDiscount': instance.suggestedDiscount,
      'isAcknowledged': instance.isAcknowledged,
      'acknowledgedByName': instance.acknowledgedByName,
      'acknowledgedAt': instance.acknowledgedAt?.toIso8601String(),
      'isResolved': instance.isResolved,
      'resolutionAction': instance.resolutionAction,
      'resolvedByName': instance.resolvedByName,
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      assignedTo: (json['assignedTo'] as num).toInt(),
      assignedToName: json['assignedToName'] as String,
      assignedBy: (json['assignedBy'] as num?)?.toInt(),
      assignedByName: json['assignedByName'] as String?,
      store: (json['store'] as num).toInt(),
      storeName: json['storeName'] as String,
      taskType: json['taskType'] as String,
      priority: json['priority'] as String,
      shelfLocation: (json['shelfLocation'] as num?)?.toInt(),
      locationCode: json['locationCode'] as String?,
      batch: (json['batch'] as num?)?.toInt(),
      batchNumber: json['batchNumber'] as String?,
      alert: (json['alert'] as num?)?.toInt(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: json['status'] as String,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      completionNotes: json['completionNotes'] as String?,
      completionPhoto: json['completionPhoto'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'assignedTo': instance.assignedTo,
      'assignedToName': instance.assignedToName,
      'assignedBy': instance.assignedBy,
      'assignedByName': instance.assignedByName,
      'store': instance.store,
      'storeName': instance.storeName,
      'taskType': instance.taskType,
      'priority': instance.priority,
      'shelfLocation': instance.shelfLocation,
      'locationCode': instance.locationCode,
      'batch': instance.batch,
      'batchNumber': instance.batchNumber,
      'alert': instance.alert,
      'dueDate': instance.dueDate.toIso8601String(),
      'status': instance.status,
      'completedAt': instance.completedAt?.toIso8601String(),
      'completionNotes': instance.completionNotes,
      'completionPhoto': instance.completionPhoto,
      'createdAt': instance.createdAt.toIso8601String(),
    };

DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) =>
    DashboardSummary(
      totalProducts: (json['totalProducts'] as num).toInt(),
      totalBatches: (json['totalBatches'] as num).toInt(),
      criticalAlerts: (json['criticalAlerts'] as num).toInt(),
      pendingTasks: (json['pendingTasks'] as num).toInt(),
      wastageThisMonth: (json['wastageThisMonth'] as num).toDouble(),
      revenueRecovered: (json['revenueRecovered'] as num).toDouble(),
      topExpiring: (json['topExpiring'] as List<dynamic>)
          .map((e) => ProductBatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentAudits: (json['recentAudits'] as List<dynamic>)
          .map((e) => ShelfAudit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardSummaryToJson(DashboardSummary instance) =>
    <String, dynamic>{
      'totalProducts': instance.totalProducts,
      'totalBatches': instance.totalBatches,
      'criticalAlerts': instance.criticalAlerts,
      'pendingTasks': instance.pendingTasks,
      'wastageThisMonth': instance.wastageThisMonth,
      'revenueRecovered': instance.revenueRecovered,
      'topExpiring': instance.topExpiring,
      'recentAudits': instance.recentAudits,
    };

ExpiryAnalytics _$ExpiryAnalyticsFromJson(Map<String, dynamic> json) =>
    ExpiryAnalytics(
      totalBatches: (json['totalBatches'] as num).toInt(),
      expiringCritical: (json['expiringCritical'] as num).toInt(),
      expiringHigh: (json['expiringHigh'] as num).toInt(),
      expiringMedium: (json['expiringMedium'] as num).toInt(),
      totalAtRiskValue: (json['totalAtRiskValue'] as num).toDouble(),
      topExpiringProducts: (json['topExpiringProducts'] as List<dynamic>)
          .map((e) => ProductBatch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExpiryAnalyticsToJson(ExpiryAnalytics instance) =>
    <String, dynamic>{
      'totalBatches': instance.totalBatches,
      'expiringCritical': instance.expiringCritical,
      'expiringHigh': instance.expiringHigh,
      'expiringMedium': instance.expiringMedium,
      'totalAtRiskValue': instance.totalAtRiskValue,
      'topExpiringProducts': instance.topExpiringProducts,
    };

DynamicPricing _$DynamicPricingFromJson(Map<String, dynamic> json) =>
    DynamicPricing(
      id: (json['id'] as num).toInt(),
      batch: (json['batch'] as num).toInt(),
      batchDetails: json['batchDetails'] == null
          ? null
          : ProductBatch.fromJson(json['batchDetails'] as Map<String, dynamic>),
      store: (json['store'] as num).toInt(),
      storeName: json['storeName'] as String,
      originalPrice: (json['originalPrice'] as num).toDouble(),
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
      discountedPrice: (json['discountedPrice'] as num).toDouble(),
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      effectiveUntil: json['effectiveUntil'] == null
          ? null
          : DateTime.parse(json['effectiveUntil'] as String),
      reason: json['reason'] as String,
      daysToExpiry: (json['daysToExpiry'] as num?)?.toInt(),
      isActive: json['isActive'] as bool,
      isSyncedToPos: json['isSyncedToPos'] as bool,
      status: json['status'] as String,
      quantitySold: (json['quantitySold'] as num).toInt(),
      revenueGenerated: (json['revenueGenerated'] as num).toDouble(),
      wastePrevented: (json['wastePrevented'] as num).toInt(),
    );

Map<String, dynamic> _$DynamicPricingToJson(DynamicPricing instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batch': instance.batch,
      'batchDetails': instance.batchDetails,
      'store': instance.store,
      'storeName': instance.storeName,
      'originalPrice': instance.originalPrice,
      'discountPercentage': instance.discountPercentage,
      'discountedPrice': instance.discountedPrice,
      'effectiveFrom': instance.effectiveFrom.toIso8601String(),
      'effectiveUntil': instance.effectiveUntil?.toIso8601String(),
      'reason': instance.reason,
      'daysToExpiry': instance.daysToExpiry,
      'isActive': instance.isActive,
      'isSyncedToPos': instance.isSyncedToPos,
      'status': instance.status,
      'quantitySold': instance.quantitySold,
      'revenueGenerated': instance.revenueGenerated,
      'wastePrevented': instance.wastePrevented,
    };

WastageReport _$WastageReportFromJson(Map<String, dynamic> json) =>
    WastageReport(
      id: (json['id'] as num).toInt(),
      reportNumber: json['reportNumber'] as String,
      reportDate: DateTime.parse(json['reportDate'] as String),
      store: (json['store'] as num).toInt(),
      storeName: json['storeName'] as String,
      periodStart: json['periodStart'] as String,
      periodEnd: json['periodEnd'] as String,
      totalItemsWasted: (json['totalItemsWasted'] as num).toInt(),
      totalMonetaryLoss: (json['totalMonetaryLoss'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$WastageReportToJson(WastageReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reportNumber': instance.reportNumber,
      'reportDate': instance.reportDate.toIso8601String(),
      'store': instance.store,
      'storeName': instance.storeName,
      'periodStart': instance.periodStart,
      'periodEnd': instance.periodEnd,
      'totalItemsWasted': instance.totalItemsWasted,
      'totalMonetaryLoss': instance.totalMonetaryLoss,
      'status': instance.status,
      'notes': instance.notes,
    };
