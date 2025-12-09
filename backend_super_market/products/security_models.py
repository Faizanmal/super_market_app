"""
Enhanced security features including role-based access control and data encryption.
"""
import secrets
import base64
import logging
from datetime import timedelta
from cryptography.fernet import Fernet
from django.contrib.auth import get_user_model
from django.conf import settings
from django.utils import timezone
from django.db import models
import json
import bcrypt

logger = logging.getLogger(__name__)


class SecurityRole(models.Model):
    """
    Custom security roles for fine-grained access control.
    """
    ROLE_LEVELS = [
        ('owner', 'Store Owner'),
        ('manager', 'Store Manager'),
        ('supervisor', 'Supervisor'),
        ('employee', 'Employee'),
        ('viewer', 'Read-Only Viewer'),
    ]
    
    name = models.CharField(max_length=100, unique=True)
    level = models.CharField(max_length=20, choices=ROLE_LEVELS)
    description = models.TextField(blank=True)
    
    # Permissions
    can_create_products = models.BooleanField(default=False)
    can_edit_products = models.BooleanField(default=False)
    can_delete_products = models.BooleanField(default=False)
    can_view_products = models.BooleanField(default=True)
    
    can_manage_inventory = models.BooleanField(default=False)
    can_view_analytics = models.BooleanField(default=False)
    can_export_data = models.BooleanField(default=False)
    
    can_manage_users = models.BooleanField(default=False)
    can_view_reports = models.BooleanField(default=False)
    can_manage_settings = models.BooleanField(default=False)
    
    can_access_financial_data = models.BooleanField(default=False)
    can_manage_suppliers = models.BooleanField(default=False)
    can_approve_purchases = models.BooleanField(default=False)
    
    # Advanced permissions
    can_use_ml_features = models.BooleanField(default=False)
    can_access_raw_data = models.BooleanField(default=False)
    can_modify_security = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['level', 'name']
    
    def __str__(self):
        return f"{self.name} ({self.get_level_display()})"
    
    @classmethod
    def get_default_roles(cls):
        """Create default security roles."""
        defaults = {
            'owner': {
                'name': 'Store Owner',
                'level': 'owner',
                'description': 'Full access to all features and data',
                'permissions': {
                    'can_create_products': True,
                    'can_edit_products': True,
                    'can_delete_products': True,
                    'can_view_products': True,
                    'can_manage_inventory': True,
                    'can_view_analytics': True,
                    'can_export_data': True,
                    'can_manage_users': True,
                    'can_view_reports': True,
                    'can_manage_settings': True,
                    'can_access_financial_data': True,
                    'can_manage_suppliers': True,
                    'can_approve_purchases': True,
                    'can_use_ml_features': True,
                    'can_access_raw_data': True,
                    'can_modify_security': True,
                }
            },
            'manager': {
                'name': 'Store Manager',
                'level': 'manager',
                'description': 'Manage inventory, view analytics, and supervise operations',
                'permissions': {
                    'can_create_products': True,
                    'can_edit_products': True,
                    'can_delete_products': False,
                    'can_view_products': True,
                    'can_manage_inventory': True,
                    'can_view_analytics': True,
                    'can_export_data': True,
                    'can_manage_users': False,
                    'can_view_reports': True,
                    'can_manage_settings': False,
                    'can_access_financial_data': True,
                    'can_manage_suppliers': True,
                    'can_approve_purchases': True,
                    'can_use_ml_features': True,
                    'can_access_raw_data': False,
                    'can_modify_security': False,
                }
            },
            'employee': {
                'name': 'Employee',
                'level': 'employee',
                'description': 'Basic inventory management and product operations',
                'permissions': {
                    'can_create_products': True,
                    'can_edit_products': True,
                    'can_delete_products': False,
                    'can_view_products': True,
                    'can_manage_inventory': True,
                    'can_view_analytics': False,
                    'can_export_data': False,
                    'can_manage_users': False,
                    'can_view_reports': False,
                    'can_manage_settings': False,
                    'can_access_financial_data': False,
                    'can_manage_suppliers': False,
                    'can_approve_purchases': False,
                    'can_use_ml_features': False,
                    'can_access_raw_data': False,
                    'can_modify_security': False,
                }
            },
            'viewer': {
                'name': 'Viewer',
                'level': 'viewer',
                'description': 'Read-only access to basic information',
                'permissions': {
                    'can_create_products': False,
                    'can_edit_products': False,
                    'can_delete_products': False,
                    'can_view_products': True,
                    'can_manage_inventory': False,
                    'can_view_analytics': False,
                    'can_export_data': False,
                    'can_manage_users': False,
                    'can_view_reports': False,
                    'can_manage_settings': False,
                    'can_access_financial_data': False,
                    'can_manage_suppliers': False,
                    'can_approve_purchases': False,
                    'can_use_ml_features': False,
                    'can_access_raw_data': False,
                    'can_modify_security': False,
                }
            }
        }
        
        return defaults


