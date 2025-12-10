"""
Service Layer - Business logic services for complex operations.
Provides a clean separation between views and data access.
"""
import logging
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional, Type
from django.db import transaction
from django.db.models import Model, QuerySet
from .exceptions import ResourceNotFoundError, ValidationError

logger = logging.getLogger(__name__)


class BaseService(ABC):
    """
    Abstract base service class.
    Provides common CRUD operations and business logic patterns.
    """
    
    model: Type[Model] = None
    
    def __init__(self, user=None):
        self.user = user
    
    def get_queryset(self) -> QuerySet:
        """Get the base queryset. Override for custom filtering."""
        if self.model is None:
            raise NotImplementedError("Model class must be defined")
        return self.model.objects.all()
    
    def get_by_id(self, id: Any) -> Model:
        """Get a single record by ID."""
        try:
            return self.get_queryset().get(pk=id)
        except self.model.DoesNotExist:
            raise ResourceNotFoundError(f"{self.model.__name__} with ID {id} not found")
    
    def get_by_ids(self, ids: List[Any]) -> QuerySet:
        """Get multiple records by IDs."""
        return self.get_queryset().filter(pk__in=ids)
    
    def list(self, filters: Dict = None, ordering: str = None) -> QuerySet:
        """List records with optional filtering and ordering."""
        queryset = self.get_queryset()
        
        if filters:
            queryset = queryset.filter(**filters)
        
        if ordering:
            queryset = queryset.order_by(ordering)
        
        return queryset
    
    @transaction.atomic
    def create(self, data: Dict) -> Model:
        """Create a new record."""
        self._validate_create(data)
        self._pre_create(data)
        
        instance = self.model(**data)
        instance.full_clean()
        instance.save()
        
        self._post_create(instance)
        return instance
    
    @transaction.atomic
    def update(self, id: Any, data: Dict) -> Model:
        """Update an existing record."""
        instance = self.get_by_id(id)
        self._validate_update(instance, data)
        self._pre_update(instance, data)
        
        for key, value in data.items():
            setattr(instance, key, value)
        
        instance.full_clean()
        instance.save()
        
        self._post_update(instance)
        return instance
    
    @transaction.atomic
    def delete(self, id: Any, soft: bool = True) -> bool:
        """Delete a record (soft or hard delete)."""
        instance = self.get_by_id(id)
        self._pre_delete(instance)
        
        if soft and hasattr(instance, 'soft_delete'):
            instance.soft_delete(user=self.user)
        else:
            instance.delete()
        
        self._post_delete(instance)
        return True
    
    @transaction.atomic
    def bulk_create(self, data_list: List[Dict]) -> List[Model]:
        """Create multiple records at once."""
        instances = []
        for data in data_list:
            self._validate_create(data)
            instances.append(self.model(**data))
        
        return self.model.objects.bulk_create(instances)
    
    @transaction.atomic
    def bulk_update(self, updates: List[Dict], fields: List[str]) -> int:
        """Update multiple records at once."""
        instances = []
        for update in updates:
            pk = update.pop('id')
            try:
                instance = self.get_by_id(pk)
                for key, value in update.items():
                    if key in fields:
                        setattr(instance, key, value)
                instances.append(instance)
            except ResourceNotFoundError:
                continue
        
        return self.model.objects.bulk_update(instances, fields)
    
    # Validation hooks
    def _validate_create(self, data: Dict):
        """Validate data before create. Override for custom validation."""
        pass
    
    def _validate_update(self, instance: Model, data: Dict):
        """Validate data before update. Override for custom validation."""
        pass
    
    # Lifecycle hooks
    def _pre_create(self, data: Dict):
        """Hook called before create."""
        if self.user and hasattr(self.model, 'created_by'):
            data['created_by'] = self.user
    
    def _post_create(self, instance: Model):
        """Hook called after create."""
        pass
    
    def _pre_update(self, instance: Model, data: Dict):
        """Hook called before update."""
        if self.user and hasattr(self.model, 'updated_by'):
            data['updated_by'] = self.user
    
    def _post_update(self, instance: Model):
        """Hook called after update."""
        pass
    
    def _pre_delete(self, instance: Model):
        """Hook called before delete."""
        pass
    
    def _post_delete(self, instance: Model):
        """Hook called after delete."""
        pass


class ServiceResult:
    """Wrapper for service operation results."""
    
    def __init__(
        self,
        success: bool,
        data: Any = None,
        message: str = None,
        errors: Dict = None
    ):
        self.success = success
        self.data = data
        self.message = message
        self.errors = errors or {}
    
    @classmethod
    def ok(cls, data: Any = None, message: str = None):
        """Create a successful result."""
        return cls(success=True, data=data, message=message)
    
    @classmethod
    def fail(cls, message: str, errors: Dict = None):
        """Create a failed result."""
        return cls(success=False, message=message, errors=errors)
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for API response."""
        result = {'success': self.success}
        if self.message:
            result['message'] = self.message
        if self.data is not None:
            result['data'] = self.data
        if self.errors:
            result['errors'] = self.errors
        return result


class EventDispatcher:
    """Simple event dispatcher for service events."""
    
    _listeners = {}
    
    @classmethod
    def register(cls, event_name: str, callback):
        """Register an event listener."""
        if event_name not in cls._listeners:
            cls._listeners[event_name] = []
        cls._listeners[event_name].append(callback)
    
    @classmethod
    def dispatch(cls, event_name: str, *args, **kwargs):
        """Dispatch an event to all registered listeners."""
        listeners = cls._listeners.get(event_name, [])
        for callback in listeners:
            try:
                callback(*args, **kwargs)
            except Exception as e:
                logger.error(f"Error in event listener for {event_name}: {e}")
    
    @classmethod
    def clear(cls, event_name: str = None):
        """Clear event listeners."""
        if event_name:
            cls._listeners.pop(event_name, None)
        else:
            cls._listeners = {}


# Common events
class Events:
    """Event name constants."""
    PRODUCT_CREATED = 'product.created'
    PRODUCT_UPDATED = 'product.updated'
    PRODUCT_DELETED = 'product.deleted'
    PRODUCT_LOW_STOCK = 'product.low_stock'
    PRODUCT_EXPIRING = 'product.expiring'
    
    ORDER_CREATED = 'order.created'
    ORDER_UPDATED = 'order.updated'
    ORDER_RECEIVED = 'order.received'
    
    STOCK_MOVEMENT = 'stock.movement'
    STORE_TRANSFER = 'store.transfer'
    
    USER_REGISTERED = 'user.registered'
    USER_LOGIN = 'user.login'
