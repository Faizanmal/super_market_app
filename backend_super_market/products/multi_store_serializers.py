"""
Multi-Store Serializers
Comprehensive serializers for multi-store management API
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Store, StoreInventory, InterStoreTransfer, 
    StorePerformanceMetrics, StoreUser, Product
)

User = get_user_model()

class StoreSerializer(serializers.ModelSerializer):
    """Serializer for Store model"""
    manager_name = serializers.CharField(source='manager.get_full_name', read_only=True)
    total_products = serializers.ReadOnlyField()
    total_stock_value = serializers.ReadOnlyField()
    is_active = serializers.ReadOnlyField()
    
    class Meta:
        model = Store
        fields = [
            'id', 'name', 'code', 'store_type', 'status',
            'address', 'city', 'state', 'postal_code', 'country',
            'latitude', 'longitude', 'phone', 'email',
            'manager', 'manager_name', 'opening_hours', 'timezone', 'currency',
            'auto_reorder_enabled', 'inter_store_transfers_enabled', 'centralized_inventory',
            'total_products', 'total_stock_value', 'is_active',
            'created_at', 'updated_at', 'created_by'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'created_by']
    
    def validate_code(self, value):
        """Validate store code uniqueness"""
        if self.instance:
            # For updates, exclude current instance
            if Store.objects.exclude(id=self.instance.id).filter(code=value).exists():
                raise serializers.ValidationError("Store code must be unique")
        else:
            # For new stores
            if Store.objects.filter(code=value).exists():
                raise serializers.ValidationError("Store code must be unique")
        return value
    
    def validate_opening_hours(self, value):
        """Validate opening hours format"""
        if value:
            expected_days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
            for day in expected_days:
                if day in value:
                    day_hours = value[day]
                    if not isinstance(day_hours, dict) or 'open' not in day_hours or 'close' not in day_hours:
                        raise serializers.ValidationError(
                            f"Invalid format for {day}. Expected: {{'open': 'HH:MM', 'close': 'HH:MM'}}"
                        )
        return value


class ProductSimpleSerializer(serializers.ModelSerializer):
    """Simple product serializer for nested usage"""
    class Meta:
        model = Product
        fields = ['id', 'name', 'barcode', 'cost_price', 'selling_price']


class StoreSimpleSerializer(serializers.ModelSerializer):
    """Simple store serializer for nested usage"""
    class Meta:
        model = Store
        fields = ['id', 'name', 'code', 'store_type']


class StoreInventorySerializer(serializers.ModelSerializer):
    """Serializer for StoreInventory model"""
    product = ProductSimpleSerializer(read_only=True)
    product_id = serializers.IntegerField(write_only=True)
    store = StoreSimpleSerializer(read_only=True)
    store_id = serializers.UUIDField(write_only=True)
    stock_percentage = serializers.ReadOnlyField()
    needs_reorder = serializers.ReadOnlyField()
    is_overstocked = serializers.ReadOnlyField()
    is_understocked = serializers.ReadOnlyField()
    
    # Calculated fields
    total_value = serializers.SerializerMethodField()
    stock_status = serializers.SerializerMethodField()
    location_display = serializers.SerializerMethodField()
    
    class Meta:
        model = StoreInventory
        fields = [
            'id', 'store', 'store_id', 'product', 'product_id',
            'current_stock', 'min_stock_level', 'max_stock_level',
            'reorder_point', 'reorder_quantity',
            'store_cost_price', 'store_selling_price',
            'aisle', 'shelf', 'bin_location', 'location_display',
            'is_active', 'auto_reorder', 'last_reorder_date',
            'stock_percentage', 'needs_reorder', 'is_overstocked', 'is_understocked',
            'total_value', 'stock_status',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_total_value(self, obj):
        """Calculate total inventory value"""
        cost_price = obj.store_cost_price or obj.product.cost_price or 0
        return float(obj.current_stock * cost_price)
    
    def get_stock_status(self, obj):
        """Get human-readable stock status"""
        if obj.current_stock == 0:
            return 'out_of_stock'
        elif obj.needs_reorder:
            return 'low_stock'
        elif obj.is_overstocked:
            return 'overstocked'
        elif obj.is_understocked:
            return 'understocked'
        else:
            return 'optimal'
    
    def get_location_display(self, obj):
        """Get formatted location string"""
        location_parts = [obj.aisle, obj.shelf, obj.bin_location]
        location_parts = [part for part in location_parts if part]
        return ' - '.join(location_parts) if location_parts else 'Not specified'
    
    def validate(self, data):
        """Validate inventory data"""
        if data.get('min_stock_level', 0) > data.get('max_stock_level', 100):
            raise serializers.ValidationError("Min stock level cannot be greater than max stock level")
        
        if data.get('reorder_point', 0) > data.get('max_stock_level', 100):
            raise serializers.ValidationError("Reorder point cannot be greater than max stock level")
        
        if data.get('current_stock', 0) < 0:
            raise serializers.ValidationError("Current stock cannot be negative")
        
        return data


class InterStoreTransferSerializer(serializers.ModelSerializer):
    """Serializer for InterStoreTransfer model"""
    from_store = StoreSimpleSerializer(read_only=True)
    from_store_id = serializers.UUIDField(write_only=True)
    to_store = StoreSimpleSerializer(read_only=True)
    to_store_id = serializers.UUIDField(write_only=True)
    product = ProductSimpleSerializer(read_only=True)
    product_id = serializers.IntegerField(write_only=True)
    
    requested_by_name = serializers.CharField(source='requested_by.get_full_name', read_only=True)
    approved_by_name = serializers.CharField(source='approved_by.get_full_name', read_only=True)
    received_by_name = serializers.CharField(source='received_by.get_full_name', read_only=True)
    
    is_pending_approval = serializers.ReadOnlyField()
    is_in_progress = serializers.ReadOnlyField()
    is_completed = serializers.ReadOnlyField()
    total_value = serializers.ReadOnlyField()
    
    # Status display
    status_display = serializers.SerializerMethodField()
    reason_display = serializers.SerializerMethodField()
    days_in_transit = serializers.SerializerMethodField()
    
    class Meta:
        model = InterStoreTransfer
        fields = [
            'id', 'transfer_number',
            'from_store', 'from_store_id', 'to_store', 'to_store_id',
            'product', 'product_id',
            'requested_quantity', 'approved_quantity', 'received_quantity',
            'status', 'status_display', 'reason', 'reason_display', 'notes',
            'requested_date', 'approved_date', 'shipped_date', 'received_date', 'expected_delivery',
            'requested_by', 'requested_by_name',
            'approved_by', 'approved_by_name',
            'received_by', 'received_by_name',
            'transfer_cost', 'unit_cost',
            'is_pending_approval', 'is_in_progress', 'is_completed',
            'total_value', 'days_in_transit'
        ]
        read_only_fields = [
            'id', 'transfer_number', 'requested_date', 'approved_date', 
            'shipped_date', 'received_date', 'requested_by', 'approved_by', 'received_by'
        ]
    
    def get_status_display(self, obj):
        """Get human-readable status"""
        status_map = {
            'pending': 'Pending Approval',
            'approved': 'Approved',
            'in_transit': 'In Transit',
            'received': 'Received',
            'cancelled': 'Cancelled',
            'rejected': 'Rejected',
        }
        return status_map.get(obj.status, obj.status.title())
    
    def get_reason_display(self, obj):
        """Get human-readable reason"""
        reason_map = {
            'rebalancing': 'Stock Rebalancing',
            'emergency': 'Emergency Request',
            'excess_stock': 'Excess Stock',
            'promotional': 'Promotional Event',
            'maintenance': 'Store Maintenance',
            'seasonal': 'Seasonal Adjustment',
        }
        return reason_map.get(obj.reason, obj.reason.title())
    
    def get_days_in_transit(self, obj):
        """Calculate days in transit"""
        if obj.shipped_date and obj.received_date:
            return (obj.received_date.date() - obj.shipped_date.date()).days
        elif obj.shipped_date:
            from django.utils import timezone
            return (timezone.now().date() - obj.shipped_date.date()).days
        return None
    
    def validate(self, data):
        """Validate transfer data"""
        if data.get('from_store_id') == data.get('to_store_id'):
            raise serializers.ValidationError("Cannot transfer to the same store")
        
        if data.get('requested_quantity', 0) <= 0:
            raise serializers.ValidationError("Requested quantity must be greater than 0")
        
        # Check if stores allow inter-store transfers
        from_store = Store.objects.filter(id=data.get('from_store_id')).first()
        to_store = Store.objects.filter(id=data.get('to_store_id')).first()
        
        if from_store and not from_store.inter_store_transfers_enabled:
            raise serializers.ValidationError("Source store does not allow inter-store transfers")
        
        if to_store and not to_store.inter_store_transfers_enabled:
            raise serializers.ValidationError("Destination store does not allow inter-store transfers")
        
        return data
    
    def create(self, validated_data):
        """Create transfer with request user"""
        validated_data['requested_by'] = self.context['request'].user
        return super().create(validated_data)


class StorePerformanceMetricsSerializer(serializers.ModelSerializer):
    """Serializer for StorePerformanceMetrics model"""
    store = StoreSimpleSerializer(read_only=True)
    stock_health_score = serializers.ReadOnlyField()
    
    # Performance indicators
    sales_growth = serializers.SerializerMethodField()
    efficiency_score = serializers.SerializerMethodField()
    inventory_health = serializers.SerializerMethodField()
    
    class Meta:
        model = StorePerformanceMetrics
        fields = [
            'id', 'store', 'date',
            'total_sales', 'total_transactions', 'average_transaction_value',
            'total_products', 'total_stock_value', 'products_out_of_stock',
            'products_low_stock', 'products_overstocked', 'products_expired',
            'wastage_value', 'transfers_sent', 'transfers_received',
            'inventory_turnover', 'stock_accuracy', 'stock_health_score',
            'sales_growth', 'efficiency_score', 'inventory_health'
        ]
        read_only_fields = ['id']
    
    def get_sales_growth(self, obj):
        """Calculate sales growth compared to previous day"""
        try:
            from datetime import timedelta
            previous_day = obj.date - timedelta(days=1)
            previous_metrics = StorePerformanceMetrics.objects.filter(
                store=obj.store,
                date=previous_day
            ).first()
            
            if previous_metrics and previous_metrics.total_sales > 0:
                growth = ((obj.total_sales - previous_metrics.total_sales) / previous_metrics.total_sales) * 100
                return round(float(growth), 2)
        except Exception:
            pass
        return None
    
    def get_efficiency_score(self, obj):
        """Calculate overall efficiency score"""
        score = 0
        
        # Sales efficiency (30%)
        if obj.total_transactions > 0:
            avg_transaction = obj.average_transaction_value
            if avg_transaction > 50:  # Threshold for good average
                score += 30
            else:
                score += (avg_transaction / 50) * 30
        
        # Inventory efficiency (40%)
        score += obj.stock_health_score * 0.4
        
        # Waste efficiency (30%)
        if obj.total_stock_value > 0:
            waste_percentage = (obj.wastage_value / obj.total_stock_value) * 100
            waste_score = max(0, 30 - waste_percentage)  # Lower waste = higher score
            score += waste_score
        else:
            score += 30  # No waste if no stock
        
        return round(min(100, max(0, score)), 2)
    
    def get_inventory_health(self, obj):
        """Get inventory health status"""
        if obj.total_products == 0:
            return 'no_data'
        
        out_of_stock_pct = (obj.products_out_of_stock / obj.total_products) * 100
        low_stock_pct = (obj.products_low_stock / obj.total_products) * 100
        
        if out_of_stock_pct > 10:
            return 'critical'
        elif out_of_stock_pct > 5 or low_stock_pct > 20:
            return 'poor'
        elif out_of_stock_pct > 2 or low_stock_pct > 10:
            return 'fair'
        elif out_of_stock_pct <= 1 and low_stock_pct <= 5:
            return 'excellent'
        else:
            return 'good'


class UserSimpleSerializer(serializers.ModelSerializer):
    """Simple user serializer for nested usage"""
    full_name = serializers.CharField(source='get_full_name', read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'full_name']


class StoreUserSerializer(serializers.ModelSerializer):
    """Serializer for StoreUser model"""
    user = UserSimpleSerializer(read_only=True)
    user_id = serializers.IntegerField(write_only=True)
    assigned_stores = StoreSimpleSerializer(many=True, read_only=True)
    assigned_store_ids = serializers.ListField(
        child=serializers.UUIDField(),
        write_only=True,
        required=False
    )
    primary_store = StoreSimpleSerializer(read_only=True)
    primary_store_id = serializers.UUIDField(write_only=True, required=False)
    accessible_stores = serializers.SerializerMethodField()
    
    class Meta:
        model = StoreUser
        fields = [
            'id', 'user', 'user_id', 'assigned_stores', 'assigned_store_ids',
            'primary_store', 'primary_store_id', 'accessible_stores',
            'can_manage_inventory', 'can_approve_transfers',
            'can_view_analytics', 'can_manage_users',
            'default_store_view', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_accessible_stores(self, obj):
        """Get list of accessible stores"""
        accessible_stores = obj.accessible_stores
        return StoreSimpleSerializer(accessible_stores, many=True).data
    
    def create(self, validated_data):
        """Create StoreUser with assigned stores"""
        assigned_store_ids = validated_data.pop('assigned_store_ids', [])
        store_user = super().create(validated_data)
        
        if assigned_store_ids:
            stores = Store.objects.filter(id__in=assigned_store_ids)
            store_user.assigned_stores.set(stores)
        
        return store_user
    
    def update(self, instance, validated_data):
        """Update StoreUser with assigned stores"""
        assigned_store_ids = validated_data.pop('assigned_store_ids', None)
        store_user = super().update(instance, validated_data)
        
        if assigned_store_ids is not None:
            stores = Store.objects.filter(id__in=assigned_store_ids)
            store_user.assigned_stores.set(stores)
        
        return store_user
    
    def validate(self, data):
        """Validate store user data"""
        primary_store_id = data.get('primary_store_id')
        assigned_store_ids = data.get('assigned_store_ids', [])
        
        if primary_store_id and assigned_store_ids and str(primary_store_id) not in [str(sid) for sid in assigned_store_ids]:
            raise serializers.ValidationError("Primary store must be in assigned stores list")
        
        return data


# Bulk operation serializers
class BulkStockUpdateSerializer(serializers.Serializer):
    """Serializer for bulk stock updates"""
    updates = serializers.ListField(
        child=serializers.DictField(),
        allow_empty=False
    )
    
    def validate_updates(self, value):
        """Validate bulk update format"""
        for update in value:
            if 'inventory_id' not in update or 'new_stock' not in update:
                raise serializers.ValidationError(
                    "Each update must contain 'inventory_id' and 'new_stock'"
                )
            
            if not isinstance(update['new_stock'], (int, float)) or update['new_stock'] < 0:
                raise serializers.ValidationError("new_stock must be a non-negative number")
        
        return value


class TransferApprovalSerializer(serializers.Serializer):
    """Serializer for transfer approval"""
    approved_quantity = serializers.IntegerField(min_value=0)
    notes = serializers.CharField(required=False, allow_blank=True)


class TransferReceiptSerializer(serializers.Serializer):
    """Serializer for transfer receipt"""
    received_quantity = serializers.IntegerField(min_value=0)
    notes = serializers.CharField(required=False, allow_blank=True)
    damages = serializers.IntegerField(min_value=0, default=0)
    condition_notes = serializers.CharField(required=False, allow_blank=True)