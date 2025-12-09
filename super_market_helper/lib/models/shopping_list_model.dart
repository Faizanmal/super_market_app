import 'package:hive/hive.dart';

part 'shopping_list_model.g.dart';

@HiveType(typeId: 3)
class ShoppingList extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String status; // 'active', 'completed', 'cancelled'

  @HiveField(3)
  String? notes;

  @HiveField(4)
  List<ShoppingListItem> items;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? completedAt;

  ShoppingList({
    required this.id,
    required this.name,
    required this.status,
    this.notes,
    required this.items,
    required this.createdAt,
    this.completedAt,
  });

  int get totalItems => items.length;
  int get completedItems => items.where((item) => item.isPurchased).length;
  double get estimatedTotal => items.fold(0.0, (sum, item) => sum + item.estimatedCost);
  double get completionPercentage =>
      totalItems > 0 ? (completedItems / totalItems) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status,
        'notes': notes,
        'items': items.map((item) => item.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
        id: json['id'],
        name: json['name'],
        status: json['status'],
        notes: json['notes'],
        items: (json['items'] as List?)
                ?.map((item) => ShoppingListItem.fromJson(item))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['created_at']),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
      );
}

@HiveType(typeId: 4)
class ShoppingListItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? productId;

  @HiveField(2)
  String itemName;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  double estimatedPrice;

  @HiveField(5)
  bool isPurchased;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime createdAt;

  ShoppingListItem({
    required this.id,
    this.productId,
    required this.itemName,
    required this.quantity,
    required this.estimatedPrice,
    this.isPurchased = false,
    this.notes,
    required this.createdAt,
  });

  double get estimatedCost => quantity * estimatedPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'item_name': itemName,
        'quantity': quantity,
        'estimated_price': estimatedPrice,
        'is_purchased': isPurchased,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) =>
      ShoppingListItem(
        id: json['id'],
        productId: json['product_id'],
        itemName: json['item_name'],
        quantity: json['quantity'],
        estimatedPrice: (json['estimated_price'] as num).toDouble(),
        isPurchased: json['is_purchased'] ?? false,
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
      );
}
