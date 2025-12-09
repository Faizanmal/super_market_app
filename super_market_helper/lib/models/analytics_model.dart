import 'package:hive/hive.dart';

part 'analytics_model.g.dart';

/// Smart analytics data models

@HiveType(typeId: 5)
class DemandForecast {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String productName;

  @HiveField(2)
  int currentStock;

  @HiveField(3)
  DateTime predictedReorderDate;

  @HiveField(4)
  int recommendedQuantity;

  @HiveField(5)
  int daysUntilReorder;

  DemandForecast({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.predictedReorderDate,
    required this.recommendedQuantity,
    required this.daysUntilReorder,
  });

  factory DemandForecast.fromJson(Map<String, dynamic> json) => DemandForecast(
        productId: json['product_id'],
        productName: json['product_name'],
        currentStock: json['current_stock'],
        predictedReorderDate: DateTime.parse(json['predicted_reorder_date']),
        recommendedQuantity: json['recommended_quantity'],
        daysUntilReorder: json['days_until_reorder'],
      );
}

@HiveType(typeId: 6)
class StockHealthScore {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String productName;

  @HiveField(2)
  int healthScore;

  @HiveField(3)
  String status; // 'critical', 'warning', 'good'

  @HiveField(4)
  int currentStock;

  StockHealthScore({
    required this.productId,
    required this.productName,
    required this.healthScore,
    required this.status,
    required this.currentStock,
  });

  factory StockHealthScore.fromJson(Map<String, dynamic> json) =>
      StockHealthScore(
        productId: json['product_id'],
        productName: json['product_name'],
        healthScore: json['health_score'],
        status: json['status'],
        currentStock: json['current_stock'] ?? 0,
      );
}

class ProfitAnalysis {
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double profitMargin;
  final List<TopProduct> topProducts;
  final int periodDays;

  ProfitAnalysis({
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.profitMargin,
    required this.topProducts,
    required this.periodDays,
  });

  factory ProfitAnalysis.fromJson(Map<String, dynamic> json) => ProfitAnalysis(
        totalRevenue: double.parse(json['total_revenue']),
        totalCost: double.parse(json['total_cost']),
        totalProfit: double.parse(json['total_profit']),
        profitMargin: (json['profit_margin'] as num).toDouble(),
        topProducts: (json['top_products'] as List)
            .map((item) => TopProduct.fromJson(item))
            .toList(),
        periodDays: json['period_days'],
      );
}

class TopProduct {
  final String productName;
  final int quantitySold;
  final double revenue;
  final double profit;
  final double marginPercent;

  TopProduct({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.profit,
    required this.marginPercent,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
        productName: json['product_name'],
        quantitySold: json['quantity_sold'],
        revenue: double.parse(json['revenue']),
        profit: double.parse(json['profit']),
        marginPercent: (json['margin_percent'] as num?)?.toDouble() ?? 0.0,
      );
}

class SmartAlert {
  final String type;
  final String productId;
  final String productName;
  final String message;
  final String? recommendation;
  final int? recommendedQuantity;
  final int? healthScore;

  SmartAlert({
    required this.type,
    required this.productId,
    required this.productName,
    required this.message,
    this.recommendation,
    this.recommendedQuantity,
    this.healthScore,
  });

  factory SmartAlert.fromJson(Map<String, dynamic> json) => SmartAlert(
        type: json['type'],
        productId: json['product_id'],
        productName: json['product_name'],
        message: json['message'],
        recommendation: json['recommendation'],
        recommendedQuantity: json['recommended_quantity'],
        healthScore: json['health_score'],
      );
}

class InventoryValuation {
  final double totalCostValue;
  final double totalSellingValue;
  final double potentialProfit;
  final int totalProducts;
  final Map<String, CategoryBreakdown> categoryBreakdown;

  InventoryValuation({
    required this.totalCostValue,
    required this.totalSellingValue,
    required this.potentialProfit,
    required this.totalProducts,
    required this.categoryBreakdown,
  });

  factory InventoryValuation.fromJson(Map<String, dynamic> json) {
    final breakdown = <String, CategoryBreakdown>{};
    if (json['category_breakdown'] != null) {
      (json['category_breakdown'] as Map<String, dynamic>).forEach((key, value) {
        breakdown[key] = CategoryBreakdown.fromJson(value);
      });
    }

    return InventoryValuation(
      totalCostValue: (json['total_cost_value'] as num).toDouble(),
      totalSellingValue: (json['total_selling_value'] as num).toDouble(),
      potentialProfit: (json['potential_profit'] as num).toDouble(),
      totalProducts: json['total_products'],
      categoryBreakdown: breakdown,
    );
  }
}

class CategoryBreakdown {
  final double costValue;
  final double sellingValue;
  final int quantity;
  final int productCount;

