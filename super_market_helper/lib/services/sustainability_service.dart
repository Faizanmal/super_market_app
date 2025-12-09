import '../models/sustainability_models.dart';
import '../core/api_client.dart';

/// Service for Sustainability and Environmental Impact API operations
class SustainabilityService {
  final ApiClient _apiClient;

  SustainabilityService(this._apiClient);

  /// Get sustainability metrics
  Future<SustainabilityMetrics> getMetrics({
    required int storeId,
    String periodType = 'monthly',
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/sustainability/metrics/',
        queryParameters: {
          'store_id': storeId.toString(),
          'period_type': periodType,
        },
      );

      return SustainabilityMetrics.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get sustainability metrics: $e');
    }
  }

  /// Get waste records
  Future<List<WasteRecord>> getWasteRecords({
    int? storeId,
    String? wasteType,
    String? disposalMethod,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/sustainability/waste_records/',
        queryParameters: {
          if (storeId != null) 'store_id': storeId.toString(),
          if (wasteType != null) 'waste_type': wasteType,
          if (disposalMethod != null) 'disposal_method': disposalMethod,
          if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      final records = (response.data['records'] as List)
          .map((json) => WasteRecord.fromJson(json))
          .toList();

      return records;
    } catch (e) {
      throw Exception('Failed to get waste records: $e');
    }
  }

  /// Create waste record
  Future<int> createWasteRecord({
    required int storeId,
    int? productId,
    int? batchId,
    required String wasteType,
    required double quantity,
    int? unitCount,
    required double monetaryValue,
    required String disposalMethod,
    double disposalCost = 0,
    required String reason,
    String reasonDetails = '',
    bool preventable = true,
    List<String> photos = const [],
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/sustainability/waste_records/',
        data: {
          'store_id': storeId,
          if (productId != null) 'product_id': productId,
          if (batchId != null) 'batch_id': batchId,
          'waste_type': wasteType,
          'quantity': quantity,
          if (unitCount != null) 'unit_count': unitCount,
          'monetary_value': monetaryValue,
          'disposal_method': disposalMethod,
          'disposal_cost': disposalCost,
          'reason': reason,
          'reason_details': reasonDetails,
          'preventable': preventable,
          'photos': photos,
        },
      );

      return response.data['waste_record_id'];
    } catch (e) {
      throw Exception('Failed to create waste record: $e');
    }
  }

  /// Get sustainability initiatives
  Future<List<SustainabilityInitiative>> getInitiatives({
    int? storeId,
    String? status,
    String? category,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/sustainability/initiatives/',
        queryParameters: {
          if (storeId != null) 'store_id': storeId.toString(),
          if (status != null) 'status': status,
          if (category != null) 'category': category,
        },
      );

      final initiatives = (response.data['initiatives'] as List)
          .map((json) => SustainabilityInitiative.fromJson(json))
          .toList();

      return initiatives;
    } catch (e) {
      throw Exception('Failed to get sustainability initiatives: $e');
    }
  }

  /// Create sustainability initiative
  Future<int> createInitiative({
    required int storeId,
    required String name,
    required String description,
    required String category,
    required DateTime startDate,
    DateTime? targetCompletionDate,
    double? targetWasteReduction,
    double? targetCarbonReduction,
    double? targetCostSavings,
    double budget = 0,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/sustainability/initiatives/',
        data: {
          'store_id': storeId,
          'name': name,
          'description': description,
          'category': category,
          'start_date': startDate.toIso8601String().split('T')[0],
          if (targetCompletionDate != null)
            'target_completion_date': targetCompletionDate.toIso8601String().split('T')[0],
          if (targetWasteReduction != null) 'target_waste_reduction_kg': targetWasteReduction,
          if (targetCarbonReduction != null) 'target_carbon_reduction_kg': targetCarbonReduction,
          if (targetCostSavings != null) 'target_cost_savings': targetCostSavings,
          'budget': budget,
        },
      );

      return response.data['initiative_id'];
    } catch (e) {
      throw Exception('Failed to create sustainability initiative: $e');
    }
  }

  /// Update initiative progress
  Future<bool> updateInitiativeProgress({
    required int initiativeId,
    required double progressPercentage,
    double? actualWasteReduction,
    double? actualCarbonReduction,
    double? actualCostSavings,
    double? actualCost,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/api/sustainability/initiatives/$initiativeId/',
        data: {
          'progress_percentage': progressPercentage,
          if (actualWasteReduction != null) 'actual_waste_reduction_kg': actualWasteReduction,
          if (actualCarbonReduction != null) 'actual_carbon_reduction_kg': actualCarbonReduction,
          if (actualCostSavings != null) 'actual_cost_savings': actualCostSavings,
          if (actualCost != null) 'actual_cost': actualCost,
        },
      );

      return response.data['success'] ?? false;
    } catch (e) {
      throw Exception('Failed to update initiative progress: $e');
    }
  }

  /// Get green supplier ratings
  Future<List<GreenSupplierRating>> getGreenSupplierRatings() async {
    try {
      final response = await _apiClient.get('/api/sustainability/green_suppliers/');

      final ratings = (response.data['ratings'] as List)
          .map((json) => GreenSupplierRating.fromJson(json))
          .toList();

      return ratings;
    } catch (e) {
      throw Exception('Failed to get green supplier ratings: $e');
    }
  }

  /// Get sustainability dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary(int storeId) async {
    try {
      final response = await _apiClient.get(
        '/api/sustainability/dashboard_summary/',
        queryParameters: {'store_id': storeId.toString()},
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to get dashboard summary: $e');
    }
  }

  /// Calculate product carbon footprint
  Future<double> calculateProductCarbonFootprint({
    required int productId,
    required double transportationDistanceKm,
    String transportationMethod = 'road',
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/sustainability/calculate_carbon_footprint/',
        data: {
          'product_id': productId,
          'transportation_distance_km': transportationDistanceKm,
          'transportation_method': transportationMethod,
        },
      );

      return double.parse(response.data['carbon_footprint'].toString());
    } catch (e) {
      throw Exception('Failed to calculate carbon footprint: $e');
    }
  }

  /// Get waste analytics
  Future<Map<String, dynamic>> getWasteAnalytics({
    required int storeId,
    int days = 30,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/sustainability/waste_analytics/',
        queryParameters: {
          'store_id': storeId.toString(),
          'days': days.toString(),
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to get waste analytics: $e');
    }
  }
}
