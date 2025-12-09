"""
Admin configuration for accounts app.
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _

from .models import User

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Custom admin for User model with role-based fields."""
    
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        (_('Personal info'), {'fields': ('first_name', 'last_name', 'phone_number', 
                                         'company_name', 'address', 'profile_picture', 
                                         'date_of_birth')}),
        (_('Role & Store'), {'fields': ('role', 'store', 'employee_id')}),
        (_('Permissions'), {'fields': ('can_receive_stock', 'can_audit', 'can_manage_staff', 
                                       'can_view_analytics', 'is_active', 'is_staff', 
                                       'is_superuser', 'groups', 'user_permissions')}),
        (_('Important dates'), {'fields': ('last_login', 'created_at', 'updated_at')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2', 'first_name', 'last_name', 'role', 'store'),
        }),
    )
    
    list_display = ('email', 'get_full_name', 'role', 'store', 'is_staff', 'is_active', 'created_at')
    list_filter = ('role', 'is_staff', 'is_superuser', 'is_active', 'store', 'created_at')
    search_fields = ('email', 'first_name', 'last_name', 'employee_id', 'company_name')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at', 'last_login')
