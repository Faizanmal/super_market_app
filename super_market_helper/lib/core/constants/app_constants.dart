/// Application-wide constants and configuration.
/// All magic numbers and strings should be defined here.
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ==================== App Info ====================
  static const String appName = 'SuperMart Pro';
  static const String appVersion = '2.0.0';
  static const String appBuildNumber = '1';
  static const String appDescription = 'Enterprise Inventory Management System';
  
  // ==================== Cache Keys ====================
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyTokenExpiry = 'token_expiry';
  static const String keyCurrentUserId = 'current_user_id';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserData = 'user_data';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyCachedProducts = 'cached_products';
  static const String keyCachedCategories = 'cached_categories';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyOfflineQueue = 'offline_queue';
  static const String keyNotificationSettings = 'notification_settings';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyPinEnabled = 'pin_enabled';
  static const String keyPinHash = 'pin_hash';
  
  // ==================== Hive Type IDs ====================
  static const int userTypeId = 0;
  static const int productTypeId = 1;
  static const int categoryTypeId = 2;
  static const int alertTypeId = 3;
  static const int storeTypeId = 4;
  static const int batchTypeId = 5;
  static const int shelfLocationTypeId = 6;
  static const int receivingLogTypeId = 7;
  static const int taskTypeId = 8;
  static const int analyticsTypeId = 9;
  static const int auditTypeId = 10;
  static const int shoppingListTypeId = 11;
  static const int supplierTypeId = 12;
  static const int purchaseOrderTypeId = 13;
  
  // ==================== Durations ====================
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration syncInterval = Duration(minutes: 15);
  static const Duration notificationCheckInterval = Duration(minutes: 5);
  
  // ==================== Limits ====================
  static const int maxProductsPerPage = 20;
  static const int maxSearchResults = 50;
  static const int maxRecentSearches = 10;
  static const int maxImageSizeMB = 5;
  static const int maxBarcodeLength = 50;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int pinLength = 6;
  static const int otpLength = 6;
  static const int maxRetryAttempts = 3;
  static const int maxOfflineQueueSize = 1000;
  
  // ==================== Business Rules ====================
  static const int defaultExpiryWarningDays = 7;
  static const int criticalExpiryDays = 3;
  static const int lowStockThresholdPercent = 20;
  static const double defaultTaxRate = 0.0;
  static const String defaultCurrency = 'USD';
  
  // ==================== Feature Flags ====================
  static const bool enableBiometricAuth = true;
  static const bool enablePinAuth = true;
  static const bool enableOfflineMode = true;
  static const bool enableVoiceCommands = true;
  static const bool enableAIFeatures = true;
  static const bool enableMultiStore = true;
  static const bool enableIoTIntegration = true;
  static const bool enableSustainabilityTracking = true;
  
  // ==================== Routes ====================
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeDashboard = '/dashboard';
  static const String routeProducts = '/products';
  static const String routeProductDetail = '/products/detail';
  static const String routeAddProduct = '/products/add';
  static const String routeEditProduct = '/products/edit';
  static const String routeCategories = '/categories';
  static const String routeSuppliers = '/suppliers';
  static const String routeOrders = '/orders';
  static const String routeAlerts = '/alerts';
  static const String routeAnalytics = '/analytics';
  static const String routeReports = '/reports';
  static const String routeSettings = '/settings';
  static const String routeProfile = '/profile';
  static const String routeNotifications = '/notifications';
  static const String routeSmartPricing = '/smart-pricing';
  static const String routeIoTDashboard = '/iot-dashboard';
  static const String routeSustainability = '/sustainability';
  static const String routeSupplierPortal = '/supplier-portal';
  static const String routeMultiStore = '/multi-store';
  static const String routeAudit = '/audit';
  static const String routeReceiving = '/receiving';
  static const String routeTasks = '/tasks';
  static const String routeScanner = '/scanner';
  
  // ==================== Date Formats ====================
  static const String dateFormatDisplay = 'MMM dd, yyyy';
  static const String dateFormatShort = 'MM/dd/yy';
  static const String dateFormatFull = 'EEEE, MMMM dd, yyyy';
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String dateTimeFormatDisplay = 'MMM dd, yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  static const String timeFormatAmPm = 'hh:mm a';
  
  // ==================== Regex Patterns ====================
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?[\d\s-]{10,}$';
  static const String passwordPattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$';
  static const String barcodePattern = r'^[A-Za-z0-9-]{4,50}$';
  static const String skuPattern = r'^[A-Za-z0-9-]{2,20}$';
  static const String pricePattern = r'^\d+\.?\d{0,2}$';
  
  // ==================== Asset Paths ====================
  static const String assetsImages = 'assets/images';
  static const String assetsIcons = 'assets/icons';
  static const String assetsAnimations = 'assets/animations';
  
  // ==================== Error Messages ====================
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Please check your network.';
  static const String errorTimeout = 'Request timed out. Please try again.';
  static const String errorUnauthorized = 'Session expired. Please login again.';
  static const String errorForbidden = 'You don\'t have permission to perform this action.';
  static const String errorNotFound = 'The requested resource was not found.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorValidation = 'Please check your input and try again.';
}


