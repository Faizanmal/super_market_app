"""
URL patterns for authentication endpoints.
"""
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    CustomTokenObtainPairView,
    UserRegistrationView,
    UserProfileView,
    ChangePasswordView,
    LogoutView,
    user_stats,
    GoogleAuthView,
    GoogleAuthCallbackView,
)
 
app_name = 'accounts'

urlpatterns = [
    # Authentication
    path('login/', CustomTokenObtainPairView.as_view(), name='login'),
    path('register/', UserRegistrationView.as_view(), name='register'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Google OAuth (placeholder - requires proper OAuth setup)
    path('google/', GoogleAuthView.as_view(), name='google_auth'),
    path('google/callback/', GoogleAuthCallbackView.as_view(), name='google_callback'),
    
    # User Profile
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('stats/', user_stats, name='user_stats'),
]
