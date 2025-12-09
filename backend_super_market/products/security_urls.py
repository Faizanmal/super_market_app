"""
URL patterns for security-related API endpoints.
"""
from django.urls import path
from . import security_views

urlpatterns = [
    # Security role management
    path('security/roles/', security_views.security_roles_view, name='security_roles'),
    path('security/roles/<int:role_id>/', security_views.security_role_detail_view, name='security_role_detail'),
    
    # User role management
    path('security/user-roles/', security_views.user_roles_view, name='user_roles'),
    
    # Audit logging
    path('security/audit-logs/', security_views.security_audit_logs_view, name='security_audit_logs'),
    
    # Security dashboard
    path('security/dashboard/', security_views.security_dashboard_view, name='security_dashboard'),
    
    # System initialization
    path('security/initialize/', security_views.initialize_security_system_view, name='initialize_security'),
    
    # Permission checking
    path('security/permissions/', security_views.check_permissions_view, name='check_permissions'),
]