// Expiry & Shelf Management API Service
// Comprehensive API integration for the advanced expiry management system

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/expiry_models.dart';

class ExpiryApiService {
  static final ExpiryApiService _instance = ExpiryApiService._internal();
  factory ExpiryApiService() => _instance;
  
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Base URL - Update this with your backend URL
  static const String baseUrl = 'http://localhost:8000/api';
  
  ExpiryApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle token expiration
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request
            return handler.resolve(await _retry(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
  }
  
  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );
      
      await _storage.write(key: 'access_token', value: response.data['access']);
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }
  
  // ==================== AUTHENTICATION ====================
  
  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login/',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final loginResponse = LoginResponse.fromJson(response.data);
      
      // Save tokens
      await _storage.write(key: 'access_token', value: loginResponse.access);
      await _storage.write(key: 'refresh_token', value: loginResponse.refresh);
      await _storage.write(key: 'user_role', value: loginResponse.user.role);
      
      return loginResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<User> register(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/auth/register/', data: userData);
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> logout() async {
    await _storage.deleteAll();
  }
  
  Future<User?> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me/');
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
  
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
  
  Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }
  
  // ==================== PRODUCT BATCHES ====================
  
  Future<List<ProductBatch>> getBatches({
    String? status,
    int? store,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (store != null) queryParams['store'] = store;
      if (search != null) queryParams['search'] = search;
      
      final response = await _dio.get('/products/batches/', queryParameters: queryParams);
      return (response.data as List).map((item) => ProductBatch.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ProductBatch> getBatchById(int id) async {
    try {
      final response = await _dio.get('/products/batches/$id/');
      return ProductBatch.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<ProductBatch>> getExpiringSoonBatches({int days = 30}) async {
    try {
      final response = await _dio.get(
        '/products/batches/expiring_soon/',
        queryParameters: {'days': days},
      );
      return (response.data as List).map((item) => ProductBatch.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<ProductBatch>> getExpiredBatches() async {
    try {
      final response = await _dio.get('/products/batches/expired/');
      return (response.data as List).map((item) => ProductBatch.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, List<ProductBatch>>> getBatchesBySeverity() async {
    try {
      final response = await _dio.get('/products/batches/by_severity/');
      return {
        'critical': (response.data['critical'] as List).map((item) => ProductBatch.fromJson(item)).toList(),
        'high': (response.data['high'] as List).map((item) => ProductBatch.fromJson(item)).toList(),
        'medium': (response.data['medium'] as List).map((item) => ProductBatch.fromJson(item)).toList(),
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ProductBatch> createBatch(Map<String, dynamic> batchData) async {
    try {
      final response = await _dio.post('/products/batches/', data: batchData);
      return ProductBatch.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ProductBatch> markBatchExpired(int id) async {
    try {
      final response = await _dio.post('/products/batches/$id/mark_expired/');
      return ProductBatch.fromJson(response.data['batch']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== SHELF LOCATIONS ====================
  
  Future<List<ShelfLocation>> getShelfLocations({int? store}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (store != null) queryParams['store'] = store;
      
      final response = await _dio.get('/products/shelf-locations/', queryParameters: queryParams);
      return (response.data as List).map((item) => ShelfLocation.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ShelfLocation> getShelfLocationById(int id) async {
    try {
      final response = await _dio.get('/products/shelf-locations/$id/');
      return ShelfLocation.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<ProductBatch>> getBatchesAtLocation(int locationId) async {
    try {
      final response = await _dio.get('/products/shelf-locations/$locationId/batches/');
      return (response.data as List).map((item) => ProductBatch.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ShelfLocation> createShelfLocation(Map<String, dynamic> locationData) async {
    try {
      final response = await _dio.post('/products/shelf-locations/', data: locationData);
      return ShelfLocation.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ShelfLocation> generateQRCode(int locationId) async {
    try {
      final response = await _dio.post('/products/shelf-locations/$locationId/generate_qr/');
      return ShelfLocation.fromJson(response.data['location']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== RECEIVING ====================
  
  Future<List<ReceivingLog>> getReceivingLogs({String? status, int? store}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (store != null) queryParams['store'] = store;
      
      final response = await _dio.get('/products/receiving-logs/', queryParameters: queryParams);
      return (response.data as List).map((item) => ReceivingLog.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ReceivingLog> createReceivingLog(Map<String, dynamic> logData, {
    File? palletPhoto,
    File? invoicePhoto,
  }) async {
    try {
      final formData = FormData.fromMap(logData);
      
      if (palletPhoto != null) {
        formData.files.add(MapEntry(
          'pallet_photo',
          await MultipartFile.fromFile(palletPhoto.path),
        ));
      }
      
      if (invoicePhoto != null) {
        formData.files.add(MapEntry(
          'invoice_photo',
          await MultipartFile.fromFile(invoicePhoto.path),
        ));
      }
      
      final response = await _dio.post('/products/receiving-logs/', data: formData);
      return ReceivingLog.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ReceivingLog> approveReceivingLog(int id) async {
    try {
      final response = await _dio.post('/products/receiving-logs/$id/approve/');
      return ReceivingLog.fromJson(response.data['log']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ReceivingLog> rejectReceivingLog(int id, String reason) async {
    try {
      final response = await _dio.post(
        '/products/receiving-logs/$id/reject/',
        data: {'reason': reason},
      );
      return ReceivingLog.fromJson(response.data['log']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== AUDITS ====================
  
  Future<List<ShelfAudit>> getShelfAudits({String? status, int? store}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (store != null) queryParams['store'] = store;
      
      final response = await _dio.get('/products/shelf-audits/', queryParameters: queryParams);
      return (response.data as List).map((item) => ShelfAudit.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ShelfAudit> createShelfAudit(Map<String, dynamic> auditData) async {
    try {
      final response = await _dio.post('/products/shelf-audits/', data: auditData);
      return ShelfAudit.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<AuditItem> addAuditItem(Map<String, dynamic> itemData, {File? photo}) async {
    try {
      final formData = FormData.fromMap(itemData);
      
      if (photo != null) {
        formData.files.add(MapEntry(
          'photo',
          await MultipartFile.fromFile(photo.path),
        ));
      }
      
      final response = await _dio.post('/products/audit-items/', data: formData);
      return AuditItem.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ShelfAudit> completeAudit(int id) async {
    try {
      final response = await _dio.post('/products/shelf-audits/$id/complete/');
      return ShelfAudit.fromJson(response.data['audit']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== EXPIRY ALERTS ====================
  
  Future<List<ExpiryAlert>> getExpiryAlerts({
    String? severity,
    bool? isResolved,
    int? store,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (severity != null) queryParams['severity'] = severity;
      if (isResolved != null) queryParams['is_resolved'] = isResolved;
      if (store != null) queryParams['store'] = store;
      
      final response = await _dio.get('/products/expiry-alerts/', queryParameters: queryParams);
      return (response.data as List).map((item) => ExpiryAlert.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<ExpiryAlert>> getCriticalAlerts() async {
    try {
      final response = await _dio.get('/products/expiry-alerts/critical/');
      return (response.data as List).map((item) => ExpiryAlert.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<ExpiryAlert>> getUnresolvedAlerts() async {
    try {
      final response = await _dio.get('/products/expiry-alerts/unresolved/');
      return (response.data as List).map((item) => ExpiryAlert.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ExpiryAlert> acknowledgeAlert(int id) async {
    try {
      final response = await _dio.post('/products/expiry-alerts/$id/acknowledge/');
      return ExpiryAlert.fromJson(response.data['alert']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ExpiryAlert> resolveAlert(int id, String action, String notes) async {
    try {
      final response = await _dio.post(
        '/products/expiry-alerts/$id/resolve/',
        data: {
          'action': action,
          'notes': notes,
        },
      );
      return ExpiryAlert.fromJson(response.data['alert']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== TASKS ====================
  
  Future<List<Task>> getTasks({
    String? status,
    String? priority,
    int? assignedTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      if (assignedTo != null) queryParams['assigned_to'] = assignedTo;
      
      final response = await _dio.get('/products/tasks/', queryParameters: queryParams);
      return (response.data as List).map((item) => Task.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Task>> getMyTasks() async {
    try {
      final response = await _dio.get('/products/tasks/my_tasks/');
      return (response.data as List).map((item) => Task.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Task>> getOverdueTasks() async {
    try {
      final response = await _dio.get('/products/tasks/overdue/');
      return (response.data as List).map((item) => Task.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Task> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post('/products/tasks/', data: taskData);
      return Task.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Task> startTask(int id) async {
    try {
      final response = await _dio.post('/products/tasks/$id/start/');
      return Task.fromJson(response.data['task']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Task> completeTask(int id, String notes, {File? photo}) async {
    try {
      final formData = FormData.fromMap({'notes': notes});
      
      if (photo != null) {
        formData.files.add(MapEntry(
          'photo',
          await MultipartFile.fromFile(photo.path),
        ));
      }
      
      final response = await _dio.post('/products/tasks/$id/complete/', data: formData);
      return Task.fromJson(response.data['task']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== ANALYTICS ====================
  
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final response = await _dio.get('/products/analytics/dashboard/');
      return DashboardSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<ExpiryAnalytics> getExpiryAnalytics() async {
    try {
      final response = await _dio.get('/products/analytics/expiry_analytics/');
      return ExpiryAnalytics.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> getWastageAnalytics() async {
    try {
      final response = await _dio.get('/products/analytics/wastage_analytics/');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<dynamic>> getStoreComparison() async {
    try {
      final response = await _dio.get('/products/analytics/store_comparison/');
      return response.data['stores'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== DYNAMIC PRICING ====================
  
  Future<List<DynamicPricing>> getDynamicPricing({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      
      final response = await _dio.get('/products/dynamic-pricing/', queryParameters: queryParams);
      return (response.data as List).map((item) => DynamicPricing.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<DynamicPricing> createDynamicPricing(Map<String, dynamic> pricingData) async {
    try {
      final response = await _dio.post('/products/dynamic-pricing/', data: pricingData);
      return DynamicPricing.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<DynamicPricing> approveDynamicPricing(int id) async {
    try {
      final response = await _dio.post('/products/dynamic-pricing/$id/approve/');
      return DynamicPricing.fromJson(response.data['pricing']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<DynamicPricing> activateDynamicPricing(int id) async {
    try {
      final response = await _dio.post('/products/dynamic-pricing/$id/activate/');
      return DynamicPricing.fromJson(response.data['pricing']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== WASTAGE REPORTS ====================
  
  Future<List<WastageReport>> getWastageReports({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      
      final response = await _dio.get('/products/wastage-reports/', queryParameters: queryParams);
      return (response.data as List).map((item) => WastageReport.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<WastageReport> createWastageReport(Map<String, dynamic> reportData) async {
    try {
      final response = await _dio.post('/products/wastage-reports/', data: reportData);
      return WastageReport.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<WastageReport> submitWastageReport(int id) async {
    try {
      final response = await _dio.post('/products/wastage-reports/$id/submit/');
      return WastageReport.fromJson(response.data['report']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<WastageReport> approveWastageReport(int id) async {
    try {
      final response = await _dio.post('/products/wastage-reports/$id/approve/');
      return WastageReport.fromJson(response.data['report']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== ERROR HANDLING ====================
  
  String _handleError(DioException e) {
    if (e.response?.data != null) {
      if (e.response!.data is Map) {
        final errors = e.response!.data as Map<String, dynamic>;
        if (errors.containsKey('detail')) {
          return errors['detail'];
        }
        if (errors.containsKey('error')) {
          return errors['error'];
        }
        // Return first error message
        for (var value in errors.values) {
          if (value is String) return value;
          if (value is List && value.isNotEmpty) return value[0].toString();
        }
      }
      return e.response!.data.toString();
    }
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
