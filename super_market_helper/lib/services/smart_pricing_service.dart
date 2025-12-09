import '../models/smart_pricing_models.dart';
import '../core/api_client.dart';

/// Service for Smart Pricing API operations
class SmartPricingService {
  final ApiClient _apiClient;

  SmartPricingService(this._apiClient);

  /// Calculate dynamic prices for products
  Future<Map<String, dynamic>> calculateDynamicPrices({
    List<int>? productIds,
    bool autoApprove = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/pricing/calculate_dynamic_prices/',
        data: {
          if (productIds != null) 'product_ids': productIds,
          'auto_approve': autoApprove,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to calculate dynamic prices: $e');
    }
  }

  /// Get pricing recommendations
  Future<List<PricingRecommendation>> getPricingRecommendations() async {
    try {
      final response = await _apiClient.get('/api/pricing/recommendations/');
      
      final recommendations = (response.data['recommendations'] as List)
          .map((json) => PricingRecommendation.fromJson(json))
          .toList();

      return recommendations;
    } catch (e) {
      throw Exception('Failed to get pricing recommendations: $e');
    }
  }

  /// Get dynamic prices
  Future<List<DynamicPrice>> getDynamicPrices({String status = 'pending'}) async {
    try {
      final response = await _apiClient.get(
        '/api/pricing/dynamic_prices/',
        queryParameters: {'status': status},
      );

      final prices = (response.data['results'] as List)
          .map((json) => DynamicPrice.fromJson(json))
          .toList();

      return prices;
    } catch (e) {
      throw Exception('Failed to get dynamic prices: $e');
    }
  }

  /// Approve dynamic price
  Future<bool> approveDynamicPrice({
    required int dynamicPriceId,
    String notes = '',
    bool activate = true,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/pricing/approve_dynamic_price/',
        data: {
          'dynamic_price_id': dynamicPriceId,
          'notes': notes,
          'activate': activate,
        },
      );

      return response.data['success'] ?? false;
    } catch (e) {
      throw Exception('Failed to approve dynamic price: $e');
    }
  }

  /// Add competitor price
  Future<Map<String, dynamic>> addCompetitorPrice({
    required int productId,
    required String competitorName,
    required double price,
    String source = 'manual',
    String sourceUrl = '',
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/pricing/add_competitor_price/',
        data: {
          'product_id': productId,
          'competitor_name': competitorName,
          'price': price,
          'source': source,
          'source_url': sourceUrl,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to add competitor price: $e');
    }
  }

  /// Get competitor analysis
  Future<List<CompetitorPrice>> getCompetitorAnalysis({int? productId}) async {
    try {
      final response = await _apiClient.get(
        '/api/pricing/competitor_analysis/',
        queryParameters: {
          if (productId != null) 'product_id': productId.toString(),
        },
      );

      final analysis = (response.data['analysis'] as List)
          .map((json) => CompetitorPrice.fromJson(json))
          .toList();

      return analysis;
    } catch (e) {
      throw Exception('Failed to get competitor analysis: $e');
    }
  }

  /// Get price history for a product
  Future<List<PriceHistory>> getPriceHistory(int productId) async {
    try {
      final response = await _apiClient.get(
        '/api/pricing/price_history/',
        queryParameters: {'product_id': productId.toString()},
      );

      final history = (response.data['history'] as List)
          .map((json) => PriceHistory.fromJson(json))
          .toList();

      return history;
    } catch (e) {
      throw Exception('Failed to get price history: $e');
    }
  }

  /// Get pricing analytics
  Future<Map<String, dynamic>> getPricingAnalytics() async {
    try {
      final response = await _apiClient.get('/api/pricing/analytics/');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get pricing analytics: $e');
    }
  }
}
