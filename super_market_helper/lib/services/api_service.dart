import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/shopping_list_model.dart';
import '../models/analytics_model.dart';
import '../models/store_models.dart' as store_models;

/// Comprehensive API Service for backend communication with JWT authentication,
/// offline sync, error handling, and all the implemented backend endpoints
class ApiService {
  // TODO: Replace with your actual backend URL
  static const String baseUrl = 'http://localhost:8000/api';
  
  String? _authToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Initialize API service and load stored tokens
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
    final expiryString = prefs.getString('token_expiry');
    if (expiryString != null) {
      _tokenExpiry = DateTime.parse(expiryString);
    }
  }

  /// Check if user is authenticated and token is valid
  bool get isAuthenticated => _authToken != null && _isTokenValid();

  bool _isTokenValid() {
    if (_tokenExpiry == null) return true; // Assume valid if no expiry set
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Set authentication tokens
  Future<void> setAuthTokens(String accessToken, String refreshToken) async {
    _authToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = DateTime.now().add(const Duration(hours: 1)); // JWT default expiry
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('token_expiry', _tokenExpiry!.toIso8601String());
  }

  /// Clear authentication tokens
  Future<void> clearAuthTokens() async {
    _authToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiry');
  }

  /// Get request headers with authentication
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Refresh JWT access token
  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await setAuthTokens(data['access'], _refreshToken!);
        return true;
      }
    } catch (e) {
      // Token refresh failed
    }
    
    return false;
  }

  /// Make authenticated HTTP request with automatic token refresh
  Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function() request,
  ) async {
    // Check if token needs refresh
    if (!_isTokenValid() && _refreshToken != null) {
      await refreshAuthToken();
    }

    final response = await request();
    
    // If unauthorized, try refreshing token once
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await refreshAuthToken();
      if (refreshed) {
        return await request();
      }
    }
    
    return response;
  }

  // ============ Authentication ============

  /// Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setAuthTokens(data['access'], data['refresh']);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['access'] != null && data['refresh'] != null) {
        await setAuthTokens(data['access'], data['refresh']);
      }
      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  /// Logout user
  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout/'),
          headers: _headers,
          body: jsonEncode({'refresh': _refreshToken}),
        );
      } catch (e) {
        // Logout request failed
      }
    }
    await clearAuthTokens();
  }

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse('$baseUrl/auth/profile/'), headers: _headers)
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.patch(
        Uri.parse('$baseUrl/auth/profile/'),
        headers: _headers,
        body: jsonEncode(userData),
      )
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // ============ Products ============

  /// Get all products
  Future<List<Product>> getProducts({Map<String, String>? filters}) async {
    String url = '$baseUrl/products/products/';
    if (filters != null && filters.isNotEmpty) {
      final queryParams = filters.entries.map((e) => '${e.key}=${e.value}').join('&');
      url += '?$queryParams';
    }

    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse(url), headers: _headers)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  /// Get single product
  Future<Product> getProduct(String productId) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse('$baseUrl/products/products/$productId/'), headers: _headers)
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load product');
    }
  }

  /// Create new product
  Future<Product> createProduct(Product product) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.post(
        Uri.parse('$baseUrl/products/products/'),
        headers: _headers,
        body: jsonEncode(product.toJson()),
      )
    );

    if (response.statusCode == 201) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create product: ${response.body}');
    }
  }

  /// Update existing product
  Future<Product> updateProduct(Product product) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.put(
        Uri.parse('$baseUrl/products/products/${product.id}/'),
        headers: _headers,
        body: jsonEncode(product.toJson()),
      )
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.delete(Uri.parse('$baseUrl/products/products/$productId/'), headers: _headers)
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete product');
    }
  }

  /// Search products by barcode
  Future<Product?> searchByBarcode(String barcode) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(
        Uri.parse('$baseUrl/products/products/search_barcode/?barcode=$barcode'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['product'] != null ? Product.fromJson(data['product']) : null;
    } else {
      throw Exception('Failed to search product by barcode');
    }
  }

  // ============ Categories ============

  /// Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse('$baseUrl/products/categories/'), headers: _headers)
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  /// Create new category
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.post(
        Uri.parse('$baseUrl/products/categories/'),
        headers: _headers,
        body: jsonEncode(categoryData),
      )
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create category');
    }
  }

  // ============ Smart Analytics ============

  /// Get demand forecasts
  Future<List<DemandForecast>> getDemandForecasts() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(
        Uri.parse('$baseUrl/products/smart-analytics/demand_forecast/'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> forecasts = data['forecasts'];
      return forecasts.map((json) => DemandForecast.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load demand forecasts');
    }
  }

  /// Get trending products
  Future<List<Product>> getTrendingProducts({int days = 7}) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(
        Uri.parse('$baseUrl/products/smart-analytics/trending_products/?days=$days'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> products = data['trending_products'];
      return products.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load trending products');
    }
  }

  /// Get stock health scores
  Future<List<StockHealthScore>> getStockHealthScores() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(
        Uri.parse('$baseUrl/products/smart-analytics/stock_health/'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> scores = data['health_scores'];
      return scores.map((json) => StockHealthScore.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stock health scores');
    }
  }

  /// Get profit analysis
  Future<ProfitAnalysis> getProfitAnalysis({int days = 30}) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(
        Uri.parse('$baseUrl/products/smart-analytics/profit_analysis/?days=$days'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      return ProfitAnalysis.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profit analysis');
    }
  }

  /// Get smart alerts
  Future<Map<String, List<SmartAlert>>> getSmartAlerts() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(
        Uri.parse('$baseUrl/products/smart-analytics/smart_alerts/'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'critical': (data['critical'] as List? ?? [])
            .map((json) => SmartAlert.fromJson(json))
            .toList(),
        'high': (data['high'] as List? ?? [])
            .map((json) => SmartAlert.fromJson(json))
            .toList(),
        'medium': (data['medium'] as List? ?? [])
            .map((json) => SmartAlert.fromJson(json))
            .toList(),
        'recommendations': (data['recommendations'] as List? ?? [])
            .map((json) => SmartAlert.fromJson(json))
            .toList(),
      };
    } else {
      throw Exception('Failed to load smart alerts');
    }
  }

  // ============ Expiry & Shelf Management ============

  /// Get product batches
  Future<List<Map<String, dynamic>>> getProductBatches({Map<String, String>? filters}) async {
    String url = '$baseUrl/products/batches/';
    if (filters != null && filters.isNotEmpty) {
      final queryParams = filters.entries.map((e) => '${e.key}=${e.value}').join('&');
      url += '?$queryParams';
    }

    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse(url), headers: _headers)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load product batches');
    }
  }

  /// Get expiring batches
  Future<List<Map<String, dynamic>>> getExpiringBatches({int days = 30}) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(
        Uri.parse('$baseUrl/products/batches/expiring_soon/?days=$days'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load expiring batches');
    }
  }

  /// Get shelf locations
  Future<List<Map<String, dynamic>>> getShelfLocations({String? storeId}) async {
    String url = '$baseUrl/products/shelf-locations/';
    if (storeId != null) {
      url += '?store=$storeId';
    }

    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse(url), headers: _headers)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load shelf locations');
    }
  }

  /// Get expiry alerts
  Future<List<Map<String, dynamic>>> getExpiryAlerts({String? severity}) async {
    String url = '$baseUrl/products/expiry-alerts/';
    if (severity != null) {
      url += '?severity=$severity';
    }

    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse(url), headers: _headers)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load expiry alerts');
    }
  }

  /// Acknowledge expiry alert
  Future<Map<String, dynamic>> acknowledgeExpiryAlert(String alertId) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.post(
        Uri.parse('$baseUrl/products/expiry-alerts/$alertId/acknowledge/'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to acknowledge alert');
    }
  }

  /// Get tasks
  Future<List<Map<String, dynamic>>> getTasks({String? status, String? assignedTo}) async {
    String url = '$baseUrl/products/tasks/';
    List<String> params = [];
    if (status != null) params.add('status=$status');
    if (assignedTo != null) params.add('assigned_to=$assignedTo');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse(url), headers: _headers)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  /// Complete task
  Future<Map<String, dynamic>> completeTask(String taskId, {String? notes, File? photo}) async {
    Map<String, dynamic> body = {};
    if (notes != null) body['notes'] = notes;
    
    // TODO: Implement multipart upload for photo
    final response = await _makeAuthenticatedRequest(() => 
      http.post(
        Uri.parse('$baseUrl/products/tasks/$taskId/complete/'),
        headers: _headers,
        body: jsonEncode(body),
      )
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to complete task');
    }
  }

  // ============ Shopping Lists ============

  /// Get shopping lists
  Future<List<ShoppingList>> getShoppingLists() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse('$baseUrl/products/shopping-lists/'), headers: _headers)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.map((json) => ShoppingList.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load shopping lists');
    }
  }

  /// Create shopping list
  Future<ShoppingList> createShoppingList(ShoppingList shoppingList) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.post(
        Uri.parse('$baseUrl/products/shopping-lists/'),
        headers: _headers,
        body: jsonEncode(shoppingList.toJson()),
      )
    );

    if (response.statusCode == 201) {
      return ShoppingList.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create shopping list');
    }
  }

  /// Update shopping list
  Future<ShoppingList> updateShoppingList(ShoppingList shoppingList) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.put(
        Uri.parse('$baseUrl/products/shopping-lists/${shoppingList.id}/'),
        headers: _headers,
        body: jsonEncode(shoppingList.toJson()),
      )
    );

    if (response.statusCode == 200) {
      return ShoppingList.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update shopping list');
    }
  }

  // ============ Analytics Dashboard ============

  /// Get dashboard summary
  Future<DashboardSummary> getDashboardSummary() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(
        Uri.parse('$baseUrl/products/expiry-analytics/dashboard_summary/'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      return DashboardSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load dashboard summary');
    }
  }

  /// Get expiry breakdown
  Future<Map<String, dynamic>> getExpiryBreakdown() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(
        Uri.parse('$baseUrl/products/expiry-analytics/expiry_breakdown/'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load expiry breakdown');
    }
  }

  /// Get wastage analysis
  Future<Map<String, dynamic>> getWastageAnalysis({int days = 30}) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(
        Uri.parse('$baseUrl/products/expiry-analytics/wastage_analysis/?days=$days'),
        headers: _headers,
      )
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load wastage analysis');
    }
  }

  // ============ Utility Methods ============

  /// Test connection to backend
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/stats/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check if backend is reachable
  Future<bool> isBackendReachable() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl.replaceAll('/api', '/health/')),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ Reports ============

  Future<InventoryValuation> getInventoryValuation() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/reports/inventory_valuation/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return InventoryValuation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load inventory valuation');
    }
  }

  Future<String> exportInventoryCSV() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/reports/export_inventory_csv/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['csv_data'];
    } else {
      throw Exception('Failed to export inventory');
    }
  }

  // ============ Favorites ============

  Future<void> toggleFavorite(String productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products/favorites/toggle/'),
      headers: _headers,
      body: jsonEncode({'product_id': productId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to toggle favorite');
    }
  }

  Future<List<String>> getFavoriteProductIds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/favorites/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['results'];
      return data.map((item) => item['product']['id'] as String).toList();
    } else {
      throw Exception('Failed to load favorites');
    }
  }

  Future<void> registerFCMToken(String token) async {    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-fcm-token/'),    
      headers: _headers,
      body: jsonEncode({'fcm_token': token}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {                                                    
      throw Exception('Failed to register FCM token');   
    }
  }

  // ============ Multi-Store Management ============

  /// Get all stores
  Future<List<store_models.Store>> getStores() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse('$baseUrl/stores/stores/'), headers: _headers)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.map((json) => store_models.Store.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stores');
    }
  }

  /// Get store inventories
  Future<List<store_models.StoreInventory>> getStoreInventories({required String storeId}) async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse('$baseUrl/stores/inventories/?store=$storeId'), headers: _headers)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.map((json) => store_models.StoreInventory.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load store inventories');
    }
  }

  /// Get inter-store transfers
  Future<List<store_models.InterStoreTransfer>> getInterStoreTransfers() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse('$baseUrl/stores/transfers/'), headers: _headers)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.map((json) => store_models.InterStoreTransfer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load inter-store transfers');
    }
  }

  /// Get store performance metrics
  Future<List<store_models.StorePerformanceMetrics>> getStorePerformanceMetrics() async {
    final response = await _makeAuthenticatedRequest(() => 
      http.get(Uri.parse('$baseUrl/stores/performance/'), headers: _headers)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? data;
      return results.map((json) => store_models.StorePerformanceMetrics.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load store performance metrics');
    }
  }
}