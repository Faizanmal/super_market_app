import 'package:flutter/foundation.dart';

/// Configuration class for API and app settings
/// Update these values for your deployment
class AppConfig {
  // ============ Backend API Configuration ============
  
  /// Production API URL - Update this for production deployment
  static const String productionApiUrl = 'https://your-production-api.com/api';
  
  /// Development API URL - For local testing
  static const String developmentApiUrl = 'http://localhost:8000/api';
  
  /// Get the current API URL based on build mode
  static String get apiUrl {
    if (kReleaseMode) {
      return productionApiUrl;
    } else {
      return developmentApiUrl;
    }
  }
  
  // ============ WebSocket Configuration ============
  
  static const String productionWsUrl = 'wss://your-production-api.com/ws';
  static const String developmentWsUrl = 'ws://localhost:8000/ws';
  
  static String get wsUrl {
    if (kReleaseMode) {
      return productionWsUrl;
    } else {
      return developmentWsUrl;
    }
  }
  
  // ============ Firebase Configuration ============
  
  /// Enable/Disable Firebase features
  static const bool enableFirebase = true;
  
  // ============ Feature Flags ============
  
  /// Enable/Disable voice commands
  static const bool enableVoiceCommands = true;
  
  /// Enable/Disable gamification
  static const bool enableGamification = true;
  
  /// Enable/Disable AI forecasting
  static const bool enableAIForecasting = true;
  
  /// Enable/Disable export features
  static const bool enableExport = true;
  
  /// Enable/Disable offline mode
  static const bool enableOfflineMode = true;
  
  // ============ App Settings ============
  
  /// Default items per page for pagination
  static const int itemsPerPage = 20;
  
  /// Cache duration in hours
  static const int cacheDuration = 24;
  
  /// Auto-sync interval in minutes
  static const int autoSyncInterval = 15;
  
  /// Low stock threshold percentage
  static const double lowStockThreshold = 0.2;
  
  /// Expiry alert days threshold
  static const int expiryAlertDays = 30;
  
  // ============ Security Settings ============
  
  /// Enable biometric authentication
  static const bool enableBiometric = true;
  
  /// Enable PIN security
  static const bool enablePinSecurity = true;
  
  /// Token refresh threshold in minutes
  static const int tokenRefreshThreshold = 5;
  
  // ============ Export Settings ============
  
  /// Default export format (csv, pdf, excel)
  static const String defaultExportFormat = 'csv';
  
  /// Include images in PDF exports
  static const bool includePdfImages = false;
  
  // ============ Notification Settings ============
  
  /// Enable push notifications
  static const bool enablePushNotifications = true;
  
  /// Enable local notifications
  static const bool enableLocalNotifications = true;
  
  /// Notification sound
  static const bool enableNotificationSound = true;
  
  // ============ Performance Settings ============
  
  /// Enable image caching
  static const bool enableImageCache = true;
  
  /// Max cache size in MB
  static const int maxCacheSize = 100;
  
  /// Enable analytics tracking
  static const bool enableAnalytics = true;
  
  // ============ Development Settings ============
  
  /// Enable debug logging
  static const bool enableDebugLogging = !kReleaseMode;
  
  /// Show performance overlay
  static const bool showPerformanceOverlay = false;
  
  /// Enable mock data for testing
  static const bool useMockData = false;
}

/// Environment-specific configuration
class Environment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';
  
  /// Current environment
  static String get current {
    if (kReleaseMode) {
      return production;
    } else {
      return development;
    }
  }
}
