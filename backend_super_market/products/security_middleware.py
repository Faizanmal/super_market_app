"""
Security middleware and decorators for enhanced protection.
"""
import json
import time
import logging
from functools import wraps
from django.http import JsonResponse
from django.core.cache import cache
from django.utils.deprecation import MiddlewareMixin
from django.contrib.auth import logout
from django.core.exceptions import PermissionDenied
from .security_models import security_manager

logger = logging.getLogger(__name__)


class SecurityMiddleware(MiddlewareMixin):
    """
    Comprehensive security middleware for request processing.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        super().__init__(get_response)
    
    def process_request(self, request):
        """Process incoming requests for security threats."""
        
        # Rate limiting
        if self._is_rate_limited(request):
            security_manager.log_security_event(
                user=getattr(request, 'user', None),
                event_type='security_violation',
                description='Rate limit exceeded',
                request=request,
                risk_level='medium'
            )
            return JsonResponse({
                'error': 'Rate limit exceeded. Please try again later.'
            }, status=429)
        
        # IP-based blocking
        if self._is_blocked_ip(request):
            security_manager.log_security_event(
                user=getattr(request, 'user', None),
                event_type='security_violation',
                description='Access from blocked IP',
                request=request,
                risk_level='high'
            )
            return JsonResponse({
                'error': 'Access denied.'
            }, status=403)
        
        # Session security validation
        if hasattr(request, 'user') and request.user.is_authenticated:
            if not security_manager.validate_session(request.user):
                logout(request)
                return JsonResponse({
                    'error': 'Session expired or invalid.'
                }, status=401)
        
        return None
    
    def process_response(self, request, response):
        """Process responses for security logging."""
        
        # Log suspicious activities
        if response.status_code >= 400:
            self._log_suspicious_activity(request, response)
        
        # Add security headers
        response = self._add_security_headers(response)
        
        return response
    
    def _is_rate_limited(self, request) -> bool:
        """Check if request is rate limited."""
        try:
            client_ip = self._get_client_ip(request)
            cache_key = f"rate_limit:{client_ip}"
            
            # Get current request count
            request_count = cache.get(cache_key, 0)
            
            # Limit: 100 requests per minute
            if request_count >= 100:
                return True
            
            # Increment counter
            cache.set(cache_key, request_count + 1, 60)
            return False
            
        except Exception as e:
            logger.error(f"Rate limiting error: {e}")
            return False
    
    def _is_blocked_ip(self, request) -> bool:
        """Check if IP is in blocklist."""
        try:
            client_ip = self._get_client_ip(request)
            
            # Check cache for blocked IPs
            blocked_ips = cache.get('blocked_ips', set())
            return client_ip in blocked_ips
            
        except Exception as e:
            logger.error(f"IP blocking error: {e}")
            return False
    
    def _log_suspicious_activity(self, request, response):
        """Log potentially suspicious activities."""
        try:
            # Log failed authentication attempts
            if response.status_code == 401:
                security_manager.log_security_event(
                    user=getattr(request, 'user', None),
                    event_type='failed_login',
                    description=f'Authentication failed for {request.path}',
                    request=request,
                    risk_level='medium'
                )
            
            # Log permission denials
            elif response.status_code == 403:
                security_manager.log_security_event(
                    user=getattr(request, 'user', None),
                    event_type='permission_denied',
                    description=f'Access denied to {request.path}',
                    request=request,
                    risk_level='medium'
                )
            
            # Log server errors (potential attacks)
            elif response.status_code >= 500:
                security_manager.log_security_event(
                    user=getattr(request, 'user', None),
                    event_type='suspicious_activity',
                    description=f'Server error on {request.path}',
                    request=request,
                    risk_level='high'
                )
                
        except Exception as e:
            logger.error(f"Suspicious activity logging error: {e}")
    
    def _add_security_headers(self, response):
        """Add security headers to response."""
        try:
            # Prevent clickjacking
            response['X-Frame-Options'] = 'DENY'
            
            # Prevent MIME type sniffing
            response['X-Content-Type-Options'] = 'nosniff'
            
            # Enable XSS protection
            response['X-XSS-Protection'] = '1; mode=block'
            
            # Force HTTPS in production
            response['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
            
            # Control referrer information
            response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
            
            # Content Security Policy
            response['Content-Security-Policy'] = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data: https:; "
                "connect-src 'self';"
            )
            
            return response
            
        except Exception as e:
            logger.error(f"Security headers error: {e}")
            return response
    
    def _get_client_ip(self, request) -> str:
        """Get client IP address."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '')


