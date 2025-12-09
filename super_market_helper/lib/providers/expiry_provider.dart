// Expiry Data Provider
// Manages expiry alerts, batches, and tasks state

import 'package:flutter/material.dart';
import '../models/expiry_models.dart';
import '../services/expiry_api_service.dart';

class ExpiryProvider with ChangeNotifier {
  final ExpiryApiService _apiService = ExpiryApiService();
  
  // State
  bool _isLoading = false;
  String? _errorMessage;
  
  // Data
  List<ProductBatch> _batches = [];
  List<ExpiryAlert> _alerts = [];
  List<Task> _tasks = [];
  DashboardSummary? _dashboard;
  ExpiryAnalytics? _analytics;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ProductBatch> get batches => _batches;
  List<ExpiryAlert> get alerts => _alerts;
  List<Task> get tasks => _tasks;
  DashboardSummary? get dashboard => _dashboard;
  ExpiryAnalytics? get analytics => _analytics;
  
  // Filtered getters
  List<ExpiryAlert> get criticalAlerts => 
      _alerts.where((a) => a.severity == 'critical' && !a.isResolved).toList();
  
  List<ExpiryAlert> get unresolvedAlerts => 
      _alerts.where((a) => !a.isResolved).toList();
  
  List<Task> get myPendingTasks => 
      _tasks.where((t) => t.status != 'completed').toList();
  
  List<Task> get overdueTasks => 
      _tasks.where((t) => t.dueDate.isBefore(DateTime.now()) &&
                           t.status != 'completed').toList();
  
  List<ProductBatch> get expiringSoonBatches => 
      _batches.where((b) => b.daysUntilExpiry <= 7 &&
                             b.expiryStatus != 'expired').toList();
  
  // ==================== DASHBOARD ====================
  
  Future<void> loadDashboard() async {
    _setLoading(true);
    _clearError();
    
    try {
      _dashboard = await _apiService.getDashboardSummary();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load dashboard: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // ==================== BATCHES ====================
  
  Future<void> loadBatches({String? status, int? store}) async {
    _setLoading(true);
    _clearError();
    
    try {
      _batches = await _apiService.getBatches(status: status, store: store);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load batches: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> loadExpiringSoonBatches({int days = 30}) async {
    _setLoading(true);
    _clearError();
    
    try {
      _batches = await _apiService.getExpiringSoonBatches(days: days);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load expiring batches: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<ProductBatch?> getBatchById(int id) async {
    try {
      return await _apiService.getBatchById(id);
    } catch (e) {
      _setError('Failed to load batch: ${e.toString()}');
      return null;
    }
  }
  
  Future<bool> markBatchExpired(int id) async {
    try {
      final updatedBatch = await _apiService.markBatchExpired(id);
      
      // Update local batch
      final index = _batches.indexWhere((b) => b.id == id);
      if (index != -1) {
        _batches[index] = updatedBatch;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to mark batch as expired: ${e.toString()}');
      return false;
    }
  }
  
  // ==================== ALERTS ====================
  
  Future<void> loadAlerts({String? severity, bool? isResolved}) async {
    _setLoading(true);
    _clearError();
    
    try {
      _alerts = await _apiService.getExpiryAlerts(
        severity: severity,
        isResolved: isResolved,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load alerts: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> loadCriticalAlerts() async {
    _setLoading(true);
    _clearError();
    
    try {
      _alerts = await _apiService.getCriticalAlerts();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load critical alerts: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> acknowledgeAlert(int id) async {
    try {
      final updatedAlert = await _apiService.acknowledgeAlert(id);
      
      // Update local alert
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alerts[index] = updatedAlert;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to acknowledge alert: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> resolveAlert(int id, String action, String notes) async {
    try {
      final updatedAlert = await _apiService.resolveAlert(id, action, notes);
      
      // Update local alert
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alerts[index] = updatedAlert;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to resolve alert: ${e.toString()}');
      return false;
    }
  }
  
  // ==================== TASKS ====================
  
  Future<void> loadMyTasks() async {
    _setLoading(true);
    _clearError();
    
    try {
      _tasks = await _apiService.getMyTasks();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tasks: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> loadTasks({String? status, String? priority}) async {
    _setLoading(true);
    _clearError();
    
    try {
      _tasks = await _apiService.getTasks(status: status, priority: priority);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tasks: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> startTask(int id) async {
    try {
      final updatedTask = await _apiService.startTask(id);
      
      // Update local task
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to start task: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> completeTask(int id, String notes) async {
    try {
      final updatedTask = await _apiService.completeTask(id, notes);
      
      // Update local task
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to complete task: ${e.toString()}');
      return false;
    }
  }
  
  // ==================== ANALYTICS ====================
  
  Future<void> loadAnalytics() async {
    _setLoading(true);
    _clearError();
    
    try {
      _analytics = await _apiService.getExpiryAnalytics();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load analytics: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // ==================== HELPERS ====================
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  void clearError() {
    _clearError();
    notifyListeners();
  }
  
  void clearAll() {
    _batches = [];
    _alerts = [];
    _tasks = [];
    _dashboard = null;
    _analytics = null;
    _clearError();
    notifyListeners();
  }
}
