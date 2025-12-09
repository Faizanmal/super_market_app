import 'package:flutter/foundation.dart';
import '../models/enterprise_models.dart';
import '../services/secure_api_service.dart';

/// Provider for managing audit logs and compliance tracking
class AuditProvider with ChangeNotifier {
  final SecureApiService _apiService = SecureApiService();
  
  List<AuditLogModel> _auditLogs = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<AuditLogModel> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Fetch audit logs with filters
  Future<void> fetchAuditLogs({
    int? userId,
    String? action,
    String? contentType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getAuditLogs(
        userId: userId,
        action: action,
        contentType: contentType,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (response['success']) {
        final results = response['data']['results'] ?? response['data'];
        if (results is List) {
          _auditLogs = results
              .map((json) => AuditLogModel.fromJson(json))
              .toList();
        } else {
          _auditLogs = [];
        }
        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching audit logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get user activity logs
  Future<List<AuditLogModel>> getUserActivity(int userId) async {
    try {
      final response = await _apiService.getUserActivity(userId);
      
      if (response['success']) {
        return (response['data'] as List)
            .map((json) => AuditLogModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching user activity: $e');
      return [];
    }
  }
  
  /// Get object history (all changes to a specific object)
  Future<List<AuditLogModel>> getObjectHistory({
    required String model,
    required int objectId,
  }) async {
    try {
      final response = await _apiService.getObjectHistory(
        contentType: model,
        objectId: objectId,
      );
      
      if (response['success']) {
        final data = response['data'];
        if (data is List) {
          return data.map((json) => AuditLogModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching object history: $e');
      return [];
    }
  }
  
  /// Get logs by action type
  List<AuditLogModel> getByAction(String action) {
    return _auditLogs.where((log) => log.action == action).toList();
  }
  
  /// Get logs by content type (model)
  List<AuditLogModel> getByContentType(String contentType) {
    return _auditLogs.where((log) => log.contentType == contentType).toList();
  }
  
  /// Get logs for today
  List<AuditLogModel> getTodayLogs() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _auditLogs.where((log) {
      return log.timestamp.isAfter(startOfDay);
    }).toList();
  }
  
  /// Get logs for last N days
  List<AuditLogModel> getRecentLogs(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return _auditLogs.where((log) {
      return log.timestamp.isAfter(cutoffDate);
    }).toList();
  }
  
  /// Export audit logs to JSON (for compliance reports)
  Map<String, dynamic> exportToJson({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    List<AuditLogModel> logsToExport = _auditLogs;
    
    if (startDate != null || endDate != null) {
      logsToExport = _auditLogs.where((log) {
        if (startDate != null && log.timestamp.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && log.timestamp.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
    }
    
    return {
      'export_date': DateTime.now().toIso8601String(),
      'total_logs': logsToExport.length,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'logs': logsToExport.map((log) => log.toJson()).toList(),
    };
  }
  
  /// Get activity summary by action
  Map<String, int> getActionSummary() {
    final summary = <String, int>{};
    
    for (final log in _auditLogs) {
      summary[log.action] = (summary[log.action] ?? 0) + 1;
    }
    
    return summary;
  }
  
  /// Get activity summary by user
  Map<int, int> getUserSummary() {
    final summary = <int, int>{};
    
    for (final log in _auditLogs) {
      if (log.userId != null) {
        summary[log.userId!] = (summary[log.userId!] ?? 0) + 1;
      }
    }
    
    return summary;
  }
  
  /// Get activity summary by content type
  Map<String, int> getContentTypeSummary() {
    final summary = <String, int>{};
    
    for (final log in _auditLogs) {
      if (log.contentType != null) {
        summary[log.contentType!] = (summary[log.contentType!] ?? 0) + 1;
      }
    }
    
    return summary;
  }
  
  /// Refresh audit logs
  Future<void> refresh() async {
    await fetchAuditLogs();
  }
}
