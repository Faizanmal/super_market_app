"""
Custom Permission Classes - Role-based access control for the application.
Implements granular permissions based on user roles.
"""
from rest_framework import permissions


class BaseRolePermission(permissions.BasePermission):
    """Base class for role-based permissions."""
    
    allowed_roles = []
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Superusers always have permission
        if request.user.is_superuser:
            return True
        
        return request.user.role in self.allowed_roles


class IsStoreManager(BaseRolePermission):
    """Permission class for store managers."""
    allowed_roles = ['store_manager', 'head_office']
    message = "Only store managers can perform this action."


class IsStockReceiver(BaseRolePermission):
    """Permission class for stock receiving operations."""
    allowed_roles = ['stock_receiver', 'store_manager', 'head_office']
    message = "Only authorized staff can receive stock."


class IsShelfStaff(BaseRolePermission):
    """Permission class for shelf staff operations."""
    allowed_roles = ['shelf_staff', 'stock_receiver', 'auditor', 'store_manager', 'head_office']
    message = "Only shelf staff can perform this action."


class IsAuditor(BaseRolePermission):
    """Permission class for auditors and QA staff."""
    allowed_roles = ['auditor', 'store_manager', 'head_office']
    message = "Only auditors can perform this action."


class IsHeadOffice(BaseRolePermission):
    """Permission class for head office administration."""
    allowed_roles = ['head_office']
    message = "Only head office administrators can perform this action."


class CanViewAnalytics(permissions.BasePermission):
    """Permission to view analytics dashboard and reports."""
    message = "You don't have permission to view analytics."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        if request.user.is_superuser:
            return True
        
        return getattr(request.user, 'can_view_analytics', False)


class CanManageStaff(permissions.BasePermission):
    """Permission to manage team members."""
    message = "You don't have permission to manage staff."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        if request.user.is_superuser:
            return True
        
        return getattr(request.user, 'can_manage_staff', False)


class CanPerformAudit(permissions.BasePermission):
    """Permission to perform shelf audits."""
    message = "You don't have permission to perform audits."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        if request.user.is_superuser:
            return True
        
        return getattr(request.user, 'can_audit', False)


class CanReceiveStock(permissions.BasePermission):
    """Permission to receive stock at warehouse."""
    message = "You don't have permission to receive stock."
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        if request.user.is_superuser:
            return True
        
        return getattr(request.user, 'can_receive_stock', False)


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Object-level permission to only allow owners of an object to edit it.
    """
    
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed for any request
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions are only allowed to the owner
        owner_field = getattr(view, 'owner_field', 'created_by')
        return getattr(obj, owner_field, None) == request.user


class IsSameStoreOrAdmin(permissions.BasePermission):
    """
    Permission to access objects within the same store or for admins.
    """
    message = "You can only access resources from your assigned store."
    
    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or request.user.role == 'head_office':
            return True
        
        # Check if object has store field
        obj_store = getattr(obj, 'store', None)
        user_store = getattr(request.user, 'store', None)
        
        if obj_store is None or user_store is None:
            return True  # No store restriction
        
        return obj_store == user_store


class DynamicPermission(permissions.BasePermission):
    """
    Dynamic permission based on view action.
    Configure permissions per action in view class.
    """
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Get action-specific permissions from view
        action_permissions = getattr(view, 'action_permissions', {})
        action = getattr(view, 'action', None)
        
        if action and action in action_permissions:
            required_permission = action_permissions[action]
            return required_permission().has_permission(request, view)
        
        return True
