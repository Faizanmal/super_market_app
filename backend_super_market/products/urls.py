"""
URL patterns for products endpoints.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    CategoryViewSet,
    SupplierViewSet,
    ProductViewSet,
    StockMovementViewSet,
)
from .smart_views import (
    SmartAnalyticsViewSet,
    ShoppingListViewSet,
    ShoppingListItemViewSet,
    PurchaseOrderViewSet,
    ProductFavoriteViewSet,
    StoreViewSet,
    ProductReviewViewSet,
)
from .report_views import ReportViewSet
from .enterprise_views import (
    NotificationViewSet,
    AuditLogViewSet,
    CurrencyViewSet,
    InventoryAdjustmentViewSet,
    StoreTransferViewSet,
    PriceHistoryViewSet,
    SupplierContractViewSet,
)
from .expiry_api_views import (
    ProductBatchViewSet,
    ShelfLocationViewSet,
    BatchLocationViewSet,
    ReceivingLogViewSet,
    ShelfAuditViewSet,
    AuditItemViewSet,
    ExpiryAlertViewSet,
    TaskViewSet,
    PhotoEvidenceViewSet,
    WastageReportViewSet,
    WastageItemViewSet,
    ComplianceLogViewSet,
    SupplierPerformanceViewSet,
    DynamicPricingViewSet,
    NotificationPreferenceViewSet,
    ExpiryAnalyticsViewSet,
)
from .multi_store_views import (
    StoreViewSet as MultiStoreViewSet,
    StoreInventoryViewSet,
    InterStoreTransferViewSet,
    StorePerformanceMetricsViewSet,
    StoreUserViewSet,
)
from .smart_pricing_views import SmartPricingViewSet
from .iot_views import IoTDeviceViewSet
from .supplier_views import (
    EnhancedSupplierViewSet,
    SupplierPerformanceViewSet as EnhancedSupplierPerformanceViewSet,
    SupplierContractViewSet as EnhancedSupplierContractViewSet,
    AutomatedReorderViewSet,
)
from .sustainability_views import (
    SustainabilityMetricsViewSet,
    WasteRecordViewSet,
    SustainabilityInitiativeViewSet,
    GreenSupplierRatingViewSet,
)
from .gamification_views import GamificationViewSet, BadgeViewSet

app_name = 'products'

router = DefaultRouter()

# Core functionality
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'suppliers', SupplierViewSet, basename='supplier')
router.register(r'products', ProductViewSet, basename='product')
router.register(r'stock-movements', StockMovementViewSet, basename='stock-movement')

# Smart features
router.register(r'smart-analytics', SmartAnalyticsViewSet, basename='smart-analytics')
router.register(r'reports', ReportViewSet, basename='report')
router.register(r'shopping-lists', ShoppingListViewSet, basename='shopping-list')
router.register(r'shopping-items', ShoppingListItemViewSet, basename='shopping-item')
router.register(r'purchase-orders', PurchaseOrderViewSet, basename='purchase-order')
router.register(r'favorites', ProductFavoriteViewSet, basename='favorite')
router.register(r'stores', StoreViewSet, basename='store')
router.register(r'reviews', ProductReviewViewSet, basename='review')

# Enterprise features
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'audit-logs', AuditLogViewSet, basename='audit-log')
router.register(r'currencies', CurrencyViewSet, basename='currency')
router.register(r'inventory-adjustments', InventoryAdjustmentViewSet, basename='inventory-adjustment')
router.register(r'store-transfers', StoreTransferViewSet, basename='store-transfer')
router.register(r'price-history', PriceHistoryViewSet, basename='price-history')
router.register(r'supplier-contracts', SupplierContractViewSet, basename='supplier-contract')

# Expiry & Shelf Management System - Core Models
router.register(r'batches', ProductBatchViewSet, basename='batch')
router.register(r'shelf-locations', ShelfLocationViewSet, basename='shelf-location')
router.register(r'batch-locations', BatchLocationViewSet, basename='batch-location')
router.register(r'receiving-logs', ReceivingLogViewSet, basename='receiving-log')
router.register(r'shelf-audits', ShelfAuditViewSet, basename='shelf-audit')
router.register(r'audit-items', AuditItemViewSet, basename='audit-item')
router.register(r'expiry-alerts', ExpiryAlertViewSet, basename='expiry-alert')
router.register(r'tasks', TaskViewSet, basename='task')
router.register(r'photos', PhotoEvidenceViewSet, basename='photo')

# Expiry & Shelf Management System - Reporting & Analytics
router.register(r'wastage-reports', WastageReportViewSet, basename='wastage-report')
router.register(r'wastage-items', WastageItemViewSet, basename='wastage-item')
router.register(r'compliance-logs', ComplianceLogViewSet, basename='compliance-log')
router.register(r'supplier-performance', SupplierPerformanceViewSet, basename='supplier-performance')
router.register(r'dynamic-pricing', DynamicPricingViewSet, basename='dynamic-pricing')
router.register(r'notification-preferences', NotificationPreferenceViewSet, basename='notification-preference')
router.register(r'expiry-analytics', ExpiryAnalyticsViewSet, basename='expiry-analytics')

# Multi-Store Management System
router.register(r'multi-stores', MultiStoreViewSet, basename='multi-store')
router.register(r'store-inventories', StoreInventoryViewSet, basename='store-inventory')
router.register(r'inter-store-transfers', InterStoreTransferViewSet, basename='inter-store-transfer')
router.register(r'store-performance', StorePerformanceMetricsViewSet, basename='store-performance')
router.register(r'store-users', StoreUserViewSet, basename='store-user')

# Advanced Enterprise Features
# Smart Pricing System
router.register(r'smart-pricing', SmartPricingViewSet, basename='smart-pricing')

# IoT Device Management
router.register(r'iot-devices', IoTDeviceViewSet, basename='iot-device')

# Enhanced Supplier Management
router.register(r'enhanced-suppliers', EnhancedSupplierViewSet, basename='enhanced-supplier')
router.register(r'enhanced-supplier-performance', EnhancedSupplierPerformanceViewSet, basename='enhanced-supplier-performance')
router.register(r'enhanced-supplier-contracts', EnhancedSupplierContractViewSet, basename='enhanced-supplier-contract')
router.register(r'automated-reorders', AutomatedReorderViewSet, basename='automated-reorder')

# Sustainability Management
router.register(r'sustainability-metrics', SustainabilityMetricsViewSet, basename='sustainability-metrics')
router.register(r'waste-records', WasteRecordViewSet, basename='waste-record')
router.register(r'sustainability-initiatives', SustainabilityInitiativeViewSet, basename='sustainability-initiative')
router.register(r'green-supplier-ratings', GreenSupplierRatingViewSet, basename='green-supplier-rating')

# Gamification
router.register(r'gamification', GamificationViewSet, basename='gamification')
router.register(r'badges', BadgeViewSet, basename='badge')

urlpatterns = [
    path('', include(router.urls)),
    
    # Security system URLs
    path('', include('products.security_urls')),
    
    # ML Analytics URLs
    path('ml/', include([
        path('demand-forecast/', include('products.ml_urls')),
    ])),
    
    # Receipt OCR URLs  
    path('ocr/', include([
        path('receipt-scan/', include('products.receipt_urls')),
    ])),
    
    # WebSocket URLs are handled in routing.py
    # Currency URLs
    path('currency/', include([
        path('exchange-rates/', include('products.currency_urls')),
    ])),
    
    # Barcode URLs
    path('barcode/', include([
        path('generate/', include('products.barcode_urls')),
    ])),
    
    # New Features - Batch Discounts, Sales Forecasting, Customer Features
    path('features/', include('products.new_features_urls')),
    
    # Customer App, AI Chatbot, Staff Management, Payments
    path('v2/', include('products.new_features_urls_v2')),
]
 