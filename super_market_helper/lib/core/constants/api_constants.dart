/// API Constants - All API-related configuration.
class ApiConstants {
  // Prevent instantiation
  ApiConstants._();
  
  // ==================== Base URLs ====================
  /// Development base URL
  static const String devBaseUrl = 'http://localhost:8000/api';
  
  /// Staging base URL
  static const String stagingBaseUrl = 'https://staging-api.supermart.pro/api';
  
  /// Production base URL
  static const String prodBaseUrl = 'https://api.supermart.pro/api';
  
  /// Current base URL (change based on environment)
  static String get baseUrl => devBaseUrl;
  
  // ==================== Authentication ====================
  static const String authLogin = '/auth/login/';
  static const String authRegister = '/auth/register/';
  static const String authLogout = '/auth/logout/';
  static const String authRefreshToken = '/auth/token/refresh/';
  static const String authProfile = '/auth/profile/';
  static const String authChangePassword = '/auth/change-password/';
  static const String authResetPassword = '/auth/reset-password/';
  static const String authVerifyEmail = '/auth/verify-email/';
  
  // ==================== Products ====================
  static const String products = '/products/products/';
  static const String productsExpiringSoon = '/products/products/expiring_soon/';
  static const String productsExpired = '/products/products/expired/';
  static const String productsLowStock = '/products/products/low_stock/';
  static const String productsSearchBarcode = '/products/products/search_barcode/';
  static const String productsBulkCreate = '/products/products/bulk_create/';
  static const String productsBulkUpdate = '/products/products/bulk_update/';
  
  // ==================== Categories ====================
  static const String categories = '/products/categories/';
  
  // ==================== Suppliers ====================
  static const String suppliers = '/products/suppliers/';
  static const String supplierPerformance = '/products/supplier-performance/';
  static const String supplierContracts = '/products/supplier-contracts/';
  
  // ==================== Stock Movements ====================
  static const String stockMovements = '/products/stock-movements/';
  static const String stockMovementsBulk = '/products/stock-movements/bulk/';
  
  // ==================== Stores ====================
  static const String stores = '/products/stores/';
  static const String storeInventory = '/products/store-inventory/';
  static const String storeTransfers = '/products/store-transfers/';
  static const String storeMetrics = '/products/store-metrics/';
  
  // ==================== Purchase Orders ====================
  static const String purchaseOrders = '/products/purchase-orders/';
  
  // ==================== Analytics ====================
  static const String smartAnalytics = '/products/smart-analytics/';
  static const String reports = '/products/reports/';
  static const String dashboardMetrics = '/products/smart-analytics/dashboard_metrics/';
  static const String categoryAnalysis = '/products/smart-analytics/category_analysis/';
  static const String trendAnalysis = '/products/smart-analytics/trend_analysis/';
  static const String demandForecast = '/products/smart-analytics/demand_forecast/';
  static const String wastePredict = '/products/smart-analytics/waste_prediction/';
  
  // ==================== Notifications ====================
  static const String notifications = '/products/notifications/';
  static const String notificationsMarkRead = '/products/notifications/mark_all_read/';
  static const String notificationsUnreadCount = '/products/notifications/unread_count/';
  
  // ==================== Smart Features ====================
  static const String smartPricing = '/products/smart-pricing/';
  static const String smartPricingOptimize = '/products/smart-pricing/optimize/';
  static const String smartPricingBulk = '/products/smart-pricing/bulk_optimize/';
  
  static const String aiRecommendations = '/products/smart-analytics/ai_recommendations/';
  static const String reorderOptimization = '/products/smart-analytics/reorder_optimization/';
  
  // ==================== Expiry Management ====================
  static const String productBatches = '/products/batches/';
  static const String shelfLocations = '/products/shelf-locations/';
  static const String receivingLogs = '/products/receiving-logs/';
  static const String shelfAudits = '/products/shelf-audits/';
  static const String expiryAlerts = '/products/expiry-alerts/';
  static const String dynamicPricing = '/products/dynamic-pricing/';
  
  // ==================== IoT ====================
  static const String iotDevices = '/products/iot-devices/';
  static const String sensorReadings = '/products/sensor-readings/';
  static const String iotAlerts = '/products/iot-alerts/';
  
  // ==================== Sustainability ====================
  static const String sustainabilityMetrics = '/products/sustainability-metrics/';
  static const String wasteRecords = '/products/waste-records/';
  static const String sustainabilityInitiatives = '/products/sustainability-initiatives/';
  static const String greenSupplierRatings = '/products/green-supplier-ratings/';
  
  // ==================== Tasks ====================
  static const String tasks = '/products/tasks/';
  static const String taskAssign = '/products/tasks/assign/';
  static const String taskComplete = '/products/tasks/complete/';
  
  // ==================== Audit ====================
  static const String auditLogs = '/products/audit-logs/';
  static const String inventoryAdjustments = '/products/inventory-adjustments/';
  
  // ==================== Currency ====================
  static const String currencies = '/products/currencies/';
  static const String currencyConvert = '/products/currencies/convert/';
  
  // ==================== Shopping Lists ====================
  static const String shoppingLists = '/products/shopping-lists/';
  static const String shoppingItems = '/products/shopping-items/';
  
  // ==================== WebSocket ====================
  static const String wsNotifications = '/ws/notifications/';
  static const String wsStockUpdates = '/ws/stock-updates/';
  static const String wsIoTData = '/ws/iot-data/';
  
  // ==================== API Headers ====================
  static const String headerContentType = 'Content-Type';
  static const String headerAuthorization = 'Authorization';
  static const String headerAccept = 'Accept';
  static const String headerAcceptLanguage = 'Accept-Language';
  static const String headerClientVersion = 'X-Client-Version';
  static const String headerPlatform = 'X-Platform';
  static const String headerDeviceId = 'X-Device-Id';
  
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';
  
  // ==================== Query Parameters ====================
  static const String queryPage = 'page';
  static const String queryPageSize = 'page_size';
  static const String querySearch = 'search';
  static const String queryOrdering = 'ordering';
  static const String queryCategory = 'category';
  static const String querySupplier = 'supplier';
  static const String queryStore = 'store';
  static const String queryStartDate = 'start_date';
  static const String queryEndDate = 'end_date';
  static const String queryStatus = 'status';
  static const String queryPriority = 'priority';
  
  // ==================== Status Codes ====================
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusConflict = 409;
  static const int statusValidationError = 422;
  static const int statusTooManyRequests = 429;
  static const int statusInternalError = 500;
  static const int statusServiceUnavailable = 503;
}
