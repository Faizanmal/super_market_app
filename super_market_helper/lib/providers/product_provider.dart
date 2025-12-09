import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../config/constants.dart';

/// Product provider for state management
/// Manages product data and business logic using Provider pattern
class ProductProvider extends ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  final NotificationService _notificationService = NotificationService();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String? _selectedCategory;
  ProductSortOption _sortOption = ProductSortOption.nameAsc;
  bool _isLoading = false;

  // Getters
  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  ProductSortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;

  /// Initialize provider and load products
  Future<void> init() async {
    await loadProducts();
    await _checkAndSendNotifications();
  }

  /// Load all products from storage
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = _storageService.getAllProducts();
      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new product
  Future<bool> addProduct(Product product) async {
    try {
      await _storageService.addProduct(product);
      _products.add(product);
      _applyFiltersAndSort();
      notifyListeners();

      // Check if product is expiring soon and send notification
      if (product.isExpiringSoon) {
        await _notificationService.showExpiryAlert(product);
      }

      return true;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    }
  }

  /// Update an existing product
  Future<bool> updateProduct(Product product) async {
    try {
      await _storageService.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        _applyFiltersAndSort();
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  /// Delete a product
  Future<bool> deleteProduct(String productId) async {
    try {
      await _storageService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      _applyFiltersAndSort();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  /// Get a single product by ID
  Product? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Sort products
  void sortProducts(ProductSortOption option) {
    _sortOption = option;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Apply filters and sorting
  void _applyFiltersAndSort() {
    _filteredProducts = List.from(_products);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredProducts = _filteredProducts.where((product) {
        return product.name.toLowerCase().contains(lowerQuery) ||
            product.category.toLowerCase().contains(lowerQuery) ||
            product.supplier.toLowerCase().contains(lowerQuery) ||
            (product.barcode?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case ProductSortOption.nameAsc:
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSortOption.nameDesc:
        _filteredProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ProductSortOption.expiryDateAsc:
        _filteredProducts.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case ProductSortOption.expiryDateDesc:
        _filteredProducts.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
        break;
      case ProductSortOption.quantityAsc:
        _filteredProducts.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case ProductSortOption.quantityDesc:
        _filteredProducts.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case ProductSortOption.categoryAsc:
        _filteredProducts.sort((a, b) => a.category.compareTo(b.category));
        break;
    }
  }

  /// Get expiring products
  List<Product> getExpiringProducts() {
    return _products.where((p) => p.isExpiringSoon && !p.isExpired).toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  /// Get expired products
  List<Product> getExpiredProducts() {
    return _products.where((p) => p.isExpired).toList()
      ..sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
  }

  /// Get low stock products
  List<Product> getLowStockProducts() {
    return _products
        .where((p) => p.stockStatus == StockStatus.lowStock)
        .toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
  }

  /// Get out of stock products
  List<Product> getOutOfStockProducts() {
    return _products.where((p) => p.stockStatus == StockStatus.outOfStock).toList();
  }

  /// Get product by barcode
  Product? getProductByBarcode(String barcode) {
    return _storageService.getProductByBarcode(barcode);
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalProducts': _products.length,
      'totalStockValue': _storageService.getTotalStockSellingValue(),
      'expiringCount': getExpiringProducts().length,
      'expiredCount': getExpiredProducts().length,
      'lowStockCount': getLowStockProducts().length,
      'outOfStockCount': getOutOfStockProducts().length,
      'categoryCount': _storageService.getProductCountByCategory(),
    };
  }

  /// Get products by expiry status
  List<Product> getProductsByExpiryStatus(ExpiryStatus status) {
    return _products.where((p) => p.expiryStatus == status).toList();
  }

  /// Check and send notifications for expiring/low stock products
  Future<void> _checkAndSendNotifications() async {
    final expiringProducts = getExpiringProducts();
    final lowStockProducts = getLowStockProducts();

    // Send notifications for expiring products
    for (var product in expiringProducts) {
      if (product.daysUntilExpiry <= AppConstants.expiryDangerDays) {
        await _notificationService.showExpiryAlert(product);
      }
    }

    // Send notifications for low stock products
    for (var product in lowStockProducts) {
      await _notificationService.showLowStockAlert(product);
    }
  }

  /// Refresh data and notifications
  Future<void> refresh() async {
    await loadProducts();
    await _checkAndSendNotifications();
  }
}
