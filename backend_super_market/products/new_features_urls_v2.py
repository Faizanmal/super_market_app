"""
New Features URL Configuration
Routes for customer app, chatbot, staff management, etc.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .customer_app_views import (
    CustomerProfileViewSet, LoyaltyViewSet, OffersViewSet,
    CustomerOrderViewSet, ProductReviewViewSet, RecipeViewSet,
    StoreNavigationViewSet, ReferralViewSet
)
from .chatbot_views import ChatbotViewSet, VisualRecognitionViewSet, quick_search
from .staff_management_views import (
    StaffProfileViewSet, ShiftViewSet, TimeTrackingViewSet,
    TimeOffViewSet, TrainingViewSet, PerformanceViewSet, PayrollViewSet
)

router = DefaultRouter()

# Customer App
router.register(r'customer/profile', CustomerProfileViewSet, basename='customer-profile')
router.register(r'customer/loyalty', LoyaltyViewSet, basename='loyalty')
router.register(r'customer/offers', OffersViewSet, basename='offers')
router.register(r'customer/orders', CustomerOrderViewSet, basename='customer-orders')
router.register(r'customer/reviews', ProductReviewViewSet, basename='reviews')
router.register(r'customer/recipes', RecipeViewSet, basename='recipes')
router.register(r'customer/navigation', StoreNavigationViewSet, basename='navigation')
router.register(r'customer/referrals', ReferralViewSet, basename='referrals')

# AI Features
router.register(r'ai/chat', ChatbotViewSet, basename='chatbot')
router.register(r'ai/vision', VisualRecognitionViewSet, basename='vision')

# Staff Management
router.register(r'staff/profiles', StaffProfileViewSet, basename='staff-profiles')
router.register(r'staff/shifts', ShiftViewSet, basename='shifts')
router.register(r'staff/time', TimeTrackingViewSet, basename='time-tracking')
router.register(r'staff/time-off', TimeOffViewSet, basename='time-off')
router.register(r'staff/training', TrainingViewSet, basename='training')
router.register(r'staff/performance', PerformanceViewSet, basename='performance')
router.register(r'staff/payroll', PayrollViewSet, basename='payroll')

urlpatterns = [
    path('', include(router.urls)),
    path('ai/quick-search/', quick_search, name='quick-search'),
]
