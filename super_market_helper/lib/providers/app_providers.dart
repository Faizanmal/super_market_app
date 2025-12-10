/// SuperMart Pro - Enhanced State Management
/// Riverpod Providers for Application State
library;

import 'dart:async';
import 'package:riverpod/riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// AUTH PROVIDERS
// ============================================================================

/// Authentication state
enum AuthStatus { unknown, authenticated, unauthenticated, loading }

/// Auth state model
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// User model
class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final List<Store> stores;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.stores = const [],
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'viewer',
      stores: (json['stores'] as List?)
              ?.map((s) => Store.fromJson(s))
              .toList() ??
          [],
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
    );
  }

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isManager => role == 'store_manager' || isAdmin;
  bool get canManageStock => ['admin', 'super_admin', 'store_manager', 'stock_receiver'].contains(role);
}

/// Store model
class Store {
  final int id;
  final String name;
  final String? address;
  final bool isActive;

  const Store({
    required this.id,
    required this.name,
    this.address,
    this.isActive = true,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      isActive: json['is_active'] ?? true,
    );
  }
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading, isLoading: true);
    
    try {
      // Check for stored tokens and validate
      // final token = await SecureStorageService.instance.getAccessToken();
      // if (token != null) {
      //   final user = await _fetchUserProfile();
      //   state = AuthState(status: AuthStatus.authenticated, user: user);
      // } else {
      //   state = const AuthState(status: AuthStatus.unauthenticated);
      // }
      
      // Placeholder - implement actual token check
      await Future.delayed(const Duration(milliseconds: 500));
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      // Implement actual login
      // final response = await ApiClient.instance.post('/auth/login/', {
      //   'email': email,
      //   'password': password,
      // });
      
      // Placeholder
      await Future.delayed(const Duration(seconds: 1));
      
      final user = User(
        id: 1,
        email: email,
        fullName: 'Demo User',
        role: 'store_manager',
      );
      
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Clear tokens
      // await SecureStorageService.instance.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});


// ============================================================================
// PRODUCT PROVIDERS
// ============================================================================

/// Product model
class Product {
  final int id;
  final String name;
  final String sku;
  final String? barcode;
  final String? description;
  final Category? category;
  final double price;
  final double? costPrice;
  final int quantity;
  final int minStockLevel;
  final DateTime? expiryDate;
  final String status;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.description,
    this.category,
    required this.price,
    this.costPrice,
    required this.quantity,
    this.minStockLevel = 0,
    this.expiryDate,
    this.status = 'active',
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      barcode: json['barcode'],
      description: json['description'],
      category: json['category'] != null 
          ? Category.fromJson(json['category']) 
          : null,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      costPrice: double.tryParse(json['cost_price']?.toString() ?? ''),
      quantity: json['quantity'] ?? 0,
      minStockLevel: json['min_stock_level'] ?? 0,
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
      status: json['status'] ?? 'active',
      imageUrl: json['image'],
    );
  }

  bool get isLowStock => quantity <= minStockLevel;
  
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }
  
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 7;
  }
}

/// Category model
class Category {
  final int id;
  final String name;
  final String? description;
  final int? parentId;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      parentId: json['parent'],
    );
  }
}

/// Product list state
class ProductListState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final int currentPage;
  final int totalCount;
  final ProductFilter filter;

  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.currentPage = 1,
    this.totalCount = 0,
    this.filter = const ProductFilter(),
  });

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    int? currentPage,
    int? totalCount,
    ProductFilter? filter,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      filter: filter ?? this.filter,
    );
  }
}

/// Product filter
class ProductFilter {
  final String? search;
  final int? categoryId;
  final int? storeId;
  final String? status;
  final bool? lowStock;
  final bool? expiring;
  final String ordering;

  const ProductFilter({
    this.search,
    this.categoryId,
    this.storeId,
    this.status,
    this.lowStock,
    this.expiring,
    this.ordering = '-created_at',
  });

  ProductFilter copyWith({
    String? search,
    int? categoryId,
    int? storeId,
    String? status,
    bool? lowStock,
    bool? expiring,
    String? ordering,
  }) {
    return ProductFilter(
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      storeId: storeId ?? this.storeId,
      status: status ?? this.status,
      lowStock: lowStock ?? this.lowStock,
      expiring: expiring ?? this.expiring,
      ordering: ordering ?? this.ordering,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['category'] = categoryId;
    if (storeId != null) params['store'] = storeId;
    if (status != null) params['status'] = status;
    if (lowStock == true) params['low_stock'] = true;
    if (expiring == true) params['expiring'] = true;
    params['ordering'] = ordering;
    return params;
  }
}

/// Product list notifier
class ProductListNotifier extends StateNotifier<ProductListState> {
  ProductListNotifier() : super(const ProductListState());

  Future<void> loadProducts({bool refresh = false}) async {
    if (state.isLoading) return;
    
    if (refresh) {
      state = state.copyWith(
        products: [],
        currentPage: 1,
        hasMore: true,
        isLoading: true,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      // Implement actual API call
      // final response = await ApiClient.instance.get(
      //   '/products/products/',
      //   queryParameters: {
      //     ...state.filter.toQueryParams(),
      //     'page': state.currentPage,
      //   },
      // );
      
      // Placeholder with demo data
      await Future.delayed(const Duration(milliseconds: 500));
      
      final demoProducts = List.generate(
        20,
        (i) => Product(
          id: i + 1,
          name: 'Product ${i + 1}',
          sku: 'SKU-${(i + 1).toString().padLeft(4, '0')}',
          price: 9.99 + i,
          quantity: 50 + i * 5,
          minStockLevel: 10,
          expiryDate: DateTime.now().add(Duration(days: i * 7)),
        ),
      );

      state = state.copyWith(
        products: refresh ? demoProducts : [...state.products, ...demoProducts],
        isLoading: false,
        hasMore: demoProducts.length >= 20,
        currentPage: state.currentPage + 1,
        totalCount: 100,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load products: ${e.toString()}',
      );
    }
  }

  Future<void> refreshProducts() => loadProducts(refresh: true);

  void setFilter(ProductFilter filter) {
    state = state.copyWith(filter: filter);
    loadProducts(refresh: true);
  }

  void clearFilter() {
    state = state.copyWith(filter: const ProductFilter());
    loadProducts(refresh: true);
  }
}

/// Product list provider
final productListProvider = StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  return ProductListNotifier();
});