def require_permission(permission_name: str, raise_exception: bool = True):
    """
    Decorator to require specific permission for view access.
    
    Args:
        permission_name: Name of the permission to check
        raise_exception: Whether to raise exception or return 403
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            if not hasattr(request, 'user') or not request.user.is_authenticated:
                if raise_exception:
                    raise PermissionDenied("Authentication required")
                return JsonResponse({'error': 'Authentication required'}, status=401)
            
            if not security_manager.check_permission(request.user, permission_name):
                security_manager.log_security_event(
                    user=request.user,
                    event_type='permission_denied',
                    description=f'Permission denied: {permission_name}',
                    request=request,
                    risk_level='medium'
                )
                
                if raise_exception:
                    raise PermissionDenied(f"Permission required: {permission_name}")
                return JsonResponse({'error': f'Permission required: {permission_name}'}, status=403)
            
            # Log successful access
            security_manager.log_security_event(
                user=request.user,
                event_type='data_access',
                description=f'Accessed with permission: {permission_name}',
                request=request,
                risk_level='low'
            )
            
            return view_func(request, *args, **kwargs)
        return _wrapped_view
    return decorator


def require_role(required_role: str):
    """
    Decorator to require specific role for view access.
    
    Args:
        required_role: Required role level (owner, manager, employee, etc.)
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            if not hasattr(request, 'user') or not request.user.is_authenticated:
                return JsonResponse({'error': 'Authentication required'}, status=401)
            
            user_profile = getattr(request.user, 'security_profile', None)
            if not user_profile or not user_profile.security_role:
                return JsonResponse({'error': 'No role assigned'}, status=403)
            
            # Check role hierarchy
            role_hierarchy = ['viewer', 'employee', 'supervisor', 'manager', 'owner']
            user_level = role_hierarchy.index(user_profile.security_role.level)
            required_level = role_hierarchy.index(required_role)
            
            if user_level < required_level:
                security_manager.log_security_event(
                    user=request.user,
                    event_type='permission_denied',
                    description=f'Insufficient role: {user_profile.security_role.level} < {required_role}',
                    request=request,
                    risk_level='medium'
                )
                return JsonResponse({'error': 'Insufficient privileges'}, status=403)
            
            return view_func(request, *args, **kwargs)
        return _wrapped_view
    return decorator


def audit_access(resource_name: str, action: str):
    """
    Decorator to audit data access.
    
    Args:
        resource_name: Name of the resource being accessed
        action: Type of action (read, write, delete, etc.)
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            start_time = time.time()
            
            # Execute the view
            response = view_func(request, *args, **kwargs)
            
            # Log the access
            if hasattr(request, 'user') and request.user.is_authenticated:
                execution_time = time.time() - start_time
                
                security_manager.log_security_event(
                    user=request.user,
                    event_type='data_access',
                    description=f'{action.title()} access to {resource_name}',
                    request=request,
                    risk_level='low',
                    resource=resource_name,
                    action=action,
                    execution_time=execution_time,
                    response_code=getattr(response, 'status_code', None)
                )
            
            return response
        return _wrapped_view
    return decorator


def rate_limit(max_requests: int = 10, window_minutes: int = 1):
    """
    Decorator for view-specific rate limiting.
    
    Args:
        max_requests: Maximum requests allowed
        window_minutes: Time window in minutes
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            # Get user or IP identifier
            if hasattr(request, 'user') and request.user.is_authenticated:
                identifier = f"user:{request.user.id}"
            else:
                identifier = f"ip:{request.META.get('REMOTE_ADDR', '')}"
            
            cache_key = f"rate_limit:{view_func.__name__}:{identifier}"
            
            # Check current count
            current_count = cache.get(cache_key, 0)
            if current_count >= max_requests:
                security_manager.log_security_event(
                    user=getattr(request, 'user', None),
                    event_type='security_violation',
                    description=f'Rate limit exceeded for {view_func.__name__}',
                    request=request,
                    risk_level='medium'
                )
                return JsonResponse({
                    'error': 'Rate limit exceeded. Please try again later.'
                }, status=429)
            
            # Increment counter
            cache.set(cache_key, current_count + 1, window_minutes * 60)
            
            return view_func(request, *args, **kwargs)
        return _wrapped_view
    return decorator


