import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

/// Centralized API client for all HTTP communications
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  ApiClient._internal() {
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
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));
  }

  late Dio _dio;
  final _storage = const FlutterSecureStorage();
  
  // TODO: Update with your backend URL
  static const String baseUrl = 'http://localhost:8000/api';
  
  /// Get authentication token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  /// Set authentication token
  Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  /// Clear authentication token
  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }
  
  /// Request interceptor - add auth token
  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    developer.log(
      'API Request: ${options.method} ${options.path}',
      name: 'ApiClient',
    );
    
    handler.next(options);
  }
  
  /// Response interceptor - log responses
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      'API Response: ${response.statusCode} ${response.requestOptions.path}',
      name: 'ApiClient',
    );
    handler.next(response);
  }
  
  /// Error interceptor - handle errors
  void _onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      'API Error: ${err.response?.statusCode} ${err.requestOptions.path}',
      name: 'ApiClient',
      error: err,
    );
    
    // Handle 401 Unauthorized - token expired
    if (err.response?.statusCode == 401) {
      clearToken();
      // TODO: Navigate to login screen
    }
    
    handler.next(err);
  }
  
  /// GET request
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// POST request
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// PUT request
  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? data,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// PATCH request
  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? data,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// DELETE request
  Future<dynamic> delete(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Upload file
  Future<dynamic> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });
      
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Download file
  Future<void> downloadFile(
    String path,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        path,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Handle and format errors
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timeout. Please check your internet connection.');
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['detail'] ?? 
                       error.response?.data?['message'] ??
                       'Request failed with status code: $statusCode';
        return ApiException(message, statusCode: statusCode);
        
      case DioExceptionType.cancel:
        return ApiException('Request cancelled');
        
      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return ApiException('No internet connection');
        }
        return ApiException('An unexpected error occurred: ${error.message}');
        
      default:
        return ApiException('An error occurred: ${error.message}');
    }
  }
  
  /// Check connection to server
  Future<bool> checkConnection() async {
    try {
      await _dio.get('/health/', options: Options(
        receiveTimeout: const Duration(seconds: 5),
      ));
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get Dio instance for custom requests
  Dio get dio => _dio;
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => message;
}
