/// Customer Features Service
/// Handles API communication for shopping lists, receipts, and warranties
library;

import '../config/constants.dart';
import '../services/secure_api_service.dart';

class CustomerFeaturesService {
  final SecureApiService _apiService = SecureApiService();
  final String _baseUrl = '${AppConstants.apiBaseUrl}/features';

  // ============================================================================
  // Customer Dashboard
  // ============================================================================

  /// Get customer dashboard overview
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _apiService.get('$_baseUrl/customer/dashboard/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // Shopping Lists
  // ============================================================================

  /// Get all shopping lists
  Future<List<Map<String, dynamic>>> getShoppingLists() async {
    try {
      final response = await _apiService.get('$_baseUrl/shopping-lists/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single shopping list
  Future<Map<String, dynamic>> getShoppingList(String id) async {
    try {
      final response = await _apiService.get('$_baseUrl/shopping-lists/$id/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new shopping list
  Future<Map<String, dynamic>> createShoppingList(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('$_baseUrl/shopping-lists/', body: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Update a shopping list
  Future<Map<String, dynamic>> updateShoppingList(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('$_baseUrl/shopping-lists/$id/', body: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a shopping list
  Future<void> deleteShoppingList(String id) async {
    try {
      await _apiService.delete('$_baseUrl/shopping-lists/$id/');
    } catch (e) {
      rethrow;
    }
  }

  /// Share a shopping list
  Future<Map<String, dynamic>> shareShoppingList(String id) async {
    try {
      final response = await _apiService.post('$_baseUrl/shopping-lists/$id/share/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Join a shared shopping list
  Future<Map<String, dynamic>> joinShoppingList(String shareCode) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/shopping-lists/join/',
        body: {'share_code': shareCode},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Add item to shopping list
  Future<Map<String, dynamic>> addItemToList(String listId, Map<String, dynamic> item) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/shopping-lists/$listId/add_item/',
        body: item,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Complete a shopping list
  Future<Map<String, dynamic>> completeShoppingList(String id) async {
    try {
      final response = await _apiService.post('$_baseUrl/shopping-lists/$id/complete/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get optimized shopping route
  Future<Map<String, dynamic>> getOptimizedRoute(String id) async {
    try {
      final response = await _apiService.get('$_baseUrl/shopping-lists/$id/optimized_route/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Check off an item
  Future<Map<String, dynamic>> checkOffItem(int itemId, {double? actualPrice}) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/shopping-list-items/$itemId/check_off/',
        body: actualPrice != null ? {'actual_price': actualPrice} : null,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Uncheck an item
  Future<Map<String, dynamic>> uncheckItem(int itemId) async {
    try {
      final response = await _apiService.post('$_baseUrl/shopping-list-items/$itemId/uncheck/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // Digital Receipts
  // ============================================================================

  /// Get all receipts
  Future<List<Map<String, dynamic>>> getReceipts() async {
    try {
      final response = await _apiService.get('$_baseUrl/receipts/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get recent receipts
  Future<List<Map<String, dynamic>>> getRecentReceipts({int days = 30}) async {
    try {
      final response = await _apiService.get('$_baseUrl/receipts/recent/?days=$days');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single receipt
  Future<Map<String, dynamic>> getReceipt(String id) async {
    try {
      final response = await _apiService.get('$_baseUrl/receipts/$id/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get spending summary
  Future<Map<String, dynamic>> getSpendingSummary({int days = 30}) async {
    try {
      final response = await _apiService.get('$_baseUrl/receipts/summary/?days=$days');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Create receipt from purchase
  Future<Map<String, dynamic>> createReceipt(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('$_baseUrl/customer/create-receipt/', body: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // Warranties
  // ============================================================================

  /// Get all warranties
  Future<List<Map<String, dynamic>>> getWarranties() async {
    try {
      final response = await _apiService.get('$_baseUrl/warranties/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get warranty dashboard
  Future<Map<String, dynamic>> getWarrantyDashboard() async {
    try {
      final response = await _apiService.get('$_baseUrl/warranties/dashboard/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get warranties expiring soon
  Future<List<Map<String, dynamic>>> getExpiringWarranties({int days = 30}) async {
    try {
      final response = await _apiService.get('$_baseUrl/warranties/expiring_soon/?days=$days');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single warranty
  Future<Map<String, dynamic>> getWarranty(String id) async {
    try {
      final response = await _apiService.get('$_baseUrl/warranties/$id/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Set warranty reminder
  Future<Map<String, dynamic>> setWarrantyReminder(String id, int daysBefore) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/warranties/$id/set_reminder/',
        body: {'days_before': daysBefore},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// File a warranty claim
  Future<Map<String, dynamic>> fileWarrantyClaim(
    String warrantyId,
    String issueDescription, {
    List<String>? images,
  }) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/warranties/$warrantyId/file_claim/',
        body: {
          'issue_description': issueDescription,
          'images': images ?? [],
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get warranty claims
  Future<List<Map<String, dynamic>>> getWarrantyClaims() async {
    try {
      final response = await _apiService.get('$_baseUrl/warranty-claims/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
