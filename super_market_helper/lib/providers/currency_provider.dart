import 'package:flutter/foundation.dart';
import '../models/currency_model.dart';
import '../services/secure_api_service.dart';

/// Provider for managing multi-currency support
class CurrencyProvider with ChangeNotifier {
  final SecureApiService _apiService = SecureApiService();
  
  List<CurrencyModel> _currencies = [];
  CurrencyModel? _baseCurrency;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<CurrencyModel> get currencies => _currencies;
  List<CurrencyModel> get activeCurrencies => 
      _currencies.where((c) => c.isActive).toList();
  CurrencyModel? get baseCurrency => _baseCurrency;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Fetch all currencies
  Future<void> fetchCurrencies({bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getCurrencies(isActive: isActive);
      
      if (response['success']) {
        final data = response['data'];
        final results = data['results'] ?? data;
        if (results is List) {
          _currencies = results
              .map((json) => CurrencyModel.fromJson(json))
              .toList();
        } else {
          _currencies = [];
        }
        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching currencies: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Fetch base currency
  Future<void> fetchBaseCurrency() async {
    try {
      final response = await _apiService.getBaseCurrency();
      
      if (response['success']) {
        _baseCurrency = CurrencyModel.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching base currency: $e');
    }
  }
  
  /// Convert amount between currencies
  Future<CurrencyConversion?> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      final response = await _apiService.convertCurrency(
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );
      
      if (response['success']) {
        return CurrencyConversion.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error converting currency: $e');
      return null;
    }
  }
  
  /// Update exchange rates (admin only)
  Future<bool> updateExchangeRates() async {
    try {
      final response = await _apiService.updateExchangeRates();
      
      if (response['success']) {
        await fetchCurrencies();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating exchange rates: $e');
      return false;
    }
  }
  
  /// Create new currency (admin only)
  Future<bool> createCurrency(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createCurrency(data);
      
      if (response['success']) {
        final newCurrency = CurrencyModel.fromJson(response['data']);
        _currencies.insert(0, newCurrency);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating currency: $e');
      return false;
    }
  }
  
  /// Update currency (admin only)
  Future<bool> updateCurrency(int currencyId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.updateCurrency(currencyId, data);
      
      if (response['success']) {
        final index = _currencies.indexWhere((c) => c.id == currencyId);
        if (index != -1) {
          _currencies[index] = CurrencyModel.fromJson(response['data']);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating currency: $e');
      return false;
    }
  }
  
  /// Get currency by code
  CurrencyModel? getCurrencyByCode(String code) {
    try {
      return _currencies.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }
  
  /// Format amount with currency
  String formatAmount(double amount, String currencyCode) {
    final currency = getCurrencyByCode(currencyCode);
    if (currency != null) {
      return '${currency.symbol}${amount.toStringAsFixed(2)}';
    }
    return amount.toStringAsFixed(2);
  }
  
  /// Initialize currencies (call on app start)
  Future<void> initialize() async {
    await fetchCurrencies(isActive: true);
    await fetchBaseCurrency();
  }
}
