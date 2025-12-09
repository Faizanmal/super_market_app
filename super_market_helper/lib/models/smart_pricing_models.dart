/// Smart Pricing Models for Flutter
class DynamicPrice {
  final int id;
  final int productId;
  final String productName;
  final double originalPrice;
  final double suggestedPrice;
  final double discountAmount;
  final double discountPercent;
  final List<int> appliedRules;
  final Map<String, dynamic> pricingFactors;
  final String status;
  final DateTime validFrom;
  final DateTime? validUntil;
  final DateTime createdAt;

  DynamicPrice({
    required this.id,
    required this.productId,
    required this.productName,
    required this.originalPrice,
    required this.suggestedPrice,
    required this.discountAmount,
    required this.discountPercent,
    required this.appliedRules,
    required this.pricingFactors,
    required this.status,
    required this.validFrom,
    this.validUntil,
    required this.createdAt,
  });

  factory DynamicPrice.fromJson(Map<String, dynamic> json) {
    return DynamicPrice(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'] ?? '',
      originalPrice: double.parse(json['original_price'].toString()),
      suggestedPrice: double.parse(json['suggested_price'].toString()),
      discountAmount: double.parse(json['discount_amount'].toString()),
      discountPercent: double.parse(json['discount_percent'].toString()),
      appliedRules: List<int>.from(json['applied_rules'] ?? []),
      pricingFactors: Map<String, dynamic>.from(json['pricing_factors'] ?? {}),
      status: json['status'],
      validFrom: DateTime.parse(json['valid_from']),
      validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  double get savingsAmount => originalPrice - suggestedPrice;
}

class PricingRecommendation {
  final int productId;
  final String productName;
  final String reason;
  final int? daysToExpiry;
  final int? currentStock;
  final double currentPrice;
  final double suggestedDiscountPercent;
  final double suggestedPrice;
  final String priority;

  PricingRecommendation({
    required this.productId,
    required this.productName,
    required this.reason,
    this.daysToExpiry,
    this.currentStock,
    required this.currentPrice,
    required this.suggestedDiscountPercent,
    required this.suggestedPrice,
    required this.priority,
  });

  factory PricingRecommendation.fromJson(Map<String, dynamic> json) {
    return PricingRecommendation(
      productId: json['product_id'],
      productName: json['product_name'],
      reason: json['reason'],
      daysToExpiry: json['days_to_expiry'],
      currentStock: json['current_stock'],
      currentPrice: double.parse(json['current_price'].toString()),
      suggestedDiscountPercent: double.parse(json['suggested_discount_percent'].toString()),
      suggestedPrice: double.parse(json['suggested_price'].toString()),
      priority: json['priority'],
    );
  }

  String get reasonDisplay {
    switch (reason) {
      case 'expiring_soon':
        return 'Expiring Soon';
      case 'overstock':
        return 'Overstock';
      case 'slow_moving':
        return 'Slow Moving';
      default:
        return reason;
    }
  }
}

class CompetitorPrice {
  final int id;
  final int productId;
  final String productName;
  final String competitorName;
  final double price;
  final double ourPrice;
  final double priceDifference;
  final double priceDifferencePercent;
  final bool isCheaper;
  final DateTime observedAt;

  CompetitorPrice({
    required this.id,
    required this.productId,
    required this.productName,
    required this.competitorName,
    required this.price,
    required this.ourPrice,
    required this.priceDifference,
    required this.priceDifferencePercent,
    required this.isCheaper,
    required this.observedAt,
  });

  factory CompetitorPrice.fromJson(Map<String, dynamic> json) {
    return CompetitorPrice(
      id: json['id'] ?? 0,
      productId: json['product_id'],
      productName: json['product_name'] ?? '',
      competitorName: json['competitor_name'],
      price: double.parse(json['competitor_price'].toString()),
      ourPrice: double.parse(json['our_price'].toString()),
      priceDifference: double.parse(json['price_difference'].toString()),
      priceDifferencePercent: double.parse(json['price_difference_percent'].toString()),
      isCheaper: json['is_cheaper'] ?? false,
      observedAt: DateTime.parse(json['observed_at']),
    );
  }
}

class PriceHistory {
  final double oldPrice;
  final double newPrice;
  final double priceDifference;
  final double percentChange;
  final String changeType;
  final String reason;
  final String? changedBy;
  final DateTime changedAt;

  PriceHistory({
    required this.oldPrice,
    required this.newPrice,
    required this.priceDifference,
    required this.percentChange,
    required this.changeType,
    required this.reason,
    this.changedBy,
    required this.changedAt,
  });

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      oldPrice: double.parse(json['old_price'].toString()),
      newPrice: double.parse(json['new_price'].toString()),
      priceDifference: double.parse(json['price_difference'].toString()),
      percentChange: double.parse(json['percent_change'].toString()),
      changeType: json['change_type'],
      reason: json['reason'],
      changedBy: json['changed_by'],
      changedAt: DateTime.parse(json['changed_at']),
    );
  }

  bool get isPriceIncrease => percentChange > 0;
}
