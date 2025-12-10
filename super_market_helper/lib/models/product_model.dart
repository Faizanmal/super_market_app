import 'package:hive/hive.dart';
import '../config/constants.dart';

part 'product_model.g.dart';

/// Product model representing inventory items
/// Stores all product information including expiry and stock details
@HiveType(typeId: AppConstants.productTypeId)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  DateTime expiryDate;

  @HiveField(5)
  String supplier;

  @HiveField(6)
  double costPrice;

  @HiveField(7)
  double sellingPrice;

  @HiveField(8)
  String? barcode;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  String? description;

  @HiveField(12)
  String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.expiryDate,
    required this.supplier,
    required this.costPrice,
    required this.sellingPrice,
    this.barcode,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.imageUrl,
  });

  /// Calculate profit margin percentage
  double get profitMargin {
    if (costPrice == 0) return 0;
    return ((sellingPrice - costPrice) / costPrice) * 100;
  }

  /// Calculate total profit for current stock
  double get totalProfit {
    return (sellingPrice - costPrice) * quantity;
  }

  /// Calculate total cost value
  double get totalCostValue {
    return costPrice * quantity;
  }

  /// Calculate total selling value
  double get totalSellingValue {
    return sellingPrice * quantity;
  }

  /// Get expiry status based on current date
  ExpiryStatus get expiryStatus {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;

    if (difference < 0) {
      return ExpiryStatus.expired;
    } else if (difference <= AppConstants.expiryDangerDays) {
      return ExpiryStatus.danger;
    } else if (difference <= AppConstants.expiryWarningDays) {
      return ExpiryStatus.warning;
    } else {
      return ExpiryStatus.fresh;
    }
  }

  /// Get stock status based on quantity
  StockStatus get stockStatus {
    if (quantity == 0) {
      return StockStatus.outOfStock;
    } else if (quantity <= AppConstants.lowStockThreshold) {
      return StockStatus.lowStock;
    } else {
      return StockStatus.inStock;
    }
  }

  /// Check if product is expiring soon
  bool get isExpiringSoon {
    final status = expiryStatus;
    return status == ExpiryStatus.warning || status == ExpiryStatus.danger;
  }

  /// Check if product is expired
  bool get isExpired {
    return expiryStatus == ExpiryStatus.expired;
  }

  /// Get days until expiry (negative if expired)
  int get daysUntilExpiry {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  /// Alias for barcode/id - used in dashboard exports
  String get sku => barcode ?? id;

  /// Alias for quantity - used in dashboard exports
  int get stockQuantity => quantity;

  /// Alias for sellingPrice - used in dashboard exports
  double get price => sellingPrice;

  /// Create a copy of the product with updated fields
  Product copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    DateTime? expiryDate,
    String? supplier,
    double? costPrice,
    double? sellingPrice,
    String? barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      supplier: supplier ?? this.supplier,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Convert product to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'expiryDate': expiryDate.toIso8601String(),
      'supplier': supplier,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'barcode': barcode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  /// Create product from JSON map
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      supplier: json['supplier'] as String,
      costPrice: (json['costPrice'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      barcode: json['barcode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, category: $category, quantity: $quantity, expiryDate: $expiryDate)';
  }
}
