import 'package:flutter/foundation.dart';
import '../models/enterprise_models.dart';
import '../services/secure_api_service.dart';

/// Provider for managing inventory adjustments and store transfers
class InventoryProvider with ChangeNotifier {
  final SecureApiService _apiService = SecureApiService();
  
  // Inventory Adjustments
  List<InventoryAdjustmentModel> _adjustments = [];
  bool _isLoadingAdjustments = false;
  String? _adjustmentError;
  
  // Store Transfers
  List<StoreTransferModel> _transfers = [];
  bool _isLoadingTransfers = false;
  String? _transferError;
  
  // Price History
  List<PriceHistoryModel> _priceHistory = [];
  bool _isLoadingPriceHistory = false;
  
  // Getters - Adjustments
  List<InventoryAdjustmentModel> get adjustments => _adjustments;
  List<InventoryAdjustmentModel> get pendingAdjustments => 
      _adjustments.where((a) => a.status == 'pending').toList();
  bool get isLoadingAdjustments => _isLoadingAdjustments;
  String? get adjustmentError => _adjustmentError;
  
  // Getters - Transfers
  List<StoreTransferModel> get transfers => _transfers;
  List<StoreTransferModel> get pendingTransfers => 
      _transfers.where((t) => t.status == 'pending').toList();
  List<StoreTransferModel> get inTransitTransfers => 
      _transfers.where((t) => t.status == 'in_transit').toList();
  bool get isLoadingTransfers => _isLoadingTransfers;
  String? get transferError => _transferError;
  
  // Getters - Price History
  List<PriceHistoryModel> get priceHistory => _priceHistory;
  bool get isLoadingPriceHistory => _isLoadingPriceHistory;
  
  // === INVENTORY ADJUSTMENTS ===
  
