"""
Django admin configuration for security models.
"""
from django.contrib import admin
from django.contrib.auth import get_user_model
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .security_models import SecurityRole, UserProfile, SecurityAuditLog

User = get_user_model()


@admin.register(SecurityRole)
class SecurityRoleAdmin(admin.ModelAdmin):
    list_display = ['name', 'level', 'description', 'created_at']
    list_filter = ['level', 'created_at']
    search_fields = ['name', 'description']
    ordering = ['level', 'name']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'level', 'description')
        }),
        ('Product Permissions', {
            'fields': ('can_create_products', 'can_edit_products', 'can_delete_products', 'can_view_products')
        }),
        ('Inventory & Analytics', {
            'fields': ('can_manage_inventory', 'can_view_analytics', 'can_export_data')
        }),
        ('User & System Management', {
            'fields': ('can_manage_users', 'can_view_reports', 'can_manage_settings')
        }),
        ('Financial & Operations', {
            'fields': ('can_access_financial_data', 'can_manage_suppliers', 'can_approve_purchases')
        }),
        ('Advanced Features', {
            'fields': ('can_use_ml_features', 'can_access_raw_data', 'can_modify_security')
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'security_role', 'two_factor_enabled', 'failed_login_attempts', 'last_successful_login']
    list_filter = ['security_role', 'two_factor_enabled', 'must_change_password', 'created_at']
    search_fields = ['user__username', 'user__email', 'user__first_name', 'user__last_name']
    ordering = ['user__username']
    
    fieldsets = (
        ('User Information', {
            'fields': ('user', 'security_role')
        }),
        ('Security Settings', {
            'fields': ('two_factor_enabled', 'session_timeout_minutes', 'must_change_password')
        }),
        ('Login Security', {
            'fields': ('failed_login_attempts', 'locked_until', 'last_successful_login', 'last_failed_login')
        }),
        ('Data Access', {
            'fields': ('last_data_export', 'data_access_count')
        }),
        ('System Information', {
            'fields': ('password_changed_at', 'created_at', 'updated_at')
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at', 'password_changed_at', 'last_successful_login', 'last_failed_login']


@admin.register(SecurityAuditLog)
class SecurityAuditLogAdmin(admin.ModelAdmin):
    list_display = ['timestamp', 'user', 'event_type', 'risk_level', 'description', 'ip_address']
    list_filter = ['event_type', 'risk_level', 'timestamp']
    search_fields = ['user__username', 'description', 'ip_address', 'endpoint']
    ordering = ['-timestamp']
    date_hierarchy = 'timestamp'
    
    fieldsets = (
        ('Event Information', {
            'fields': ('user', 'event_type', 'risk_level', 'description', 'timestamp')
        }),
        ('Request Details', {
            'fields': ('ip_address', 'user_agent', 'endpoint', 'method', 'response_code')
        }),
        ('Context Data', {
            'fields': ('context_data',)
        }),
    )
    
    readonly_fields = ['timestamp']
    
    def has_add_permission(self, request):
        """Prevent manual creation of audit logs."""
        return False
    
    def has_change_permission(self, request, obj=None):
        """Prevent modification of audit logs."""
        return False


# Extend the default User admin to show security information
class SecurityUserInline(admin.StackedInline):
    model = UserProfile
    can_delete = False
    verbose_name_plural = 'Security Profile'
    
    fields = ['security_role', 'two_factor_enabled', 'session_timeout_minutes', 'failed_login_attempts']
    readonly_fields = ['failed_login_attempts']


class UserAdmin(BaseUserAdmin):
    ordering = ('email',)
    inlines = (SecurityUserInline,)
    
    def get_inline_instances(self, request, obj=None):
        if not obj:
            return list()
        return super().get_inline_instances(request, obj)


# Re-register User admin with security inline
admin.site.unregister(User)
admin.site.register(User, UserAdmin)