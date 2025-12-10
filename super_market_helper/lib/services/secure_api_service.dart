import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../models/notification_model.dart';

class SecureApiService {
  static final SecureApiService _instance = SecureApiService._internal();
  factory SecureApiService() => _instance;
  SecureApiService._internal();

  late Dio _dio;
  final _secureStorage = const FlutterSecureStorage();
  
  // Security configurations
  static const String _apiBaseUrl = 'http://localhost:8000/api/v1/';
  static const String _apiKeyHeader = 'X-API-Key';
  static const String _csrfTokenHeader = 'X-CSRFToken';
  static const String _requestIdHeader = 'X-Request-ID';
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);
  
  String? _accessToken;
  String? _refreshToken;
  String? _csrfToken;
  String? _apiKey;

  Future<void> initialize() async {
    // Load stored credentials
    _accessToken = await _secureStorage.read(key: 'access_token');
    _refreshToken = await _secureStorage.read(key: 'refresh_token');
    _csrfToken = await _secureStorage.read(key: 'csrf_token');
    _apiKey = await _secureStorage.read(key: 'api_key');

    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status! < 500; // Accept all responses < 500
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_securityInterceptor());
    _dio.interceptors.add(_retryInterceptor());
    _dio.interceptors.add(_loggingInterceptor());
    _dio.interceptors.add(_errorInterceptor());

    // SSL Pinning for production
    if (!const bool.fromEnvironment('DEBUG', defaultValue: true)) {
      _configureSslPinning();
    }
  }

  /// Security Interceptor - Adds authentication and security headers
  InterceptorsWrapper _securityInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add JWT token
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }

        // Add CSRF token for state-changing requests
        if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(options.method)) {
          if (_csrfToken != null) {
            options.headers[_csrfTokenHeader] = _csrfToken;
          }
        }

        // Add API key if available
        if (_apiKey != null) {
          options.headers[_apiKeyHeader] = _apiKey;
        }

        // Add unique request ID for tracking
        options.headers[_requestIdHeader] = _generateRequestId();

        // Add request timestamp for replay attack prevention
        options.headers['X-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();

        // Add integrity hash for sensitive requests
        if (options.data != null && options.method != 'GET') {
          final dataString = jsonEncode(options.data);
          final hash = _generateHash(dataString);
          options.headers['X-Content-Hash'] = hash;
        }

        return handler.next(options);
      },
      onResponse: (response, handler) async {
        // Store new CSRF token if provided
        if (response.headers.value('X-CSRFToken') != null) {
          _csrfToken = response.headers.value('X-CSRFToken');
          await _secureStorage.write(key: 'csrf_token', value: _csrfToken!);
        }

        return handler.next(response);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized - Try to refresh token
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            // Retry the request with new token
            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer $_accessToken';
            try {
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              return handler.reject(error);
            }
          }
        }

        return handler.next(error);
      },
    );
  }

  /// Retry Interceptor - Retries failed requests
  InterceptorsWrapper _retryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        
        // Don't retry client errors (4xx) except 401, 408, 429
        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          if (![401, 408, 429].contains(statusCode)) {
            return handler.next(error);
          }
        }

        final attempts = error.requestOptions.extra['retryCount'] ?? 0;
        if (attempts >= _maxRetries) {
          return handler.next(error);
        }

        // Exponential backoff
        final delay = Duration(milliseconds: (1000 * (attempts + 1)).toInt());
        await Future.delayed(delay);

        error.requestOptions.extra['retryCount'] = attempts + 1;

        try {
          final response = await _dio.fetch(error.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(error);
        }
      },
    );
  }

  /// Logging Interceptor - Logs requests and responses
  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('🔹 REQUEST: ${options.method} ${options.uri}');
        if (const bool.fromEnvironment('DEBUG', defaultValue: true)) {
          debugPrint('Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('Data: ${options.data}');
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.uri}');
        debugPrint('Message: ${error.message}');
        return handler.next(error);
      },
    );
  }

  /// Error Interceptor - Handles and formats errors
  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final errorMessage = _formatError(error);
        final wrappedError = DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: errorMessage,
        );
        return handler.next(wrappedError);
      },
    );
  }

  /// Configure SSL Certificate Pinning
  void _configureSslPinning() {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          // Add your SSL certificate validation logic here
          // For production, implement proper certificate pinning
          return false; // Reject all certificates in production by default
        };
        return client;
      },
    );
  }

  /// Generate unique request ID
  String _generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_generateRandomString(8)}';
  }

  /// Generate content hash for integrity checking
  String _generateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate random string
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
  }

  /// Format error messages
  String _formatError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == null) return 'Bad response from server';
        if (statusCode >= 400) {
          if (statusCode == 400) {
            return error.response?.data?['detail'] ?? 'Invalid request';
          } else if (statusCode == 401) {
            return 'Authentication failed. Please login again.';
          } else if (statusCode == 403) {
            return 'Access denied. You do not have permission to perform this action.';
          } else if (statusCode == 404) {
            return 'Resource not found.';
          } else if (statusCode >= 500) {
            return 'Server error. Please try again later.';
          } else {
            return error.response?.data?['detail'] ?? 'An error occurred';
          }
        }
        return 'Bad response from server';
      
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please check your internet connection.';
      
      case DioExceptionType.unknown:
        return 'An unexpected error occurred. Please try again.';
      
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _dio.post('/auth/refresh/', data: {
        'refresh': _refreshToken,
      });

      if (response.statusCode == 200) {
        _accessToken = response.data['access'];
        await _secureStorage.write(key: 'access_token', value: _accessToken!);
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await _clearTokens();
    }
    return false;
  }

  /// Clear stored tokens
  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  // API Methods

  /// Get audit logs
  Future<Map<String, dynamic>> getAuditLogs({
    int? userId,
    String? action,
    String? contentType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['user'] = userId;
      if (action != null) queryParams['action'] = action;
      if (contentType != null) queryParams['content_type'] = contentType;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _dio.get('/audit-logs/', queryParameters: queryParams);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get user activity
  Future<Map<String, dynamic>> getUserActivity(int userId) async {
    try {
      final response = await _dio.get('/audit-logs/user/$userId/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get object history
  Future<Map<String, dynamic>> getObjectHistory({
    required String contentType,
    required int objectId,
  }) async {
    try {
      final response = await _dio.get('/audit-logs/object/', queryParameters: {
        'content_type': contentType,
        'object_id': objectId,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get currencies
  Future<Map<String, dynamic>> getCurrencies({bool? isActive}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isActive != null) queryParams['is_active'] = isActive;
      
      final response = await _dio.get('/currencies/', queryParameters: queryParams);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get base currency
  Future<Map<String, dynamic>> getBaseCurrency() async {
    try {
      final response = await _dio.get('/currencies/base/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Convert currency
  Future<Map<String, dynamic>> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      final response = await _dio.post('/currencies/convert/', data: {
        'amount': amount,
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create currency
  Future<Map<String, dynamic>> createCurrency(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/currencies/', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update currency
  Future<Map<String, dynamic>> updateCurrency(int currencyId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/currencies/$currencyId/', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update exchange rates
  Future<Map<String, dynamic>> updateExchangeRates() async {
    try {
      final response = await _dio.post('/currencies/update-rates/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get inventory adjustments
  Future<Map<String, dynamic>> getInventoryAdjustments({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      
      final response = await _dio.get('/inventory-adjustments/', queryParameters: queryParams);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create inventory adjustment
  Future<Map<String, dynamic>> createInventoryAdjustment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/inventory-adjustments/', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Approve inventory adjustment
  Future<Map<String, dynamic>> approveInventoryAdjustment(int adjustmentId) async {
    try {
      final response = await _dio.post('/inventory-adjustments/$adjustmentId/approve/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Reject inventory adjustment
  Future<Map<String, dynamic>> rejectInventoryAdjustment(int adjustmentId, String reason) async {
    try {
      final response = await _dio.post('/inventory-adjustments/$adjustmentId/reject/', data: {
        'reason': reason,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get inventory adjustment stats
  Future<Map<String, dynamic>> getInventoryAdjustmentStats() async {
    try {
      final response = await _dio.get('/inventory-adjustments/stats/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get store transfers
  Future<Map<String, dynamic>> getStoreTransfers({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      
      final response = await _dio.get('/store-transfers/', queryParameters: queryParams);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create store transfer
  Future<Map<String, dynamic>> createStoreTransfer(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/store-transfers/', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Ship transfer
  Future<Map<String, dynamic>> shipTransfer(int transferId) async {
    try {
      final response = await _dio.post('/store-transfers/$transferId/ship/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Receive transfer
  Future<Map<String, dynamic>> receiveTransfer(int transferId) async {
    try {
      final response = await _dio.post('/store-transfers/$transferId/receive/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Cancel transfer
  Future<Map<String, dynamic>> cancelTransfer(int transferId) async {
    try {
      final response = await _dio.post('/store-transfers/$transferId/cancel/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get store transfer stats
  Future<Map<String, dynamic>> getStoreTransferStats() async {
    try {
      final response = await _dio.get('/store-transfers/stats/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get price history
  Future<Map<String, dynamic>> getPriceHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      
      final response = await _dio.get('/price-history/', queryParameters: queryParams);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get product price history
  Future<Map<String, dynamic>> getProductPriceHistory(int productId) async {
    try {
      final response = await _dio.get('/price-history/product/$productId/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get recent price changes
  Future<Map<String, dynamic>> getRecentPriceChanges({int days = 7}) async {
    try {
      final response = await _dio.get('/price-history/recent/', queryParameters: {
        'days': days,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get notifications
  Future<Map<String, dynamic>> getNotifications({
    bool? isRead,
    String? notificationType,
    String? priority,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isRead != null) queryParams['is_read'] = isRead;
      if (notificationType != null) queryParams['notification_type'] = notificationType;
      if (priority != null) queryParams['priority'] = priority;
      
      final response = await _dio.get('/notifications/', queryParameters: queryParams);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get unread notifications
  Future<Map<String, dynamic>> getUnreadNotifications() async {
    try {
      final response = await _dio.get('/notifications/unread/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get notification summary
  Future<NotificationSummary?> getNotificationSummary() async {
    try {
      final response = await _dio.get('/notifications/summary/');
      if (response.statusCode == 200) {
        return NotificationSummary.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting notification summary: $e');
      return null;
    }
  }

  /// Mark notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    try {
      final response = await _dio.post('/notifications/$notificationId/read/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final response = await _dio.post('/notifications/mark-all-read/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete notification
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      final response = await _dio.delete('/notifications/$notificationId/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Clear old notifications
  Future<Map<String, dynamic>> clearOldNotifications() async {
    try {
      final response = await _dio.post('/notifications/clear-old/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  // ==================== Generic HTTP Methods ====================

  /// Generic GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Options? options}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams, options: options);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Generic POST request
  Future<Response> post(String path, {Map<String, dynamic>? body, Map<String, dynamic>? queryParams, Options? options}) async {
    try {
      final response = await _dio.post(path, data: body, queryParameters: queryParams, options: options);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Generic PUT request
  Future<Response> put(String path, {Map<String, dynamic>? body, Map<String, dynamic>? queryParams, Options? options}) async {
    try {
      final response = await _dio.put(path, data: body, queryParameters: queryParams, options: options);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Generic PATCH request
  Future<Response> patch(String path, {Map<String, dynamic>? body, Map<String, dynamic>? queryParams, Options? options}) async {
    try {
      final response = await _dio.patch(path, data: body, queryParameters: queryParams, options: options);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Generic DELETE request
  Future<Response> delete(String path, {Map<String, dynamic>? queryParams, Options? options}) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParams, options: options);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}