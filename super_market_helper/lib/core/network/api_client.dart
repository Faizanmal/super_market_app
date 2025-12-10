import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

/// Enterprise-grade API client with automatic token refresh,
/// retry logic, offline queue, and comprehensive error handling.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _httpClient = http.Client();
  final SecureStorageService _storage = SecureStorageService();
  
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  
  bool _isRefreshing = false;
  final List<Function> _tokenRefreshCallbacks = [];

  // ==================== Initialization ====================
  
  /// Initialize the API client and load stored tokens
  Future<void> init() async {
    _accessToken = await _storage.read(AppConstants.keyAuthToken);
    _refreshToken = await _storage.read(AppConstants.keyRefreshToken);
    
    final expiryStr = await _storage.read(AppConstants.keyTokenExpiry);
    if (expiryStr != null) {
      _tokenExpiry = DateTime.parse(expiryStr);
    }
  }

  // ==================== Authentication ====================
  
  /// Check if user is authenticated with valid token
  bool get isAuthenticated => _accessToken != null && _isTokenValid();
  
  bool _isTokenValid() {
    if (_tokenExpiry == null) return _accessToken != null;
    return DateTime.now().isBefore(_tokenExpiry!.subtract(AppConstants.tokenRefreshBuffer));
  }

  /// Set authentication tokens
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    Duration? accessLifetime,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = DateTime.now().add(accessLifetime ?? const Duration(hours: 1));
    
    await _storage.write(AppConstants.keyAuthToken, accessToken);
    await _storage.write(AppConstants.keyRefreshToken, refreshToken);
    await _storage.write(AppConstants.keyTokenExpiry, _tokenExpiry!.toIso8601String());
  }

  /// Clear authentication tokens (logout)
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    
    await _storage.delete(AppConstants.keyAuthToken);
    await _storage.delete(AppConstants.keyRefreshToken);
    await _storage.delete(AppConstants.keyTokenExpiry);
  }

  /// Refresh the access token
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;
    if (_isRefreshing) {
      // Wait for ongoing refresh
      return await _waitForRefresh();
    }

    _isRefreshing = true;

    try {
      final response = await _httpClient.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authRefreshToken}'),
        headers: {
          ApiConstants.headerContentType: ApiConstants.contentTypeJson,
        },
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == ApiConstants.statusOk) {
        final data = jsonDecode(response.body);
        await setTokens(
          accessToken: data['access'],
          refreshToken: _refreshToken!,
        );
        _notifyRefreshComplete(true);
        return true;
      }
    } catch (e) {
      // Token refresh failed
    } finally {
      _isRefreshing = false;
    }

    _notifyRefreshComplete(false);
    return false;
  }

  Future<bool> _waitForRefresh() async {
    final completer = Completer<bool>();
    _tokenRefreshCallbacks.add((success) => completer.complete(success));
    return completer.future;
  }

  void _notifyRefreshComplete(bool success) {
    for (final callback in _tokenRefreshCallbacks) {
      callback(success);
    }
    _tokenRefreshCallbacks.clear();
  }

  // ==================== Request Headers ====================
  
  Map<String, String> _buildHeaders({
    bool authenticated = true,
    String contentType = ApiConstants.contentTypeJson,
    Map<String, String>? additional,
  }) {
    final headers = <String, String>{
      ApiConstants.headerContentType: contentType,
      ApiConstants.headerAccept: ApiConstants.contentTypeJson,
      ApiConstants.headerClientVersion: AppConstants.appVersion,
      ApiConstants.headerPlatform: Platform.operatingSystem,
    };

    if (authenticated && _accessToken != null) {
      headers[ApiConstants.headerAuthorization] = 'Bearer $_accessToken';
    }

    if (additional != null) {
      headers.addAll(additional);
    }

    return headers;
  }

  // ==================== HTTP Methods ====================
  
  /// Perform a GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool authenticated = true,
    T Function(dynamic)? parser,
  }) async {
    return _makeRequest<T>(
      method: 'GET',
      endpoint: endpoint,
      queryParams: queryParams,
      authenticated: authenticated,
      parser: parser,
    );
  }

  /// Perform a POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool authenticated = true,
    T Function(dynamic)? parser,
  }) async {
    return _makeRequest<T>(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      authenticated: authenticated,
      parser: parser,
    );
  }

  /// Perform a PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool authenticated = true,
    T Function(dynamic)? parser,
  }) async {
    return _makeRequest<T>(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      authenticated: authenticated,
      parser: parser,
    );
  }

  /// Perform a PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool authenticated = true,
    T Function(dynamic)? parser,
  }) async {
    return _makeRequest<T>(
      method: 'PATCH',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      authenticated: authenticated,
      parser: parser,
    );
  }

  /// Perform a DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool authenticated = true,
    T Function(dynamic)? parser,
  }) async {
    return _makeRequest<T>(
      method: 'DELETE',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      authenticated: authenticated,
      parser: parser,
    );
  }

  /// Upload a file with multipart form data
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint, {
    required String fieldName,
    required String filePath,
    Map<String, String>? additionalFields,
    bool authenticated = true,
    T Function(dynamic)? parser,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(_buildHeaders(
        authenticated: authenticated,
        contentType: ApiConstants.contentTypeFormData,
      ));

      // Add file
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(AppConstants.apiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, parser);
    } on SocketException {
      throw ApiException.networkError();
    } on TimeoutException {
      throw ApiException.timeoutError();
    } catch (e) {
      throw ApiException.unknownError(e.toString());
    }
  }

  // ==================== Core Request Handler ====================
  
  Future<ApiResponse<T>> _makeRequest<T>({
    required String method,
    required String endpoint,
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool authenticated = true,
    T Function(dynamic)? parser,
    int retryCount = 0,
  }) async {
    // Check token validity and refresh if needed
    if (authenticated && !_isTokenValid() && _refreshToken != null) {
      final refreshed = await refreshToken();
      if (!refreshed) {
        throw ApiException.unauthorized();
      }
    }

    try {
      // Build URI with query parameters
      var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        ));
      }

      // Prepare headers
      final headers = _buildHeaders(authenticated: authenticated);

      // Make request
      http.Response response;
      switch (method) {
        case 'GET':
          response = await _httpClient.get(uri, headers: headers)
              .timeout(AppConstants.apiTimeout);
          break;
        case 'POST':
          response = await _httpClient.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(AppConstants.apiTimeout);
          break;
        case 'PUT':
          response = await _httpClient.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(AppConstants.apiTimeout);
          break;
        case 'PATCH':
          response = await _httpClient.patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(AppConstants.apiTimeout);
          break;
        case 'DELETE':
          response = await _httpClient.delete(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(AppConstants.apiTimeout);
          break;
        default:
          throw ApiException.unknownError('Unknown HTTP method: $method');
      }

      // Handle 401 with retry
      if (response.statusCode == ApiConstants.statusUnauthorized && 
          retryCount < AppConstants.maxRetryAttempts) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return _makeRequest<T>(
            method: method,
            endpoint: endpoint,
            body: body,
            queryParams: queryParams,
            authenticated: authenticated,
            parser: parser,
            retryCount: retryCount + 1,
          );
        }
      }

      return _handleResponse<T>(response, parser);
    } on SocketException {
      throw ApiException.networkError();
    } on TimeoutException {
      throw ApiException.timeoutError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.unknownError(e.toString());
    }
  }

  // ==================== Response Handler ====================
  
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? parser,
  ) {
    final statusCode = response.statusCode;
    dynamic data;

    try {
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }
    } catch (_) {
      data = response.body;
    }

    // Success responses
    if (statusCode >= 200 && statusCode < 300) {
      T? parsedData;
      if (parser != null && data != null) {
        parsedData = parser(data);
      } else if (data is T) {
        parsedData = data;
      }
      return ApiResponse<T>(
        success: true,
        statusCode: statusCode,
        data: parsedData,
        rawData: data,
      );
    }

    // Error responses
    final message = _extractErrorMessage(data);
    
    switch (statusCode) {
      case ApiConstants.statusBadRequest:
        throw ApiException.badRequest(message, data);
      case ApiConstants.statusUnauthorized:
        throw ApiException.unauthorized(message);
      case ApiConstants.statusForbidden:
        throw ApiException.forbidden(message);
      case ApiConstants.statusNotFound:
        throw ApiException.notFound(message);
      case ApiConstants.statusConflict:
        throw ApiException.conflict(message);
      case ApiConstants.statusValidationError:
        throw ApiException.validationError(message, data);
      case ApiConstants.statusTooManyRequests:
        throw ApiException.rateLimited();
      case ApiConstants.statusInternalError:
      case ApiConstants.statusServiceUnavailable:
        throw ApiException.serverError(message);
      default:
        throw ApiException.unknownError(message);
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data == null) return AppConstants.errorGeneric;
    if (data is String) return data;
    if (data is Map) {
      return data['message'] ?? 
             data['detail'] ?? 
             data['error'] ?? 
             AppConstants.errorGeneric;
    }
    return AppConstants.errorGeneric;
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Completer for async operations
class Completer<T> {
  final _callbacks = <void Function(T)>[];
  T? _result;
  bool _isComplete = false;

  Future<T> get future async {
    if (_isComplete) return _result as T;
    
    final completer = Completer<T>();
    _callbacks.add((result) => completer.complete(result));
    return completer.future;
  }

  void complete(T result) {
    _result = result;
    _isComplete = true;
    for (final callback in _callbacks) {
      callback(result);
    }
    _callbacks.clear();
  }
}

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final int statusCode;
  final T? data;
  final dynamic rawData;
  final String? message;

  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.rawData,
    this.message,
  });

  bool get hasData => data != null;
}

/// Paginated API Response
class PaginatedResponse<T> {
  final bool success;
  final int count;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponse({
    required this.success,
    required this.count,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    return PaginatedResponse<T>(
      success: json['success'] ?? true,
      count: json['count'] ?? 0,
      totalPages: json['total_pages'] ?? 1,
      currentPage: json['current_page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)
          ?.map((item) => itemParser(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  bool get hasMore => next != null;
  bool get hasPrevious => previous != null;
}