/// Selected product provider
final selectedProductProvider = StateProvider<Product?>((ref) => null);

/// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  // Implement actual API call
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    const Category(id: 1, name: 'Dairy'),
    const Category(id: 2, name: 'Bakery'),
    const Category(id: 3, name: 'Beverages'),
    const Category(id: 4, name: 'Snacks'),
    const Category(id: 5, name: 'Fresh Produce'),
  ];
});


// ============================================================================
// ANALYTICS PROVIDERS
// ============================================================================

/// Dashboard metrics
class DashboardMetrics {
  final int totalProducts;
  final int activeProducts;
  final double totalValue;
  final int expiringSoon;
  final int lowStock;
  final int outOfStock;
  final double todaySales;
  final double weekSales;
  final double monthSales;
  final double wasteRate;
  final double freshnessScore;

  const DashboardMetrics({
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.totalValue = 0,
    this.expiringSoon = 0,
    this.lowStock = 0,
    this.outOfStock = 0,
    this.todaySales = 0,
    this.weekSales = 0,
    this.monthSales = 0,
    this.wasteRate = 0,
    this.freshnessScore = 0,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalProducts: json['total_products'] ?? 0,
      activeProducts: json['active_products'] ?? 0,
      totalValue: double.tryParse(json['total_value']?.toString() ?? '0') ?? 0,
      expiringSoon: json['expiring_soon'] ?? 0,
      lowStock: json['low_stock'] ?? 0,
      outOfStock: json['out_of_stock'] ?? 0,
      todaySales: double.tryParse(json['today_sales']?.toString() ?? '0') ?? 0,
      weekSales: double.tryParse(json['week_sales']?.toString() ?? '0') ?? 0,
      monthSales: double.tryParse(json['month_sales']?.toString() ?? '0') ?? 0,
      wasteRate: double.tryParse(json['waste_rate']?.toString() ?? '0') ?? 0,
      freshnessScore: double.tryParse(json['freshness_score']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Dashboard provider
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  // Implement actual API call
  await Future.delayed(const Duration(milliseconds: 500));
  
  return const DashboardMetrics(
    totalProducts: 1250,
    activeProducts: 1180,
    totalValue: 125000,
    expiringSoon: 23,
    lowStock: 15,
    outOfStock: 5,
    todaySales: 4580.50,
    weekSales: 28500,
    monthSales: 125000,
    wasteRate: 2.3,
    freshnessScore: 87,
  );
});

/// AI recommendations
class AIRecommendation {
  final String type;
  final String priority;
  final String title;
  final String description;
  final String action;
  final int? productId;
  final String? potentialImpact;

  const AIRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.action,
    this.productId,
    this.potentialImpact,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      type: json['type'] ?? '',
      priority: json['priority'] ?? 'medium',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      action: json['action'] ?? '',
      productId: json['product_id'],
      potentialImpact: json['potential_impact'],
    );
  }
}

/// AI recommendations provider
final aiRecommendationsProvider = FutureProvider<List<AIRecommendation>>((ref) async {
  // Implement actual API call
  await Future.delayed(const Duration(milliseconds: 500));
  
  return const [
    AIRecommendation(
      type: 'reorder',
      priority: 'high',
      title: 'Restock Organic Milk',
      description: 'Stock level below reorder point',
      action: 'Order 100 units',
      productId: 1,
      potentialImpact: 'Prevent stockout',
    ),
    AIRecommendation(
      type: 'markdown',
      priority: 'medium',
      title: 'Mark down expiring yogurt',
      description: '15 units expiring in 3 days',
      action: 'Apply 25% discount',
      productId: 5,
      potentialImpact: 'Recover \$45 from potential waste',
    ),
    AIRecommendation(
      type: 'transfer',
      priority: 'low',
      title: 'Transfer excess bread',
      description: 'Store A has 50 extra units',
      action: 'Transfer 30 to Store B',
      productId: 12,
      potentialImpact: 'Balance inventory',
    ),
  ];
});


// ============================================================================
// APP SETTINGS PROVIDERS
// ============================================================================

/// App settings
class AppSettings {
  final bool darkMode;
  final String language;
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final int? defaultStoreId;

  const AppSettings({
    this.darkMode = false,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    this.defaultStoreId,
  });

  AppSettings copyWith({
    bool? darkMode,
    String? language,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    int? defaultStoreId,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      defaultStoreId: defaultStoreId ?? this.defaultStoreId,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  void toggleDarkMode() {
    state = state.copyWith(darkMode: !state.darkMode);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  void toggleBiometric() {
    state = state.copyWith(biometricEnabled: !state.biometricEnabled);
  }

  void setDefaultStore(int? storeId) {
    state = state.copyWith(defaultStoreId: storeId);
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// Theme mode provider (derived from settings)
final themeModeProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).darkMode;
});


// ============================================================================
// CONNECTIVITY PROVIDER
// ============================================================================

/// Connectivity state
enum ConnectivityStatus { online, offline, checking }

/// Connectivity provider
final connectivityProvider = StateProvider<ConnectivityStatus>((ref) {
  return ConnectivityStatus.online;
});