  /// Fetch all inventory adjustments
  Future<void> fetchAdjustments({String? status}) async {
    _isLoadingAdjustments = true;
    _adjustmentError = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getInventoryAdjustments(status: status);
      
      if (response['success']) {
        final data = response['data'];
        final results = data['results'] ?? data;
        if (results is List) {
          _adjustments = results
              .map((json) => InventoryAdjustmentModel.fromJson(json))
              .toList();
        } else {
          _adjustments = [];
        }
        _adjustmentError = null;
      } else {
        _adjustmentError = response['error'];
      }
    } catch (e) {
      _adjustmentError = e.toString();
      debugPrint('Error fetching adjustments: $e');
    } finally {
      _isLoadingAdjustments = false;
      notifyListeners();
    }
  }
  
  /// Create new inventory adjustment
  Future<bool> createAdjustment(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createInventoryAdjustment(data);
      
      if (response['success']) {
        final newAdjustment = InventoryAdjustmentModel.fromJson(response['data']);
        _adjustments.insert(0, newAdjustment);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating adjustment: $e');
      return false;
    }
  }
  
  /// Approve an adjustment
  Future<bool> approveAdjustment(int adjustmentId) async {
    try {
      final response = await _apiService.approveInventoryAdjustment(adjustmentId);
      
      if (response['success']) {
        final index = _adjustments.indexWhere((a) => a.id == adjustmentId);
        if (index != -1) {
          _adjustments[index] = InventoryAdjustmentModel.fromJson(response['data']);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error approving adjustment: $e');
      return false;
    }
  }
  
  /// Reject an adjustment
  Future<bool> rejectAdjustment(int adjustmentId, String reason) async {
    try {
      final response = await _apiService.rejectInventoryAdjustment(adjustmentId, reason);
      
      if (response['success']) {
        final index = _adjustments.indexWhere((a) => a.id == adjustmentId);
        if (index != -1) {
          _adjustments[index] = InventoryAdjustmentModel.fromJson(response['data']);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error rejecting adjustment: $e');
      return false;
    }
  }
  
  /// Get adjustment statistics
  Future<Map<String, dynamic>?> getAdjustmentStats() async {
    try {
      final response = await _apiService.getInventoryAdjustmentStats();
      
      if (response['success']) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching adjustment stats: $e');
      return null;
    }
  }
  
  // === STORE TRANSFERS ===
  
  /// Fetch all store transfers
  Future<void> fetchTransfers({String? status}) async {
    _isLoadingTransfers = true;
    _transferError = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getStoreTransfers(status: status);
      
      if (response['success']) {
        final data = response['data'];
        final results = data['results'] ?? data;
        if (results is List) {
          _transfers = results
              .map((json) => StoreTransferModel.fromJson(json))
              .toList();
        } else {
          _transfers = [];
        }
        _transferError = null;
      } else {
        _transferError = response['error'];
      }
    } catch (e) {
      _transferError = e.toString();
      debugPrint('Error fetching transfers: $e');
    } finally {
      _isLoadingTransfers = false;
      notifyListeners();
    }
  }
  
  /// Create new store transfer
  Future<bool> createTransfer(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createStoreTransfer(data);
      
      if (response['success']) {
        final newTransfer = StoreTransferModel.fromJson(response['data']);
        _transfers.insert(0, newTransfer);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating transfer: $e');
      return false;
    }
  }
  
  /// Ship a transfer
  Future<bool> shipTransfer(int transferId) async {
    try {
      final response = await _apiService.shipTransfer(transferId);
      
      if (response['success']) {
        final index = _transfers.indexWhere((t) => t.id == transferId);
        if (index != -1) {
          _transfers[index] = StoreTransferModel.fromJson(response['data']);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error shipping transfer: $e');
      return false;
    }
  }
  
  /// Receive a transfer
  Future<bool> receiveTransfer(int transferId) async {
    try {
      final response = await _apiService.receiveTransfer(transferId);
      
      if (response['success']) {
        final index = _transfers.indexWhere((t) => t.id == transferId);
        if (index != -1) {
          _transfers[index] = StoreTransferModel.fromJson(response['data']);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error receiving transfer: $e');
      return false;
    }
  }
  
  /// Cancel a transfer
  Future<bool> cancelTransfer(int transferId) async {
    try {
      final response = await _apiService.cancelTransfer(transferId);
      
      if (response['success']) {
        final index = _transfers.indexWhere((t) => t.id == transferId);
        if (index != -1) {
          _transfers[index] = StoreTransferModel.fromJson(response['data']);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error cancelling transfer: $e');
      return false;
    }
  }
  
  /// Get transfer statistics
  Future<Map<String, dynamic>?> getTransferStats() async {
    try {
      final response = await _apiService.getStoreTransferStats();
      
      if (response['success']) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching transfer stats: $e');
      return null;
    }
  }
  
  // === PRICE HISTORY ===
  
  /// Fetch price history with optional date range
  Future<void> fetchPriceHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoadingPriceHistory = true;
    notifyListeners();
    
    try {
      final response = await _apiService.getPriceHistory(
        startDate: startDate,
        endDate: endDate,
      );
      
      if (response['success']) {
        final data = response['data'];
        final results = data['results'] ?? data;
        if (results is List) {
          _priceHistory = results
              .map((json) => PriceHistoryModel.fromJson(json))
              .toList();
        } else {
          _priceHistory = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching price history: $e');
    } finally {
      _isLoadingPriceHistory = false;
      notifyListeners();
    }
  }
  
  /// Fetch price history for a specific product
  Future<List<PriceHistoryModel>> getProductPriceHistory(int productId) async {
    try {
      final response = await _apiService.getProductPriceHistory(productId);
      
      if (response['success']) {
        return (response['data'] as List)
            .map((json) => PriceHistoryModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching product price history: $e');
      return [];
    }
  }
  
  /// Get recent price changes summary
  Future<Map<String, dynamic>?> getRecentPriceChanges({int days = 7}) async {
    try {
      final response = await _apiService.getRecentPriceChanges(days: days);
      
      if (response['success']) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching recent price changes: $e');
      return null;
    }
  }
  
  /// Refresh all inventory data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchAdjustments(),
      fetchTransfers(),
      fetchPriceHistory(),
    ]);
  }
}
