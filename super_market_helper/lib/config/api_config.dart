/// API Configuration for secure connection between Flutter and Django backend
class ApiConfig {
  // === ENVIRONMENT CONFIGURATION ===
  
  /// Current environment (development, staging, production)
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  ); 
  
  /// Base API URL - Change this based on your environment
  static String get baseUrl {
    switch (environment) {
      case 'production':
        return 'https://api.yourproductiondomain.com'; // Replace with your production URL
      case 'staging':
        return 'https://staging-api.yourproductiondomain.com'; // Replace with staging URL
      case 'development':
      default:
        // For local development:
        // - Android Emulator: use 10.0.2.2
        // - iOS Simulator: use localhost or 127.0.0.1
        // - Physical Device: use your computer's local IP (e.g., 192.168.1.100)
        return 'http://10.0.2.2:8000'; // Android emulator default
        // return 'http://localhost:8000'; // iOS simulator
        // return 'http://192.168.1.100:8000'; // Physical device (replace with your IP)
    }
  }
  
  // === API ENDPOINTS ===
  
  static const String apiVersion = 'api/v1';
  static String get apiBaseUrl => '$baseUrl/$apiVersion';
  
  // Authentication
  static String get loginUrl => '$apiBaseUrl/accounts/login/';
  static String get registerUrl => '$apiBaseUrl/accounts/register/';
  static String get refreshTokenUrl => '$apiBaseUrl/accounts/token/refresh/';
  static String get logoutUrl => '$apiBaseUrl/accounts/logout/';
  static String get profileUrl => '$apiBaseUrl/accounts/profile/';
  
  // Products
  static String get productsUrl => '$apiBaseUrl/products/';
  
  // Categories
  static String get categoriesUrl => '$apiBaseUrl/products/categories/';
  
  // Suppliers
  static String get suppliersUrl => '$apiBaseUrl/products/suppliers/';
  
  // Purchase Orders
  static String get purchaseOrdersUrl => '$apiBaseUrl/products/purchase-orders/';
  
  // Enterprise Features
  static String get notificationsUrl => '$apiBaseUrl/products/notifications/';
  static String get currenciesUrl => '$apiBaseUrl/products/currencies/';
  static String get inventoryAdjustmentsUrl => '$apiBaseUrl/products/inventory-adjustments/';
  static String get storeTransfersUrl => '$apiBaseUrl/products/store-transfers/';
  static String get priceHistoryUrl => '$apiBaseUrl/products/price-history/';
  static String get auditLogsUrl => '$apiBaseUrl/products/audit-logs/';
  static String get supplierContractsUrl => '$apiBaseUrl/products/supplier-contracts/';
  
  // Analytics
  static String get analyticsUrl => '$apiBaseUrl/analytics/';
  
  // === SECURITY CONFIGURATION ===
  
  /// Enable SSL certificate pinning (production only)
  static bool get enableSslPinning => environment == 'production';
  
  /// SSL certificate fingerprints for pinning (SHA-256)
  /// Generate using: openssl s_client -connect yourdomain.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
  static List<String> get sslCertificateFingerprints => [
    // Add your production SSL certificate fingerprints here
    // Example: 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];
  
  /// API Key for additional security layer (if using API key authentication)
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '', // Set via --dart-define=API_KEY=your_key_here
  );
  
  /// Enable request/response integrity checking (SHA-256 hashing)
  static const bool enableIntegrityCheck = true;
  
  /// Enable automatic token refresh
  static const bool enableAutoTokenRefresh = true;
  
  /// Token refresh threshold (refresh token X seconds before expiry)
  static const int tokenRefreshThreshold = 300; // 5 minutes
  
  // === NETWORK CONFIGURATION ===
  
  /// Request timeout in milliseconds
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds
  
  /// Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 3;
  
  /// Retry delay (exponential backoff base in milliseconds)
  static const int retryDelayBase = 1000; // 1 second
  
  // === LOGGING CONFIGURATION ===
  
  /// Enable detailed API logging (disable in production)
  static bool get enableLogging => environment != 'production';
  
  /// Log request/response bodies
  static bool get logRequestBody => enableLogging;
  static bool get logResponseBody => enableLogging;
  
  // === STORAGE KEYS ===
  
  /// Secure storage keys for credentials
  static const String storageKeyAccessToken = 'access_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeyUsername = 'username';
  static const String storageKeyEmail = 'email';
  static const String storageKeyUserRole = 'user_role';
  
  // === WEBSOCKET CONFIGURATION ===
  
  /// WebSocket base URL for real-time notifications
  static String get wsBaseUrl {
    final protocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final host = baseUrl.replaceFirst(RegExp(r'https?://'), '');
    return '$protocol://$host/ws';
  }
  
  static String get notificationsWsUrl => '$wsBaseUrl/notifications/';
  static String get inventoryAlertsWsUrl => '$wsBaseUrl/inventory-alerts/';
  
  // === FEATURE FLAGS ===
  
  /// Enable offline mode support
  static const bool enableOfflineMode = true;
  
  /// Enable biometric authentication
  static const bool enableBiometrics = true;
  
  /// Enable voice commands
  static const bool enableVoiceCommands = true;
  
  /// Enable barcode scanning
  static const bool enableBarcodeScanning = true;
  
  /// Enable multi-currency support
  static const bool enableMultiCurrency = true;
  
  /// Enable real-time notifications
  static const bool enableRealTimeNotifications = true;
  
  // === CACHE CONFIGURATION ===
  
  /// Cache duration for API responses
  static const Duration cacheDuration = Duration(minutes: 5);
  
  /// Maximum cache size in MB
  static const int maxCacheSize = 50;
  
  // === VALIDATION ===
  
  /// Validate configuration on app start
  static void validate() {
    assert(baseUrl.isNotEmpty, 'Base URL cannot be empty');
    assert(connectTimeout > 0, 'Connect timeout must be positive');
    assert(maxRetryAttempts >= 0, 'Max retry attempts cannot be negative');
    
    if (enableSslPinning && sslCertificateFingerprints.isEmpty) {
      throw Exception('SSL pinning enabled but no certificates configured');
    }
  } 
  
  /// Get configuration summary for debugging
  static Map<String, dynamic> getSummary() {
    return {
      'environment': environment,
      'baseUrl': baseUrl,
      'apiBaseUrl': apiBaseUrl,
      'sslPinningEnabled': enableSslPinning,
      'integrityCheckEnabled': enableIntegrityCheck,
      'autoTokenRefreshEnabled': enableAutoTokenRefresh,
      'loggingEnabled': enableLogging,
      'offlineModeEnabled': enableOfflineMode,
    };
  }
}