class UserProfile(models.Model):
    """
    Extended user profile with security features.
    """
    user = models.OneToOneField(get_user_model(), on_delete=models.CASCADE, related_name='security_profile')
    security_role = models.ForeignKey(SecurityRole, on_delete=models.PROTECT, null=True, blank=True)
    
    # Security settings
    two_factor_enabled = models.BooleanField(default=False)
    two_factor_secret = models.CharField(max_length=32, blank=True)
    backup_codes = models.JSONField(default=list, blank=True)
    
    # Login security
    failed_login_attempts = models.IntegerField(default=0)
    locked_until = models.DateTimeField(null=True, blank=True)
    last_successful_login = models.DateTimeField(null=True, blank=True)
    last_failed_login = models.DateTimeField(null=True, blank=True)
    
    # Session security
    force_logout_all_sessions = models.BooleanField(default=False)
    session_timeout_minutes = models.IntegerField(default=480)  # 8 hours
    
    # Data access logging
    last_data_export = models.DateTimeField(null=True, blank=True)
    data_access_count = models.IntegerField(default=0)
    
    # Additional security fields
    password_changed_at = models.DateTimeField(auto_now_add=True)
    must_change_password = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def is_account_locked(self):
        """Check if account is currently locked."""
        if self.locked_until and self.locked_until > timezone.now():
            return True
        return False
    
    def increment_failed_login(self):
        """Increment failed login attempts and lock if necessary."""
        self.failed_login_attempts += 1
        self.last_failed_login = timezone.now()
        
        # Lock account after 5 failed attempts
        if self.failed_login_attempts >= 5:
            self.locked_until = timezone.now() + timedelta(minutes=30)
        
        self.save()
    
    def reset_failed_logins(self):
        """Reset failed login counter."""
        self.failed_login_attempts = 0
        self.locked_until = None
        self.last_successful_login = timezone.now()
        self.save()


class SecurityAuditLog(models.Model):
    """
    Comprehensive audit logging for security events.
    """
    EVENT_TYPES = [
        ('login', 'User Login'),
        ('logout', 'User Logout'),
        ('failed_login', 'Failed Login Attempt'),
        ('password_change', 'Password Changed'),
        ('role_change', 'Role Modified'),
        ('data_access', 'Data Accessed'),
        ('data_export', 'Data Exported'),
        ('permission_denied', 'Permission Denied'),
        ('security_violation', 'Security Violation'),
        ('admin_action', 'Administrative Action'),
        ('api_access', 'API Access'),
        ('suspicious_activity', 'Suspicious Activity'),
    ]
    
    RISK_LEVELS = [
        ('low', 'Low Risk'),
        ('medium', 'Medium Risk'),
        ('high', 'High Risk'),
        ('critical', 'Critical Risk'),
    ]
    
    user = models.ForeignKey(get_user_model(), on_delete=models.SET_NULL, null=True, blank=True)
    event_type = models.CharField(max_length=20, choices=EVENT_TYPES)
    risk_level = models.CharField(max_length=10, choices=RISK_LEVELS, default='low')
    
    description = models.TextField()
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    # Request details
    endpoint = models.CharField(max_length=200, blank=True)
    method = models.CharField(max_length=10, blank=True)
    response_code = models.IntegerField(null=True, blank=True)
    
    # Additional context
    context_data = models.JSONField(default=dict, blank=True)
    
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['user', 'timestamp']),
            models.Index(fields=['event_type', 'timestamp']),
            models.Index(fields=['risk_level', 'timestamp']),
        ]
    
    def __str__(self):
        return f"{self.event_type} - {self.user} - {self.timestamp}"


class DataEncryptionService:
    """
    Service for encrypting and decrypting sensitive data.
    """
    
    def __init__(self):
        self.encryption_key = self._get_or_create_key()
        self.cipher = Fernet(self.encryption_key)
    
    def _get_or_create_key(self) -> bytes:
        """Get existing encryption key or create a new one."""
        key_setting = getattr(settings, 'DATA_ENCRYPTION_KEY', None)
        
        if key_setting:
            return base64.urlsafe_b64decode(key_setting.encode())
        
        # Generate new key
        key = Fernet.generate_key()
        logger.warning(f"Generated new encryption key. Add this to settings: DATA_ENCRYPTION_KEY = '{key.decode()}'")
        return key
    
    def encrypt_string(self, plaintext: str) -> str:
        """Encrypt a string."""
        try:
            encrypted = self.cipher.encrypt(plaintext.encode())
            return base64.urlsafe_b64encode(encrypted).decode()
        except Exception as e:
            logger.error(f"Encryption failed: {e}")
            raise
    
    def decrypt_string(self, encrypted_text: str) -> str:
        """Decrypt a string."""
        try:
            encrypted_bytes = base64.urlsafe_b64decode(encrypted_text.encode())
            decrypted = self.cipher.decrypt(encrypted_bytes)
            return decrypted.decode()
        except Exception as e:
            logger.error(f"Decryption failed: {e}")
            raise
    
    def encrypt_dict(self, data: dict) -> str:
        """Encrypt a dictionary."""
        try:
            json_string = json.dumps(data)
            return self.encrypt_string(json_string)
        except Exception as e:
            logger.error(f"Dictionary encryption failed: {e}")
            raise
    
    def decrypt_dict(self, encrypted_text: str) -> dict:
        """Decrypt a dictionary."""
        try:
            json_string = self.decrypt_string(encrypted_text)
            return json.loads(json_string)
        except Exception as e:
            logger.error(f"Dictionary decryption failed: {e}")
            raise