/// User role definitions with permissions
enum UserRole {
  storeManager('store_manager', 'Store Manager'),
  stockReceiver('stock_receiver', 'Stock Receiver'),
  shelfStaff('shelf_staff', 'Shelf Staff'),
  auditor('auditor', 'Auditor/QA'),
  headOffice('head_office', 'Head Office Admin');

  final String value;
  final String displayName;
  
  const UserRole(this.value, this.displayName);
  
  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.shelfStaff,
    );
  }
  
  bool get canManageProducts => this == storeManager || this == headOffice;
  bool get canReceiveStock => this == stockReceiver || this == storeManager || this == headOffice;
  bool get canPerformAudit => this == auditor || this == storeManager || this == headOffice;
  bool get canViewAnalytics => this == auditor || this == storeManager || this == headOffice;
  bool get canManageStaff => this == storeManager || this == headOffice;
  bool get canManageStores => this == headOffice;
  bool get canViewAllStores => this == headOffice;
}


/// Product expiry status
enum ExpiryStatus {
  fresh('fresh', 'Fresh', 0xFF4CAF50),
  expiringSoon('expiring_soon', 'Expiring Soon', 0xFFFF9800),
  expired('expired', 'Expired', 0xFFF44336),
  unknown('unknown', 'Unknown', 0xFF9E9E9E);

  final String value;
  final String displayName;
  final int colorValue;
  
  const ExpiryStatus(this.value, this.displayName, this.colorValue);
  
  static ExpiryStatus fromString(String? value) {
    return ExpiryStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ExpiryStatus.unknown,
    );
  }
}


/// Stock status
enum StockStatus {
  outOfStock('out_of_stock', 'Out of Stock', 0xFFF44336),
  critical('critical', 'Critical', 0xFFFF5722),
  low('low', 'Low Stock', 0xFFFF9800),
  adequate('adequate', 'Adequate', 0xFF4CAF50),
  overstocked('overstocked', 'Overstocked', 0xFF2196F3);

  final String value;
  final String displayName;
  final int colorValue;
  
  const StockStatus(this.value, this.displayName, this.colorValue);
  
  static StockStatus fromString(String? value) {
    return StockStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StockStatus.adequate,
    );
  }
}


/// Movement types for stock tracking
enum MovementType {
  stockIn('in', 'Stock In'),
  stockOut('out', 'Stock Out'),
  adjustment('adjustment', 'Adjustment'),
  wastage('wastage', 'Wastage'),
  transfer('transfer', 'Transfer');

  final String value;
  final String displayName;
  
  const MovementType(this.value, this.displayName);
  
  static MovementType fromString(String? value) {
    return MovementType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MovementType.adjustment,
    );
  }
}


/// Notification priority levels
enum NotificationPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  critical('critical', 'Critical');

  final String value;
  final String displayName;
  
  const NotificationPriority(this.value, this.displayName);
  
  static NotificationPriority fromString(String? value) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => NotificationPriority.medium,
    );
  }
}
