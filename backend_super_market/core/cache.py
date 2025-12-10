"""
Cache Manager - Intelligent caching system for performance optimization.
Provides cached data access patterns and cache invalidation strategies.
"""
import hashlib
import json
import logging
from functools import wraps
from typing import Any, Callable, Optional, Union
from django.core.cache import cache
from django.conf import settings

logger = logging.getLogger(__name__)


# Cache timeout constants (in seconds)
CACHE_SHORT = 60  # 1 minute
CACHE_MEDIUM = 300  # 5 minutes
CACHE_LONG = 900  # 15 minutes
CACHE_HOUR = 3600  # 1 hour
CACHE_DAY = 86400  # 24 hours


class CacheKeyBuilder:
    """Builder for consistent cache key generation."""
    
    PREFIX = 'supermart'
    
    @classmethod
    def build(cls, *args) -> str:
        """Build a cache key from components."""
        key_parts = [cls.PREFIX] + [str(arg) for arg in args]
        return ':'.join(key_parts)
    
    @classmethod
    def user_key(cls, user_id: int, resource: str) -> str:
        """Build a user-specific cache key."""
        return cls.build('user', user_id, resource)
    
    @classmethod
    def store_key(cls, store_id: int, resource: str) -> str:
        """Build a store-specific cache key."""
        return cls.build('store', store_id, resource)
    
    @classmethod
    def product_key(cls, product_id: int, field: str = None) -> str:
        """Build a product-specific cache key."""
        if field:
            return cls.build('product', product_id, field)
        return cls.build('product', product_id)
    
    @classmethod
    def list_key(cls, model: str, filters: dict = None) -> str:
        """Build a list cache key with optional filters."""
        if filters:
            filter_hash = hashlib.md5(json.dumps(filters, sort_keys=True).encode()).hexdigest()[:8]
            return cls.build('list', model, filter_hash)
        return cls.build('list', model)
    
    @classmethod
    def analytics_key(cls, report_type: str, params: dict = None) -> str:
        """Build an analytics cache key."""
        if params:
            param_hash = hashlib.md5(json.dumps(params, sort_keys=True).encode()).hexdigest()[:8]
            return cls.build('analytics', report_type, param_hash)
        return cls.build('analytics', report_type)


class CacheManager:
    """Central cache management with intelligent invalidation."""
    
    def __init__(self):
        self.key_builder = CacheKeyBuilder
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get a value from cache."""
        try:
            return cache.get(key, default)
        except Exception as e:
            logger.error(f"Cache get error for key {key}: {e}")
            return default
    
    def set(self, key: str, value: Any, timeout: int = CACHE_MEDIUM) -> bool:
        """Set a value in cache."""
        try:
            cache.set(key, value, timeout)
            return True
        except Exception as e:
            logger.error(f"Cache set error for key {key}: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """Delete a value from cache."""
        try:
            cache.delete(key)
            return True
        except Exception as e:
            logger.error(f"Cache delete error for key {key}: {e}")
            return False
    
    def delete_pattern(self, pattern: str) -> int:
        """Delete all keys matching a pattern."""
        # Note: This requires a cache backend that supports key patterns (like Redis)
        try:
            if hasattr(cache, 'delete_pattern'):
                return cache.delete_pattern(pattern)
            return 0
        except Exception as e:
            logger.error(f"Cache delete pattern error for {pattern}: {e}")
            return 0
    
    def get_or_set(self, key: str, default_func: Callable, timeout: int = CACHE_MEDIUM) -> Any:
        """Get a value from cache, or set it if not present."""
        value = self.get(key)
        if value is None:
            value = default_func()
            self.set(key, value, timeout)
        return value
    
    def invalidate_product(self, product_id: int):
        """Invalidate all cache entries related to a product."""
        patterns = [
            self.key_builder.product_key(product_id),
            self.key_builder.build('list', 'product', '*'),
            self.key_builder.build('analytics', 'inventory', '*'),
        ]
        for pattern in patterns:
            self.delete_pattern(pattern)
    
    def invalidate_store(self, store_id: int):
        """Invalidate all cache entries related to a store."""
        patterns = [
            self.key_builder.store_key(store_id, '*'),
            self.key_builder.build('list', 'store', '*'),
        ]
        for pattern in patterns:
            self.delete_pattern(pattern)
    
    def invalidate_user_data(self, user_id: int):
        """Invalidate all cache entries for a user."""
        pattern = self.key_builder.user_key(user_id, '*')
        self.delete_pattern(pattern)
    
    def invalidate_analytics(self):
        """Invalidate all analytics cache."""
        pattern = self.key_builder.build('analytics', '*')
        self.delete_pattern(pattern)
    
    def clear_all(self):
        """Clear all cache entries (use with caution)."""
        try:
            cache.clear()
            logger.info("All cache cleared")
            return True
        except Exception as e:
            logger.error(f"Cache clear error: {e}")
            return False


# Global cache manager instance
cache_manager = CacheManager()


def cached(timeout: int = CACHE_MEDIUM, key_prefix: str = None):
    """
    Decorator for caching function results.
    
    Usage:
        @cached(timeout=300, key_prefix='my_function')
        def my_expensive_function(arg1, arg2):
            ...
    """
    def decorator(func: Callable):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Build cache key
            key_parts = [key_prefix or func.__name__]
            key_parts.extend(str(arg) for arg in args)
            key_parts.extend(f"{k}={v}" for k, v in sorted(kwargs.items()))
            cache_key = CacheKeyBuilder.build(*key_parts)
            
            # Try to get from cache
            result = cache_manager.get(cache_key)
            if result is not None:
                return result
            
            # Execute function and cache result
            result = func(*args, **kwargs)
            cache_manager.set(cache_key, result, timeout)
            return result
        
        return wrapper
    return decorator


def cached_property_ttl(timeout: int = CACHE_MEDIUM):
    """
    Decorator for caching instance properties with TTL.
    
    Usage:
        class MyModel:
            @cached_property_ttl(timeout=300)
            def expensive_property(self):
                ...
    """
    def decorator(func: Callable):
        @wraps(func)
        def wrapper(self):
            cache_key = CacheKeyBuilder.build(
                self.__class__.__name__,
                getattr(self, 'pk', getattr(self, 'id', id(self))),
                func.__name__
            )
            
            result = cache_manager.get(cache_key)
            if result is not None:
                return result
            
            result = func(self)
            cache_manager.set(cache_key, result, timeout)
            return result
        
        return property(wrapper)
    return decorator


class QuerysetCache:
    """Helper class for caching queryset results."""
    
    @staticmethod
    def get_or_fetch(
        key: str,
        queryset,
        timeout: int = CACHE_MEDIUM,
        serialize: bool = True
    ) -> list:
        """Get cached queryset results or fetch and cache them."""
        cached_data = cache_manager.get(key)
        if cached_data is not None:
            return cached_data
        
        if serialize:
            # Evaluate queryset to list of dicts
            data = list(queryset.values())
        else:
            # Just evaluate to list
            data = list(queryset)
        
        cache_manager.set(key, data, timeout)
        return data
    
    @staticmethod
    def invalidate_model(model_name: str):
        """Invalidate all cached queries for a model."""
        pattern = CacheKeyBuilder.build('list', model_name.lower(), '*')
        cache_manager.delete_pattern(pattern)
