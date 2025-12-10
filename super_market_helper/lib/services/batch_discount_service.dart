/// Batch Discount Service
/// Handles API communication for discount engine features
library;

import '../config/constants.dart';
import '../services/secure_api_service.dart';

class BatchDiscountService {
  final SecureApiService _apiService = SecureApiService();
  final String _baseUrl = '${AppConstants.apiBaseUrl}/features';

  /// Get discount dashboard overview
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _apiService.get('$_baseUrl/discounts/dashboard/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all discount rules
  Future<List<Map<String, dynamic>>> getDiscountRules() async {
    try {
      final response = await _apiService.get('$_baseUrl/discount-rules/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new discount rule
  Future<Map<String, dynamic>> createDiscountRule(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('$_baseUrl/discount-rules/', body: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Update a discount rule
  Future<Map<String, dynamic>> updateDiscountRule(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('$_baseUrl/discount-rules/$id/', body: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a discount rule
  Future<void> deleteDiscountRule(int id) async {
    try {
      await _apiService.delete('$_baseUrl/discount-rules/$id/');
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle rule status (active/paused)
  Future<Map<String, dynamic>> toggleRuleStatus(int id) async {
    try {
      final response = await _apiService.post('$_baseUrl/discount-rules/$id/toggle_status/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Apply a rule manually
  Future<Map<String, dynamic>> applyRuleNow(int id) async {
    try {
      final response = await _apiService.post('$_baseUrl/discount-rules/$id/apply_now/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get active batch discounts
  Future<List<Map<String, dynamic>>> getActiveDiscounts() async {
    try {
      final response = await _apiService.get('$_baseUrl/batch-discounts/active/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get discounts expiring today
  Future<List<Map<String, dynamic>>> getExpiringTodayDiscounts() async {
    try {
      final response = await _apiService.get('$_baseUrl/batch-discounts/expiring_today/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a discount
  Future<void> cancelDiscount(int id) async {
    try {
      await _apiService.post('$_baseUrl/batch-discounts/$id/cancel/');
    } catch (e) {
      rethrow;
    }
  }

  /// Auto-apply all active discount rules
  Future<Map<String, dynamic>> autoApplyDiscounts() async {
    try {
      final response = await _apiService.post('$_baseUrl/discounts/auto-apply/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get discount analytics
  Future<Map<String, dynamic>> getAnalytics({int days = 30}) async {
    try {
      final response = await _apiService.get('$_baseUrl/discounts/analytics/?days=$days');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
