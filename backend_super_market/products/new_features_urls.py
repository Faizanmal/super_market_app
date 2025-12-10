"""
URL Configuration for New Features.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .batch_discount_views import (
    DiscountRuleViewSet, BatchDiscountViewSet,
    discount_dashboard, auto_apply_discounts, discount_analytics
)
from .sales_forecasting_views import (
    SalesHistoryViewSet, SalesForecastViewSet, RestockRecommendationViewSet,
    forecasting_dashboard, product_forecast_detail
)
from .customer_features_views import (
    ShoppingListViewSet, ShoppingListItemViewSet,
    DigitalReceiptViewSet, WarrantyTrackerViewSet, WarrantyClaimViewSet,
    customer_dashboard, create_receipt_from_purchase
)

# Create routers
router = DefaultRouter()

# Batch Discount routes
router.register(r'discount-rules', DiscountRuleViewSet, basename='discount-rule')
router.register(r'batch-discounts', BatchDiscountViewSet, basename='batch-discount')

# Sales Forecasting routes
router.register(r'sales-history', SalesHistoryViewSet, basename='sales-history')
router.register(r'forecasts', SalesForecastViewSet, basename='forecast')
router.register(r'restock-recommendations', RestockRecommendationViewSet, basename='restock-recommendation')

# Customer Features routes
router.register(r'shopping-lists', ShoppingListViewSet, basename='shopping-list')
router.register(r'shopping-list-items', ShoppingListItemViewSet, basename='shopping-list-item')
router.register(r'receipts', DigitalReceiptViewSet, basename='receipt')
router.register(r'warranties', WarrantyTrackerViewSet, basename='warranty')
router.register(r'warranty-claims', WarrantyClaimViewSet, basename='warranty-claim')

urlpatterns = [
    # Router URLs
    path('', include(router.urls)),
    
    # Batch Discount endpoints
    path('discounts/dashboard/', discount_dashboard, name='discount-dashboard'),
    path('discounts/auto-apply/', auto_apply_discounts, name='auto-apply-discounts'),
    path('discounts/analytics/', discount_analytics, name='discount-analytics'),
    
    # Sales Forecasting endpoints
    path('forecasting/dashboard/', forecasting_dashboard, name='forecasting-dashboard'),
    path('forecasting/product/<int:product_id>/', product_forecast_detail, name='product-forecast-detail'),
    
    # Customer Features endpoints
    path('customer/dashboard/', customer_dashboard, name='customer-dashboard'),
    path('customer/create-receipt/', create_receipt_from_purchase, name='create-receipt'),
]
