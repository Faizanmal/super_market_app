"""
View Mixins - Reusable view functionality for DRY code.
Provides common patterns for CRUD operations, filtering, and responses.
"""
from rest_framework import status
from rest_framework.response import Response
from django.db.models import Q
from django.utils import timezone


class SuccessResponseMixin:
    """Mixin to standardize success responses."""
    
    def success_response(self, data=None, message=None, status_code=status.HTTP_200_OK):
        response_data = {'success': True}
        if message:
            response_data['message'] = message
        if data is not None:
            response_data['data'] = data
        return Response(response_data, status=status_code)
    
    def created_response(self, data, message="Resource created successfully"):
        return self.success_response(data, message, status.HTTP_201_CREATED)
    
    def deleted_response(self, message="Resource deleted successfully"):
        return Response({'success': True, 'message': message}, status=status.HTTP_204_NO_CONTENT)


class ErrorResponseMixin:
    """Mixin to standardize error responses."""
    
    def error_response(self, message, errors=None, status_code=status.HTTP_400_BAD_REQUEST):
        response_data = {
            'success': False,
            'message': message,
        }
        if errors:
            response_data['errors'] = errors
        return Response(response_data, status=status_code)
    
    def not_found_response(self, message="Resource not found"):
        return self.error_response(message, status_code=status.HTTP_404_NOT_FOUND)
    
    def permission_denied_response(self, message="Permission denied"):
        return self.error_response(message, status_code=status.HTTP_403_FORBIDDEN)


class AuditMixin:
    """Mixin to automatically track created_by and updated_by."""
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    def perform_update(self, serializer):
        serializer.save(updated_by=self.request.user)


class SoftDeleteMixin:
    """Mixin to implement soft delete instead of hard delete."""
    
    def perform_destroy(self, instance):
        instance.is_deleted = True
        instance.deleted_at = timezone.now()
        instance.deleted_by = self.request.user
        instance.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by'])


class MultiTenantMixin:
    """Mixin to filter queryset by user's store/organization."""
    
    tenant_field = 'store'  # Override in subclass if different
    
    def get_queryset(self):
        queryset = super().get_queryset()
        user = self.request.user
        
        # Superusers and head office can see all
        if user.is_superuser or user.role == 'head_office':
            return queryset
        
        # Filter by user's store
        user_store = getattr(user, self.tenant_field, None)
        if user_store:
            return queryset.filter(**{self.tenant_field: user_store})
        
        return queryset


class BulkOperationsMixin:
    """Mixin to support bulk create, update, and delete operations."""
    
    def bulk_create(self, request, *args, **kwargs):
        """Create multiple records at once."""
        items = request.data.get('items', [])
        if not items:
            return Response(
                {'error': 'No items provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = self.get_serializer(data=items, many=True)
        serializer.is_valid(raise_exception=True)
        self.perform_bulk_create(serializer)
        
        return Response(
            {'created': len(items), 'data': serializer.data},
            status=status.HTTP_201_CREATED
        )
    
    def perform_bulk_create(self, serializer):
        serializer.save()
    
    def bulk_update(self, request, *args, **kwargs):
        """Update multiple records at once."""
        items = request.data.get('items', [])
        if not items:
            return Response(
                {'error': 'No items provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        updated = 0
        errors = []
        
        for item in items:
            pk = item.get('id')
            if not pk:
                errors.append({'error': 'Missing id', 'data': item})
                continue
            
            try:
                instance = self.get_queryset().get(pk=pk)
                serializer = self.get_serializer(instance, data=item, partial=True)
                serializer.is_valid(raise_exception=True)
                serializer.save()
                updated += 1
            except Exception as e:
                errors.append({'id': pk, 'error': str(e)})
        
        return Response({
            'updated': updated,
            'errors': errors if errors else None
        })
    
    def bulk_delete(self, request, *args, **kwargs):
        """Delete multiple records at once."""
        ids = request.data.get('ids', [])
        if not ids:
            return Response(
                {'error': 'No ids provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        queryset = self.get_queryset().filter(pk__in=ids)
        count = queryset.count()
        
        # Use soft delete if available
        if hasattr(queryset.model, 'is_deleted'):
            queryset.update(
                is_deleted=True,
                deleted_at=timezone.now(),
                deleted_by=request.user
            )
        else:
            queryset.delete()
        
        return Response({'deleted': count})


class SearchMixin:
    """Mixin for advanced search functionality."""
    
    search_fields = []  # Override in subclass
    
    def get_search_queryset(self, queryset, search_term):
        """Apply search filter to queryset."""
        if not search_term or not self.search_fields:
            return queryset
        
        query = Q()
        for field in self.search_fields:
            query |= Q(**{f'{field}__icontains': search_term})
        
        return queryset.filter(query)


class ExportMixin:
    """Mixin for data export functionality."""
    
    export_fields = []  # Override in subclass
    export_filename = 'export'
    
    def get_export_data(self, queryset):
        """Prepare data for export."""
        data = []
        for obj in queryset:
            row = {}
            for field in self.export_fields:
                if hasattr(obj, field):
                    value = getattr(obj, field)
                    # Handle related objects
                    if hasattr(value, '__str__'):
                        value = str(value)
                    row[field] = value
            data.append(row)
        return data