  CategoryBreakdown({
    required this.costValue,
    required this.sellingValue,
    required this.quantity,
    required this.productCount,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      CategoryBreakdown(
        costValue: (json['cost_value'] as num).toDouble(),
        sellingValue: (json['selling_value'] as num).toDouble(),
        quantity: json['quantity'],
        productCount: json['product_count'],
      );
}

class DashboardSummary {
  final InventoryStatus inventory;
  final ExpiryStatus expiry;
  final ValuationStatus valuation;
  final ActivityStatus activity;
  final List<TopExpiringProduct> topExpiring;
  final List<RecentAudit> recentAudits;

  DashboardSummary({
    required this.inventory,
    required this.expiry,
    required this.valuation,
    required this.activity,
    required this.topExpiring,
    required this.recentAudits,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        inventory: InventoryStatus.fromJson(json['inventory']),
        expiry: ExpiryStatus.fromJson(json['expiry']),
        valuation: ValuationStatus.fromJson(json['valuation']),
        activity: ActivityStatus.fromJson(json['activity']),
        topExpiring: (json['top_expiring'] as List? ?? [])
            .map((item) => TopExpiringProduct.fromJson(item))
            .toList(),
        recentAudits: (json['recent_audits'] as List? ?? [])
            .map((item) => RecentAudit.fromJson(item))
            .toList(),
      );

  // Legacy getters for backward compatibility
  int get criticalAlertsCount => expiry.expired;
  int get expiringSoonCount => expiry.expiringSoon;
  int get pendingTasksCount => activity.recentMovements;
}

class InventoryStatus {
  final int totalProducts;
  final int lowStock;
  final int outOfStock;
  final int healthyStock;

  InventoryStatus({
    required this.totalProducts,
    required this.lowStock,
    required this.outOfStock,
    required this.healthyStock,
  });

  factory InventoryStatus.fromJson(Map<String, dynamic> json) =>
      InventoryStatus(
        totalProducts: json['total_products'],
        lowStock: json['low_stock'],
        outOfStock: json['out_of_stock'],
        healthyStock: json['healthy_stock'],
      );
}

class ExpiryStatus {
  final int expired;
  final int expiringSoon;
  final int fresh;

  ExpiryStatus({
    required this.expired,
    required this.expiringSoon,
    required this.fresh,
  });

  factory ExpiryStatus.fromJson(Map<String, dynamic> json) => ExpiryStatus(
        expired: json['expired'],
        expiringSoon: json['expiring_soon'],
        fresh: json['fresh'],
      );
}

class ValuationStatus {
  final double totalCostValue;
  final double totalSellingValue;
  final double potentialProfit;

  ValuationStatus({
    required this.totalCostValue,
    required this.totalSellingValue,
    required this.potentialProfit,
  });

  factory ValuationStatus.fromJson(Map<String, dynamic> json) =>
      ValuationStatus(
        totalCostValue: (json['total_cost_value'] as num).toDouble(),
        totalSellingValue: (json['total_selling_value'] as num).toDouble(),
        potentialProfit: (json['potential_profit'] as num).toDouble(),
      );
}

class ActivityStatus {
  final int recentMovements;

  ActivityStatus({required this.recentMovements});

  factory ActivityStatus.fromJson(Map<String, dynamic> json) =>
      ActivityStatus(recentMovements: json['recent_movements']);
}

/// Enhanced Dashboard Summary Model for comprehensive analytics
class EnhancedDashboardSummary {
  final int totalProducts;
  final int totalBatches;
  final int criticalAlerts;
  final int pendingTasks;
  final double wastageThisMonth;
  final double revenueRecovered;
  final List<TopExpiringProduct> topExpiring;
  final List<RecentAudit> recentAudits;

  EnhancedDashboardSummary({
    required this.totalProducts,
    required this.totalBatches,
    required this.criticalAlerts,
    required this.pendingTasks,
    required this.wastageThisMonth,
    required this.revenueRecovered,
    required this.topExpiring,
    required this.recentAudits,
  });

  factory EnhancedDashboardSummary.fromJson(Map<String, dynamic> json) => EnhancedDashboardSummary(
        totalProducts: json['total_products'] ?? 0,
        totalBatches: json['total_batches'] ?? 0,
        criticalAlerts: json['critical_alerts'] ?? 0,
        pendingTasks: json['pending_tasks'] ?? 0,
        wastageThisMonth: (json['wastage_this_month'] as num?)?.toDouble() ?? 0.0,
        revenueRecovered: (json['revenue_recovered'] as num?)?.toDouble() ?? 0.0,
        topExpiring: (json['top_expiring'] as List? ?? [])
            .map((item) => TopExpiringProduct.fromJson(item))
            .toList(),
        recentAudits: (json['recent_audits'] as List? ?? [])
            .map((item) => RecentAudit.fromJson(item))
            .toList(),
      );
}

class TopExpiringProduct {
  final String productName;
  final String batchNumber;
  final DateTime expiryDate;
  final int daysUntilExpiry;
  final int quantity;

  TopExpiringProduct({
    required this.productName,
    required this.batchNumber,
    required this.expiryDate,
    required this.daysUntilExpiry,
    required this.quantity,
  });

  factory TopExpiringProduct.fromJson(Map<String, dynamic> json) => TopExpiringProduct(
        productName: json['product_name'] ?? '',
        batchNumber: json['batch_number'] ?? '',
        expiryDate: DateTime.parse(json['expiry_date']),
        daysUntilExpiry: json['days_until_expiry'] ?? 0,
        quantity: json['quantity'] ?? 0,
      );
}

class RecentAudit {
  final String auditNumber;
  final DateTime auditDate;
  final String scope;
  final int itemsChecked;
  final int itemsExpired;

  RecentAudit({
    required this.auditNumber,
    required this.auditDate,
    required this.scope,
    required this.itemsChecked,
    required this.itemsExpired,
  });

  factory RecentAudit.fromJson(Map<String, dynamic> json) => RecentAudit(
        auditNumber: json['audit_number'] ?? '',
        auditDate: DateTime.parse(json['audit_date']),
        scope: json['scope'] ?? '',
        itemsChecked: json['items_checked'] ?? 0,
        itemsExpired: json['items_expired'] ?? 0,
      );
}
