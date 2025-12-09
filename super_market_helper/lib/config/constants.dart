/// App-wide constants
/// Contains all constant values used throughout the application
class AppConstants {
  // App Information
  static const String appName = 'SuperMart Manager';
  static const String appVersion = '1.0.0';
  
  // Hive Box Names
  static const String productsBox = 'products';
  static const String usersBox = 'users';
  static const String settingsBox = 'settings';
   
  // Hive Type IDs
  static const int productTypeId = 0;
  static const int userTypeId = 1;
  
  // Shared Preferences Keys
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyCurrentUserId = 'currentUserId';
  static const String keyThemeMode = 'themeMode';
  static const String keyNotificationsEnabled = 'notificationsEnabled';
  
  // Product Categories
  static const List<String> productCategories = [
    'Dairy',
    'Fruits & Vegetables',
    'Meat & Seafood',
    'Bakery',
    'Beverages',
    'Snacks',
    'Frozen Foods',
    'Canned Goods',
    'Personal Care',
    'Household',
    'Baby Products',
    'Other',
  ];
  
  // Expiry Alert Thresholds (in days)
  static const int expiryWarningDays = 7; // Show warning if expiring within 7 days
  static const int expiryDangerDays = 3; // Show danger if expiring within 3 days
  
  // Low Stock Threshold
  static const int lowStockThreshold = 10;
  
  // Notification Channels
  static const String expiryNotificationChannel = 'expiry_alerts';
  static const String stockNotificationChannel = 'stock_alerts';
  
  // Date Formats
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String storageDateFormat = 'yyyy-MM-dd';
  static const String displayDateTimeFormat = 'MMM dd, yyyy hh:mm a';
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Chart Colors
  static const List<String> chartColorHex = [
    '#2E7D32', // Green
    '#FF6F00', // Orange
    '#0288D1', // Blue
    '#7B1FA2', // Purple
    '#C62828', // Red
    '#00796B', // Teal
    '#F57C00', // Deep Orange
    '#5D4037', // Brown
  ];
  
  // Regex Patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?[\d\s\-\(\)]+$';
  static const String barcodePattern = r'^\d{8,13}$'; // EAN-8 or EAN-13
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  
  // Export File Names
  static const String exportFilePrefix = 'supermart_export_';
  
  // Error Messages
  static const String networkError = 'Network connection error. Please try again.';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String validationError = 'Please check your input and try again.';
  
  // Success Messages
  static const String productAddedSuccess = 'Product added successfully';
  static const String productUpdatedSuccess = 'Product updated successfully';
  static const String productDeletedSuccess = 'Product deleted successfully';
  
  // Barcode Scanning
  static const int scannerTimeout = 30; // seconds
}

/// Expiry status enumeration
enum ExpiryStatus {
  fresh,    // More than 7 days until expiry
  warning,  // 3-7 days until expiry
  danger,   // 0-3 days until expiry
  expired,  // Past expiry date
}

/// Stock status enumeration
enum StockStatus {
  inStock,   // Above low stock threshold
  lowStock,  // At or below low stock threshold
  outOfStock, // Zero quantity
}

/// Sort options for product listing
enum ProductSortOption {
  nameAsc,
  nameDesc,
  expiryDateAsc,
  expiryDateDesc,
  quantityAsc,
  quantityDesc,
  categoryAsc,
}