class SecurityManager:
    """
    Central security management service.
    """
    
    def __init__(self):
        self.encryption_service = DataEncryptionService()
        self.audit_logger = AuditLogger()
    
    def check_permission(self, user, permission_name: str) -> bool:
        """Check if user has specific permission."""
        try:
            if user.is_superuser:
                return True
            
            # Get user's security role
            profile = getattr(user, 'security_profile', None)
            if not profile or not profile.security_role:
                return False
            
            # Check permission
            return getattr(profile.security_role, permission_name, False)
            
        except Exception as e:
            logger.error(f"Permission check failed: {e}")
            return False
    
    def log_security_event(self, user, event_type: str, description: str, 
                          request=None, risk_level: str = 'low', **kwargs):
        """Log security event."""
        try:
            log_entry = SecurityAuditLog.objects.create(
                user=user,
                event_type=event_type,
                risk_level=risk_level,
                description=description,
                ip_address=self._get_client_ip(request) if request else None,
                user_agent=request.META.get('HTTP_USER_AGENT', '') if request else '',
                endpoint=request.path if request else '',
                method=request.method if request else '',
                context_data=kwargs
            )
            
            # Alert on high-risk events
            if risk_level in ['high', 'critical']:
                self._alert_security_team(log_entry)
                
        except Exception as e:
            logger.error(f"Security event logging failed: {e}")
    
    def _get_client_ip(self, request) -> str:
        """Get client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0]
        return request.META.get('REMOTE_ADDR', '')
    
    def _alert_security_team(self, log_entry):
        """Alert security team about high-risk events."""
        # In production, this would send emails/notifications
        logger.warning(f"High-risk security event: {log_entry.description}")
    
    def validate_session(self, user) -> bool:
        """Validate user session security."""
        try:
            profile = getattr(user, 'security_profile', None)
            if not profile:
                return True
            
            # Check if account is locked
            if profile.is_account_locked():
                return False
            
            # Check session timeout
            if profile.session_timeout_minutes > 0:
                # This would be implemented with session middleware
                pass
            
            return True
            
        except Exception as e:
            logger.error(f"Session validation failed: {e}")
            return False
    
    def generate_secure_token(self, length: int = 32) -> str:
        """Generate cryptographically secure token."""
        return secrets.token_urlsafe(length)
    
    def hash_password(self, password: str) -> str:
        """Hash password using bcrypt."""
        salt = bcrypt.gensalt()
        return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
    
    def verify_password(self, password: str, hashed: str) -> bool:
        """Verify password against hash."""
        return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
    
    def encrypt_sensitive_data(self, data: any) -> str:
        """Encrypt sensitive data."""
        if isinstance(data, dict):
            return self.encryption_service.encrypt_dict(data)
        else:
            return self.encryption_service.encrypt_string(str(data))
    
    def decrypt_sensitive_data(self, encrypted_data: str, return_type: type = str):
        """Decrypt sensitive data."""
        if return_type is dict:
            return self.encryption_service.decrypt_dict(encrypted_data)
        else:
            return self.encryption_service.decrypt_string(encrypted_data)


class AuditLogger:
    """
    Specialized audit logging service.
    """
    
    def log_data_access(self, user, resource: str, action: str, **kwargs):
        """Log data access events."""
        SecurityAuditLog.objects.create(
            user=user,
            event_type='data_access',
            description=f"Accessed {resource} - {action}",
            risk_level='low',
            context_data={
                'resource': resource,
                'action': action,
                **kwargs
            }
        )
    
    def log_admin_action(self, user, action: str, target=None, **kwargs):
        """Log administrative actions."""
        description = f"Admin action: {action}"
        if target:
            description += f" on {target}"
        
        SecurityAuditLog.objects.create(
            user=user,
            event_type='admin_action',
            description=description,
            risk_level='medium',
            context_data={
                'action': action,
                'target': str(target) if target else None,
                **kwargs
            }
        )
    
    def log_permission_denied(self, user, resource: str, permission: str, **kwargs):
        """Log permission denied events."""
        SecurityAuditLog.objects.create(
            user=user,
            event_type='permission_denied',
            description=f"Permission denied: {permission} on {resource}",
            risk_level='medium',
            context_data={
                'resource': resource,
                'permission': permission,
                **kwargs
            }
        )


# Global security manager instance
security_manager = SecurityManager()