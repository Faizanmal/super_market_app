/// Sales Forecasting Service
/// Handles API communication for AI-powered sales predictions
library;

import '../config/constants.dart';
import '../services/secure_api_service.dart';

class SalesForecastingService {
  final SecureApiService _apiService = SecureApiService();
  final String _baseUrl = '${AppConstants.apiBaseUrl}/features';

  /// Get forecasting dashboard overview
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _apiService.get('$_baseUrl/forecasting/dashboard/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get sales history for a product
  Future<List<Map<String, dynamic>>> getSalesHistory({
    int? productId,
    int days = 30,
  }) async {
    try {
      String url = '$_baseUrl/sales-history/';
      if (productId != null) {
        url = '$_baseUrl/sales-history/by_product/?product_id=$productId&days=$days';
      }
      final response = await _apiService.get(url);
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Bulk import sales history
  Future<Map<String, dynamic>> bulkImportSalesHistory(List<Map<String, dynamic>> sales) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/sales-history/bulk_import/',
        body: {'sales': sales},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get upcoming forecasts
  Future<List<Map<String, dynamic>>> getUpcomingForecasts({int days = 7}) async {
    try {
      final response = await _apiService.get('$_baseUrl/forecasts/upcoming/?days=$days');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Generate forecasts for products
  Future<Map<String, dynamic>> generateForecasts({
    List<int>? productIds,
    int days = 7,
  }) async {
    try {
      final response = await _apiService.post(
        '$_baseUrl/forecasts/generate/',
        body: {
          'product_ids': productIds ?? [],
          'days': days,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get product forecast detail
  Future<Map<String, dynamic>> getProductForecastDetail(int productId) async {
    try {
      final response = await _apiService.get('$_baseUrl/forecasting/product/$productId/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get pending restock recommendations
  Future<List<Map<String, dynamic>>> getPendingRestockRecommendations() async {
    try {
      final response = await _apiService.get('$_baseUrl/restock-recommendations/pending/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get restock recommendations by urgency
  Future<Map<String, dynamic>> getRestockByUrgency() async {
    try {
      final response = await _apiService.get('$_baseUrl/restock-recommendations/by_urgency/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Approve a restock recommendation
  Future<void> approveRestock(int id) async {
    try {
      await _apiService.post('$_baseUrl/restock-recommendations/$id/approve/');
    } catch (e) {
      rethrow;
    }
  }

  /// Dismiss a restock recommendation
  Future<void> dismissRestock(int id) async {
    try {
      await _apiService.post('$_baseUrl/restock-recommendations/$id/dismiss/');
    } catch (e) {
      rethrow;
    }
  }

  /// Generate new restock recommendations
  Future<Map<String, dynamic>> generateRestockRecommendations() async {
    try {
      final response = await _apiService.post('$_baseUrl/restock-recommendations/generate/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