def secure_data(encrypt_fields: list = None):
    """
    Decorator to automatically encrypt/decrypt sensitive fields in responses.
    
    Args:
        encrypt_fields: List of field names to encrypt in the response
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            response = view_func(request, *args, **kwargs)
            
            # Only process JSON responses
            if (hasattr(response, 'content_type') and 
                'application/json' in response.content_type and 
                encrypt_fields):
                
                try:
                    data = json.loads(response.content.decode())
                    
                    # Encrypt specified fields
                    def encrypt_recursive(obj, fields):
                        if isinstance(obj, dict):
                            for key, value in obj.items():
                                if key in fields and value is not None:
                                    obj[key] = security_manager.encrypt_sensitive_data(str(value))
                                elif isinstance(value, (dict, list)):
                                    encrypt_recursive(value, fields)
                        elif isinstance(obj, list):
                            for item in obj:
                                if isinstance(item, (dict, list)):
                                    encrypt_recursive(item, fields)
                    
                    encrypt_recursive(data, encrypt_fields)
                    
                    # Update response content
                    response.content = json.dumps(data).encode()
                    
                except Exception as e:
                    logger.error(f"Data encryption error: {e}")
            
            return response
        return _wrapped_view
    return decorator


class TwoFactorAuthMixin:
    """
    Mixin for adding two-factor authentication to views.
    """
    
    def verify_2fa_token(self, user, token: str) -> bool:
        """
        Verify two-factor authentication token.
        
        Args:
            user: User object
            token: 2FA token to verify
            
        Returns:
            bool: True if token is valid
        """
        try:
            profile = getattr(user, 'security_profile', None)
            if not profile or not profile.two_factor_enabled:
                return True  # 2FA not enabled
            
            # In a real implementation, this would verify TOTP tokens
            # using libraries like pyotp
            # For now, return True as placeholder
            return True
            
        except Exception as e:
            logger.error(f"2FA verification error: {e}")
            return False


def require_2fa(view_func):
    """
    Decorator to require two-factor authentication.
    """
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        if not hasattr(request, 'user') or not request.user.is_authenticated:
            return JsonResponse({'error': 'Authentication required'}, status=401)
        
        profile = getattr(request.user, 'security_profile', None)
        if profile and profile.two_factor_enabled:
            # Check for 2FA token in request
            token = request.META.get('HTTP_X_2FA_TOKEN') or request.GET.get('2fa_token')
            
            if not token:
                return JsonResponse({'error': '2FA token required'}, status=401)
            
            # Verify token (placeholder implementation)
            mixin = TwoFactorAuthMixin()
            if not mixin.verify_2fa_token(request.user, token):
                security_manager.log_security_event(
                    user=request.user,
                    event_type='failed_login',
                    description='Invalid 2FA token',
                    request=request,
                    risk_level='high'
                )
                return JsonResponse({'error': 'Invalid 2FA token'}, status=401)
        
        return view_func(request, *args, **kwargs)
    return _wrapped_view