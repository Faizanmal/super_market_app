"""
Base Serializers - Reusable serializer classes and mixins.
Provides consistent serialization patterns across the application.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone


User = get_user_model()


class TimestampSerializer(serializers.Serializer):
    """Serializer mixin for timestamp fields."""
    created_at = serializers.DateTimeField(read_only=True)
    updated_at = serializers.DateTimeField(read_only=True)


class AuditFieldsMixin(serializers.Serializer):
    """Mixin for audit fields."""
    created_by = serializers.PrimaryKeyRelatedField(read_only=True)
    updated_by = serializers.PrimaryKeyRelatedField(read_only=True)
    created_by_name = serializers.SerializerMethodField()
    updated_by_name = serializers.SerializerMethodField()
    
    def get_created_by_name(self, obj):
        if hasattr(obj, 'created_by') and obj.created_by:
            return obj.created_by.get_full_name() or obj.created_by.email
        return None
    
    def get_updated_by_name(self, obj):
        if hasattr(obj, 'updated_by') and obj.updated_by:
            return obj.updated_by.get_full_name() or obj.updated_by.email
        return None


class SoftDeleteMixin(serializers.Serializer):
    """Mixin for soft delete fields."""
    is_deleted = serializers.BooleanField(read_only=True)
    deleted_at = serializers.DateTimeField(read_only=True)


class BaseModelSerializer(serializers.ModelSerializer):
    """
    Base serializer with common functionality.
    Automatically handles created_by field.
    """
    
    def create(self, validated_data):
        """Automatically set created_by to current user."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            if hasattr(self.Meta.model, 'created_by'):
                validated_data['created_by'] = request.user
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        """Automatically set updated_by to current user."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            if hasattr(self.Meta.model, 'updated_by'):
                validated_data['updated_by'] = request.user
        return super().update(instance, validated_data)


class DynamicFieldsModelSerializer(BaseModelSerializer):
    """
    Serializer that allows dynamic field selection.
    Pass 'fields' or 'exclude' in the context to customize output.
    """
    
    def __init__(self, *args, **kwargs):
        # Get fields and exclude from kwargs
        fields = kwargs.pop('fields', None)
        exclude = kwargs.pop('exclude', None)
        
        super().__init__(*args, **kwargs)
        
        if fields is not None:
            # Drop fields not specified in 'fields'
            allowed = set(fields)
            existing = set(self.fields)
            for field_name in existing - allowed:
                self.fields.pop(field_name)
        
        if exclude is not None:
            # Drop fields specified in 'exclude'
            for field_name in exclude:
                self.fields.pop(field_name, None)


class BulkCreateSerializer(serializers.ListSerializer):
    """Serializer for bulk create operations."""
    
    def create(self, validated_data):
        result = [self.child.create(item) for item in validated_data]
        return result


class BulkUpdateSerializer(serializers.ListSerializer):
    """Serializer for bulk update operations."""
    
    def update(self, instance, validated_data):
        # Map instances by id
        instance_mapping = {str(item.id): item for item in instance}
        
        result = []
        for item in validated_data:
            item_id = str(item.get('id'))
            if item_id in instance_mapping:
                result.append(self.child.update(instance_mapping[item_id], item))
        
        return result


class NestedCreateMixin:
    """Mixin for handling nested object creation."""
    
    def create_nested_objects(self, model_class, data_list, foreign_key_name, parent_instance):
        """Create nested objects for a parent instance."""
        for item_data in data_list:
            item_data[foreign_key_name] = parent_instance
            model_class.objects.create(**item_data)


class ReadOnlyFieldsMixin:
    """Mixin to make specified fields read-only during updates."""
    
    read_only_on_update = []
    
    def get_fields(self):
        fields = super().get_fields()
        
        # Check if this is an update
        if self.instance is not None:
            for field_name in self.read_only_on_update:
                if field_name in fields:
                    fields[field_name].read_only = True
        
        return fields


class UserSummarySerializer(serializers.ModelSerializer):
    """Lightweight serializer for user references."""
    full_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ('id', 'email', 'full_name', 'role')
        read_only_fields = fields
    
    def get_full_name(self, obj):
        return obj.get_full_name() or obj.email


class IdNameSerializer(serializers.Serializer):
    """Generic serializer for id-name pairs."""
    id = serializers.IntegerField()
    name = serializers.CharField()


class StatusUpdateSerializer(serializers.Serializer):
    """Serializer for status update operations."""
    status = serializers.CharField()
    notes = serializers.CharField(required=False, allow_blank=True)


class DateRangeSerializer(serializers.Serializer):
    """Serializer for date range filtering."""
    start_date = serializers.DateField(required=False)
    end_date = serializers.DateField(required=False)
    period = serializers.ChoiceField(
        choices=[
            ('today', 'Today'),
            ('yesterday', 'Yesterday'),
            ('this_week', 'This Week'),
            ('last_week', 'Last Week'),
            ('this_month', 'This Month'),
            ('last_month', 'Last Month'),
            ('this_quarter', 'This Quarter'),
            ('this_year', 'This Year'),
            ('custom', 'Custom Range'),
        ],
        required=False
    )
    
    def validate(self, attrs):
        start_date = attrs.get('start_date')
        end_date = attrs.get('end_date')
        
        if start_date and end_date and start_date > end_date:
            raise serializers.ValidationError({
                'end_date': 'End date must be after start date.'
            })
        
        return attrs


class FileUploadSerializer(serializers.Serializer):
    """Serializer for file upload operations."""
    file = serializers.FileField()
    file_type = serializers.ChoiceField(
        choices=[
            ('image', 'Image'),
            ('document', 'Document'),
            ('spreadsheet', 'Spreadsheet'),
        ],
        required=False
    )
    
    def validate_file(self, value):
        # Validate file size (max 10MB)
        max_size = 10 * 1024 * 1024
        if value.size > max_size:
            raise serializers.ValidationError('File size must be less than 10MB.')
        return value


class PaginationSerializer(serializers.Serializer):
    """Serializer for pagination parameters."""
    page = serializers.IntegerField(min_value=1, default=1)
    page_size = serializers.IntegerField(min_value=1, max_value=100, default=20)
    ordering = serializers.CharField(required=False)


class SearchSerializer(serializers.Serializer):
    """Serializer for search parameters."""
    q = serializers.CharField(required=False, help_text='Search query')
    filters = serializers.JSONField(required=False, help_text='Filter parameters')
