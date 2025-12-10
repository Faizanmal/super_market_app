import '../constants/app_constants.dart';

/// Custom API Exception class for comprehensive error handling.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String code;
  final dynamic errors;
  final bool isNetworkError;
  final bool isAuthError;
  final bool isValidationError;
  final bool isServerError;

  const ApiException({
    required this.message,
    this.statusCode,
    required this.code,
    this.errors,
    this.isNetworkError = false,
    this.isAuthError = false,
    this.isValidationError = false,
    this.isServerError = false,
  });

  // ==================== Factory Constructors ====================

  /// Network connectivity error
  factory ApiException.networkError([String? message]) {
    return ApiException(
      message: message ?? AppConstants.errorNetwork,
      code: 'NETWORK_ERROR',
      isNetworkError: true,
    );
  }

  /// Request timeout error
  factory ApiException.timeoutError([String? message]) {
    return ApiException(
      message: message ?? AppConstants.errorTimeout,
      code: 'TIMEOUT_ERROR',
      isNetworkError: true,
    );
  }

  /// Bad request (400)
  factory ApiException.badRequest([String? message, dynamic errors]) {
    return ApiException(
      message: message ?? AppConstants.errorValidation,
      statusCode: 400,
      code: 'BAD_REQUEST',
      errors: errors,
      isValidationError: true,
    );
  }

  /// Unauthorized (401)
  factory ApiException.unauthorized([String? message]) {
    return ApiException(
      message: message ?? AppConstants.errorUnauthorized,
      statusCode: 401,
      code: 'UNAUTHORIZED',
      isAuthError: true,
    );
  }

  /// Forbidden (403)
  factory ApiException.forbidden([String? message]) {
    return ApiException(
      message: message ?? AppConstants.errorForbidden,
      statusCode: 403,
      code: 'FORBIDDEN',
      isAuthError: true,
    );
  }

  /// Not found (404)
  factory ApiException.notFound([String? message]) {
    return ApiException(
      message: message ?? AppConstants.errorNotFound,
      statusCode: 404,
      code: 'NOT_FOUND',
    );
  }

  /// Conflict (409)
  factory ApiException.conflict([String? message]) {
    return ApiException(
      message: message ?? 'A conflict occurred with the current state.',
      statusCode: 409,
      code: 'CONFLICT',
    );
  }

  /// Validation error (422)
  factory ApiException.validationError([String? message, dynamic errors]) {
    return ApiException(
      message: message ?? AppConstants.errorValidation,
      statusCode: 422,
      code: 'VALIDATION_ERROR',
      errors: errors,
      isValidationError: true,
    );
  }

  /// Rate limited (429)
  factory ApiException.rateLimited([String? message]) {
    return ApiException(
      message: message ?? 'Rate limit exceeded. Please wait before trying again.',
      statusCode: 429,
      code: 'RATE_LIMITED',
    );
  }

  /// Server error (500, 503)
  factory ApiException.serverError([String? message]) {
    return ApiException(
      message: message ?? AppConstants.errorServer,
      statusCode: 500,
      code: 'SERVER_ERROR',
      isServerError: true,
    );
  }

  /// Unknown error
  factory ApiException.unknownError([String? message]) {
    return ApiException(
      message: message ?? AppConstants.errorGeneric,
      code: 'UNKNOWN_ERROR',
    );
  }

  // ==================== Error Field Helpers ====================

  /// Get validation errors as a map
  Map<String, List<String>> get validationErrors {
    if (errors == null) return {};
    if (errors is Map) {
      final result = <String, List<String>>{};
      (errors as Map).forEach((key, value) {
        if (value is List) {
          result[key.toString()] = value.map((e) => e.toString()).toList();
        } else {
          result[key.toString()] = [value.toString()];
        }
      });
      return result;
    }
    return {};
  }

  /// Get first error for a field
  String? getFieldError(String field) {
    final fieldErrors = validationErrors[field];
    return fieldErrors?.isNotEmpty == true ? fieldErrors!.first : null;
  }

  /// Get all error messages as a single string
  String get allErrorsAsString {
    if (validationErrors.isEmpty) return message;
    
    final messages = <String>[];
    validationErrors.forEach((field, errors) {
      for (final error in errors) {
        messages.add('$field: $error');
      }
    });
    return messages.join('\n');
  }

  // ==================== Display Helpers ====================

  /// Get user-friendly error message
  String get userMessage {
    if (isNetworkError) {
      return 'Please check your internet connection and try again.';
    }
    if (isAuthError) {
      return 'Your session has expired. Please log in again.';
    }
    if (isServerError) {
      return 'We\'re experiencing technical difficulties. Please try again later.';
    }
    return message;
  }

  /// Get icon for error type
  String get errorIcon {
    if (isNetworkError) return '📶';
    if (isAuthError) return '🔒';
    if (isValidationError) return '⚠️';
    if (isServerError) return '🔧';
    return '❌';
  }

  /// Check if error is recoverable (can retry)
  bool get isRecoverable {
    return isNetworkError || isServerError || statusCode == 429;
  }

  /// Check if user should be logged out
  bool get requiresLogout {
    return statusCode == 401;
  }

  @override
  String toString() {
    return 'ApiException{code: $code, statusCode: $statusCode, message: $message}';
  }
}

/// Extension to handle API exceptions in try-catch blocks
extension ApiExceptionHandler on Future {
  /// Handle API exceptions with custom callbacks
  Future<T?> handleApiError<T>({
    void Function(ApiException)? onError,
    void Function()? onNetworkError,
    void Function()? onAuthError,
    void Function()? onServerError,
    T? defaultValue,
  }) async {
    try {
      return await this as T?;
    } on ApiException catch (e) {
      if (e.isNetworkError && onNetworkError != null) {
        onNetworkError();
      } else if (e.isAuthError && onAuthError != null) {
        onAuthError();
      } else if (e.isServerError && onServerError != null) {
        onServerError();
      } else if (onError != null) {
        onError(e);
      }
      return defaultValue;
    }
  }
}
