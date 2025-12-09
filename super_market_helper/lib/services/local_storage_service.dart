import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/shopping_list_model.dart';
import '../config/constants.dart';

/// Local storage service using Hive
/// Manages all local database operations for products and users
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Box<Product>? _productsBox;
  Box<User>? _usersBox;
  Box<ShoppingList>? _shoppingListsBox;
  Box? _settingsBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(AppConstants.productTypeId)) {
      Hive.registerAdapter(ProductAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.userTypeId)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ShoppingListAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ShoppingListItemAdapter());
    }

    // Open boxes
    _productsBox = await Hive.openBox<Product>(AppConstants.productsBox);
    _usersBox = await Hive.openBox<User>(AppConstants.usersBox);
    _shoppingListsBox = await Hive.openBox<ShoppingList>('shopping_lists');
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);

    // Create default admin user if no users exist
    if (_usersBox!.isEmpty) {
      await _createDefaultUser();
    }
  }

  /// Create default admin user
  Future<void> _createDefaultUser() async {
    final defaultUser = User(
      id: 'admin-001',
      email: 'admin@supermart.com',
      password: '', // Password will be set during first login
      fullName: 'Admin User',
      role: 'admin',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isActive: true,
    );
    await _usersBox!.put(defaultUser.id, defaultUser);
  }

  // ==================== PRODUCT OPERATIONS ====================

  /// Add a new product
  Future<void> addProduct(Product product) async {
    await _productsBox!.put(product.id, product);
  }

  /// Update an existing product
  Future<void> updateProduct(Product product) async {
    await _productsBox!.put(product.id, product);
  }

  /// Delete a product by ID
  Future<void> deleteProduct(String productId) async {
    await _productsBox!.delete(productId);
  }

  /// Get a single product by ID
  Product? getProduct(String productId) {
    return _productsBox!.get(productId);
  }

  /// Get all products
  List<Product> getAllProducts() {
    return _productsBox!.values.toList();
  }

  /// Get products by category
  List<Product> getProductsByCategory(String category) {
    return _productsBox!.values
        .where((product) => product.category == category)
        .toList();
  }

  /// Get expiring products (within warning threshold)
  List<Product> getExpiringProducts() {
    final now = DateTime.now();
    return _productsBox!.values.where((product) {
      final daysUntilExpiry = product.expiryDate.difference(now).inDays;
      return daysUntilExpiry >= 0 &&
          daysUntilExpiry <= AppConstants.expiryWarningDays;
    }).toList();
  }

  /// Get expired products
  List<Product> getExpiredProducts() {
    final now = DateTime.now();
    return _productsBox!.values
        .where((product) => product.expiryDate.isBefore(now))
        .toList();
  }

  /// Get low stock products
  List<Product> getLowStockProducts() {
    return _productsBox!.values
        .where((product) =>
            product.quantity > 0 &&
            product.quantity <= AppConstants.lowStockThreshold)
        .toList();
  }

  /// Get out of stock products
  List<Product> getOutOfStockProducts() {
    return _productsBox!.values
        .where((product) => product.quantity == 0)
        .toList();
  }

  /// Search products by name or barcode
  List<Product> searchProducts(String query) {
    final lowerQuery = query.toLowerCase();
    return _productsBox!.values.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
          (product.barcode?.toLowerCase().contains(lowerQuery) ?? false) ||
          product.supplier.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get product by barcode
  Product? getProductByBarcode(String barcode) {
    try {
      return _productsBox!.values.firstWhere(
        (product) => product.barcode == barcode,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get total number of products
  int getTotalProductCount() {
    return _productsBox!.length;
  }

  /// Get total stock value (cost)
  double getTotalStockCostValue() {
    return _productsBox!.values.fold(
      0.0,
      (sum, product) => sum + product.totalCostValue,
    );
  }

  /// Get total stock value (selling)
  double getTotalStockSellingValue() {
    return _productsBox!.values.fold(
      0.0,
      (sum, product) => sum + product.totalSellingValue,
    );
  }

  /// Get products grouped by category with count
  Map<String, int> getProductCountByCategory() {
    final Map<String, int> categoryCount = {};
    for (var product in _productsBox!.values) {
      categoryCount[product.category] = 
          (categoryCount[product.category] ?? 0) + 1;
    }
    return categoryCount;
  }

  // ==================== USER OPERATIONS ====================

  /// Add a new user
  Future<void> addUser(User user) async {
    await _usersBox!.put(user.id, user);
  }

  /// Update an existing user
  Future<void> updateUser(User user) async {
    await _usersBox!.put(user.id, user);
  }

  /// Delete a user by ID
  Future<void> deleteUser(String userId) async {
    await _usersBox!.delete(userId);
  }

  /// Get a single user by ID
  User? getUser(String userId) {
    return _usersBox!.get(userId);
  }

  /// Get all users
  List<User> getAllUsers() {
    return _usersBox!.values.toList();
  }

  /// Authenticate user
  User? authenticateUser(String email, String password) {
    try {
      return _usersBox!.values.firstWhere(
        (user) => user.email == email && user.password == password && user.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if email exists
  bool emailExists(String email) {
    return _usersBox!.values.any((user) => user.email == email);
  }

  // ==================== SETTINGS OPERATIONS ====================

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox!.put(key, value);
  }

  /// Get a setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox!.get(key, defaultValue: defaultValue) as T?;
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    await _settingsBox!.delete(key);
  }

  // ==================== SHOPPING LIST OPERATIONS ====================

  /// Add a new shopping list
  Future<void> saveShoppingList(ShoppingList list) async {
    await _shoppingListsBox!.put(list.id, list);
  }

  /// Update shopping list
  Future<void> updateShoppingList(ShoppingList list) async {
    await _shoppingListsBox!.put(list.id, list);
  }

  /// Delete shopping list
  Future<void> deleteShoppingList(String listId) async {
    await _shoppingListsBox!.delete(listId);
  }

  /// Get all shopping lists
  Future<List<ShoppingList>> getShoppingLists() async {
    return _shoppingListsBox!.values.toList();
  }

  /// Get active shopping lists
  Future<List<ShoppingList>> getActiveShoppingLists() async {
    return _shoppingListsBox!.values
        .where((list) => list.status == 'active')
        .toList();
  }

  // ==================== CLEANUP ====================

  /// Clear all products (use with caution)
  Future<void> clearAllProducts() async {
    await _productsBox!.clear();
  }

  /// Clear all users (use with caution)
  Future<void> clearAllUsers() async {
    await _usersBox!.clear();
    await _createDefaultUser();
  }

  /// Close all boxes
  Future<void> close() async {
    await _productsBox?.close();
    await _usersBox?.close();
    await _settingsBox?.close();
  }

  /// Compact boxes (optimize storage)
  Future<void> compact() async {
    await _productsBox?.compact();
    await _usersBox?.compact();
    await _settingsBox?.compact();
  }
}
