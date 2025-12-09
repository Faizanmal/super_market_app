"""
Serializers for products, categories, and suppliers.
"""
from rest_framework import serializers
from .models import (
    Category, Supplier, Product, StockMovement, Store,
    ProductFavorite, ShoppingList, ShoppingListItem,
    PurchaseOrder, PurchaseOrderItem, ProductReview,
    Notification, AuditLog, Currency, InventoryAdjustment,
    StoreTransfer, PriceHistory, SupplierContract,
    # New expiry management models
    ProductBatch, ShelfLocation, BatchLocation, ReceivingLog,
    ShelfAudit, AuditItem, ExpiryAlert, Task, PhotoEvidence,
    NotificationPreference, WastageReport, WastageItem,
    ComplianceLog, SupplierPerformance, DynamicPricing
)
 
# Import multi-store serializers


class CategorySerializer(serializers.ModelSerializer):
    """Serializer for Category model."""
    
    product_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Category
        fields = (
            'id', 'name', 'description', 'icon', 'color',
            'product_count', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')
    
    def get_product_count(self, obj):
        """Get count of products in this category."""
        return obj.products.filter(is_active=True).count()
    
    def create(self, validated_data):
        """Set created_by to current user."""
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class SupplierSerializer(serializers.ModelSerializer):
    """Serializer for Supplier model."""
    
    product_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Supplier
        fields = (
            'id', 'name', 'contact_person', 'email', 'phone', 
            'address', 'product_count', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')
    
    def get_product_count(self, obj):
        """Get count of products from this supplier."""
        return obj.products.filter(is_active=True).count()
    
    def create(self, validated_data):
        """Set created_by to current user."""
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class ProductListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for product list view."""
    
    category_name = serializers.CharField(source='category.name', read_only=True)
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    expiry_status = serializers.CharField(read_only=True)
    days_until_expiry = serializers.IntegerField(read_only=True)
    is_low_stock = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Product
        fields = (
            'id', 'name', 'barcode', 'category', 'category_name',
            'supplier', 'supplier_name', 'quantity', 'selling_price',
            'expiry_date', 'expiry_status', 'days_until_expiry',
            'is_low_stock', 'is_active', 'image'
        )


class ProductDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for product detail view."""
    
    category_name = serializers.CharField(source='category.name', read_only=True)
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    expiry_status = serializers.CharField(read_only=True)
    days_until_expiry = serializers.IntegerField(read_only=True)
    is_low_stock = serializers.BooleanField(read_only=True)
    profit_margin = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    total_value = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    
    class Meta:
        model = Product
        fields = (
            'id', 'name', 'description', 'category', 'category_name',
            'supplier', 'supplier_name', 'barcode', 'sku', 'quantity',
            'min_stock_level', 'cost_price', 'selling_price', 
            'expiry_date', 'manufacture_date', 'batch_number',
            'location', 'image', 'expiry_status', 'days_until_expiry',
            'is_low_stock', 'profit_margin', 'total_value',
            'is_active', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')


class ProductCreateUpdateSerializer(serializers.ModelSerializer):
    """Serializer for creating and updating products."""
    
    class Meta:
        model = Product
        fields = (
            'id', 'name', 'description', 'category', 'supplier',
            'barcode', 'sku', 'quantity', 'min_stock_level',
            'cost_price', 'selling_price', 'expiry_date',
            'manufacture_date', 'batch_number', 'location', 'image', 'is_active'
        )
        read_only_fields = ('id',)
    
    def validate_barcode(self, value):
        """Validate barcode uniqueness."""
        instance = self.instance
        if instance:
            # Update: exclude current instance from uniqueness check
            if Product.objects.exclude(pk=instance.pk).filter(barcode=value).exists():
                raise serializers.ValidationError("Product with this barcode already exists.")
        else:
            # Create: check if barcode exists
            if Product.objects.filter(barcode=value).exists():
                raise serializers.ValidationError("Product with this barcode already exists.")
        return value
    
    def validate(self, attrs):
        """Validate product data."""
        if attrs.get('selling_price') and attrs.get('cost_price'):
            if attrs['selling_price'] < attrs['cost_price']:
                raise serializers.ValidationError({
                    'selling_price': 'Selling price cannot be less than cost price.'
                })
        
        if attrs.get('manufacture_date') and attrs.get('expiry_date'):
            if attrs['manufacture_date'] >= attrs['expiry_date']:
                raise serializers.ValidationError({
                    'expiry_date': 'Expiry date must be after manufacture date.'
                })
        
        return attrs
    
    def create(self, validated_data):
        """Set created_by to current user."""
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


# Alias for backward compatibility
ProductSerializer = ProductDetailSerializer


class StockMovementSerializer(serializers.ModelSerializer):
    """Serializer for stock movements."""
    
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_barcode = serializers.CharField(source='product.barcode', read_only=True)
    
    class Meta:
        model = StockMovement
        fields = (
            'id', 'product', 'product_name', 'product_barcode',
            'movement_type', 'quantity', 'reason', 'reference_number',
            'unit_price', 'created_at'
        )
        read_only_fields = ('id', 'created_at')
    
    def create(self, validated_data):
        """Create stock movement and update product quantity."""
        validated_data['created_by'] = self.context['request'].user
        movement = super().create(validated_data)
        
        # Update product quantity based on movement type
        product = movement.product
        if movement.movement_type == 'in':
            product.quantity += movement.quantity
        elif movement.movement_type in ['out', 'wastage']:
            product.quantity = max(0, product.quantity - movement.quantity)
        # For 'adjustment', manually set the quantity in a separate field if needed
        
        product.save()
        
        return movement


class BarcodeSearchSerializer(serializers.Serializer):
    """Serializer for barcode search."""
    
    barcode = serializers.CharField(required=True, max_length=100)


class StoreSerializer(serializers.ModelSerializer):
    """Serializer for Store model."""
    
    manager_name = serializers.CharField(source='manager.get_full_name', read_only=True)
    product_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Store
        fields = (
            'id', 'name', 'code', 'address', 'phone', 'email',
            'manager', 'manager_name', 'is_active', 'timezone',
            'product_count', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')
    
    def get_product_count(self, obj):
        return obj.products.filter(is_deleted=False).count()


class ProductFavoriteSerializer(serializers.ModelSerializer):
    """Serializer for ProductFavorite model."""
    
    product_detail = ProductListSerializer(source='product', read_only=True)
    
    class Meta:
        model = ProductFavorite
        fields = ('id', 'product', 'product_detail', 'created_at')
        read_only_fields = ('id', 'created_at')


class ShoppingListItemSerializer(serializers.ModelSerializer):
    """Serializer for ShoppingListItem model."""
    
    product_detail = ProductListSerializer(source='product', read_only=True)
    
    class Meta:
        model = ShoppingListItem
        fields = (
            'id', 'shopping_list', 'product', 'product_detail',
            'item_name', 'quantity', 'estimated_price', 'estimated_cost',
            'is_purchased', 'notes', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'estimated_cost', 'created_at', 'updated_at')


class ShoppingListSerializer(serializers.ModelSerializer):
    """Serializer for ShoppingList model."""
    
    items = ShoppingListItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = ShoppingList
        fields = (
            'id', 'name', 'status', 'notes', 'items',
            'total_items', 'completed_items', 'estimated_total',
            'created_at', 'updated_at', 'completed_at'
        )
        read_only_fields = (
            'id', 'total_items', 'completed_items', 'estimated_total',
            'created_at', 'updated_at'
        )


class PurchaseOrderItemSerializer(serializers.ModelSerializer):
    """Serializer for PurchaseOrderItem model."""
    
    product_detail = ProductListSerializer(source='product', read_only=True)
    
    class Meta:
        model = PurchaseOrderItem
        fields = (
            'id', 'purchase_order', 'product', 'product_detail',
            'quantity', 'unit_price', 'total_price',
            'received_quantity', 'is_fully_received', 'notes'
        )
        read_only_fields = ('id', 'total_price', 'is_fully_received')


class PurchaseOrderSerializer(serializers.ModelSerializer):
    """Serializer for PurchaseOrder model."""
    
    supplier_detail = SupplierSerializer(source='supplier', read_only=True)
    items = PurchaseOrderItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = PurchaseOrder
        fields = (
            'id', 'order_number', 'supplier', 'supplier_detail',
            'status', 'order_date', 'expected_delivery', 'actual_delivery',
            'notes', 'items', 'total_amount', 'total_items',
            'created_at', 'updated_at'
        )
        read_only_fields = (
            'id', 'order_number', 'total_amount', 'total_items',
            'created_at', 'updated_at'
        )


class ProductReviewSerializer(serializers.ModelSerializer):
    """Serializer for ProductReview model."""
    
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    product_name = serializers.CharField(source='product.name', read_only=True)
    
    class Meta:
        model = ProductReview
        fields = (
            'id', 'product', 'product_name', 'user_name',
            'rating', 'review_text', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'user_name', 'created_at', 'updated_at')
    
    def validate_rating(self, value):
        if value < 1 or value > 5:
            raise serializers.ValidationError("Rating must be between 1 and 5")
        return value


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for Notification model."""
    
    product_name = serializers.CharField(source='product.name', read_only=True)
    order_number = serializers.CharField(source='purchase_order.order_number', read_only=True)
    notification_type_display = serializers.CharField(source='get_notification_type_display', read_only=True)
    priority_display = serializers.CharField(source='get_priority_display', read_only=True)
    
    class Meta:
        model = Notification
        fields = (
            'id', 'user', 'notification_type', 'notification_type_display',
            'priority', 'priority_display', 'title', 'message',
            'product', 'product_name', 'purchase_order', 'order_number',
            'is_read', 'read_at', 'action_url', 'created_at', 'expires_at'
        )
        read_only_fields = ('id', 'created_at', 'read_at')


class AuditLogSerializer(serializers.ModelSerializer):
    """Serializer for AuditLog model."""
    
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    action_display = serializers.CharField(source='get_action_display', read_only=True)
    
    class Meta:
        model = AuditLog
        fields = (
            'id', 'user', 'user_name', 'action', 'action_display',
            'timestamp', 'model_name', 'object_id', 'object_repr',
            'changes', 'ip_address', 'user_agent', 'success', 'error_message'
        )
        read_only_fields = ('id', 'timestamp')


class CurrencySerializer(serializers.ModelSerializer):
    """Serializer for Currency model."""
    
    class Meta:
        model = Currency
        fields = (
            'id', 'code', 'name', 'symbol', 'exchange_rate',
            'is_base_currency', 'is_active', 'last_updated'
        )
        read_only_fields = ('id', 'last_updated')
    
    def validate(self, data):
        """Ensure only one base currency exists."""
        if data.get('is_base_currency', False):
            if self.instance and not self.instance.is_base_currency:
                # Changing to base currency
                if Currency.objects.filter(is_base_currency=True).exclude(id=self.instance.id).exists():
                    raise serializers.ValidationError("Only one base currency can exist")
            elif not self.instance:
                # Creating new base currency
                if Currency.objects.filter(is_base_currency=True).exists():
                    raise serializers.ValidationError("Only one base currency can exist")
        return data


class InventoryAdjustmentSerializer(serializers.ModelSerializer):
    """Serializer for InventoryAdjustment model."""
    
    product_detail = ProductListSerializer(source='product', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    approved_by_name = serializers.CharField(source='approved_by.get_full_name', read_only=True)
    reason_display = serializers.CharField(source='get_reason_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = InventoryAdjustment
        fields = (
            'id', 'adjustment_number', 'product', 'product_detail',
            'quantity_before', 'quantity_after', 'adjustment_quantity',
            'reason', 'reason_display', 'notes', 'status', 'status_display',
            'created_by', 'created_by_name', 'approved_by', 'approved_by_name',
            'created_at', 'approved_at', 'photo_evidence'
        )
        read_only_fields = ('id', 'adjustment_number', 'created_at', 'approved_at')


class StoreTransferSerializer(serializers.ModelSerializer):
    """Serializer for StoreTransfer model."""
    
    from_store_detail = StoreSerializer(source='from_store', read_only=True)
    to_store_detail = StoreSerializer(source='to_store', read_only=True)
    product_detail = ProductListSerializer(source='product', read_only=True)
    initiated_by_name = serializers.CharField(source='initiated_by.get_full_name', read_only=True)
    received_by_name = serializers.CharField(source='received_by.get_full_name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = StoreTransfer
        fields = (
            'id', 'transfer_number', 'from_store', 'from_store_detail',
            'to_store', 'to_store_detail', 'product', 'product_detail',
            'quantity', 'status', 'status_display', 'notes',
            'initiated_by', 'initiated_by_name', 'received_by', 'received_by_name',
            'initiated_at', 'shipped_at', 'received_at', 'expected_arrival'
        )
        read_only_fields = ('id', 'transfer_number', 'initiated_at')


class PriceHistorySerializer(serializers.ModelSerializer):
    """Serializer for PriceHistory model."""
    
    product_detail = ProductListSerializer(source='product', read_only=True)
    changed_by_name = serializers.CharField(source='changed_by.get_full_name', read_only=True)
    cost_price_change = serializers.DecimalField(
        source='cost_price_change_percent', max_digits=5, decimal_places=2, read_only=True
    )
    selling_price_change = serializers.DecimalField(
        source='selling_price_change_percent', max_digits=5, decimal_places=2, read_only=True
    )
    
    class Meta:
        model = PriceHistory
        fields = (
            'id', 'product', 'product_detail',
            'old_cost_price', 'new_cost_price', 'cost_price_change',
            'old_selling_price', 'new_selling_price', 'selling_price_change',
            'reason', 'changed_by', 'changed_by_name', 'changed_at'
        )
        read_only_fields = ('id', 'changed_at')


class SupplierContractSerializer(serializers.ModelSerializer):
    """Serializer for SupplierContract model."""
    
    supplier_detail = SupplierSerializer(source='supplier', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    is_currently_active = serializers.BooleanField(source='is_active', read_only=True)
    days_remaining = serializers.IntegerField(source='days_until_expiry', read_only=True)
    
    class Meta:
        model = SupplierContract
        fields = (
            'id', 'contract_number', 'supplier', 'supplier_detail',
            'start_date', 'end_date', 'status', 'status_display',
            'payment_terms', 'minimum_order_value', 'discount_percentage',
            'contract_document', 'notes', 'created_by', 'created_by_name',
            'created_at', 'updated_at', 'is_currently_active', 'days_remaining'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')
    
    def validate(self, data):
        """Validate contract dates."""
        if data.get('start_date') and data.get('end_date'):
            if data['start_date'] >= data['end_date']:
                raise serializers.ValidationError("End date must be after start date")
        return data


# ==================== EXPIRY & SHELF MANAGEMENT SYSTEM SERIALIZERS ====================

class ProductBatchSerializer(serializers.ModelSerializer):
    """Serializer for ProductBatch model."""
    
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_image = serializers.ImageField(source='product.image', read_only=True)
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    store_name = serializers.CharField(source='store.name', read_only=True)
    received_by_name = serializers.CharField(source='received_by.get_full_name', read_only=True)
    
    # Computed fields
    days_until_expiry = serializers.IntegerField(read_only=True)
    expiry_status = serializers.CharField(read_only=True)
    total_value = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    
    class Meta:
        model = ProductBatch
        fields = '__all__'
        read_only_fields = ('id', 'received_date', 'created_at', 'updated_at')


class ShelfLocationSerializer(serializers.ModelSerializer):
    """Serializer for ShelfLocation model."""
    
    store_name = serializers.CharField(source='store.name', read_only=True)
    full_location = serializers.CharField(read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    
    class Meta:
        model = ShelfLocation
        fields = '__all__'
        read_only_fields = ('id', 'created_at', 'updated_at')


class BatchLocationSerializer(serializers.ModelSerializer):
    """Serializer for BatchLocation model."""
    
    batch_details = ProductBatchSerializer(source='batch', read_only=True)
    location_details = ShelfLocationSerializer(source='shelf_location', read_only=True)
    placed_by_name = serializers.CharField(source='placed_by.get_full_name', read_only=True)
    
    class Meta:
        model = BatchLocation
        fields = '__all__'
        read_only_fields = ('id', 'placed_at')


class ReceivingLogSerializer(serializers.ModelSerializer):
    """Serializer for ReceivingLog model."""
    
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    store_name = serializers.CharField(source='store.name', read_only=True)
    received_by_name = serializers.CharField(source='received_by.get_full_name', read_only=True)
    approved_by_name = serializers.CharField(source='approved_by.get_full_name', read_only=True)
    batch_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = ReceivingLog
        fields = '__all__'
        read_only_fields = ('id', 'received_date', 'created_at', 'updated_at')


class AuditItemSerializer(serializers.ModelSerializer):
    """Serializer for AuditItem model."""
    
    batch_details = ProductBatchSerializer(source='batch', read_only=True)
    
    class Meta:
        model = AuditItem
        fields = '__all__'
        read_only_fields = ('id', 'created_at')


class ShelfAuditSerializer(serializers.ModelSerializer):
    """Serializer for ShelfAudit model."""
    
    store_name = serializers.CharField(source='store.name', read_only=True)
    auditor_name = serializers.CharField(source='auditor.get_full_name', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    location_code = serializers.CharField(source='shelf_location.location_code', read_only=True)
    audit_items = AuditItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = ShelfAudit
        fields = '__all__'
        read_only_fields = ('id', 'audit_date', 'created_at', 'updated_at')


class ExpiryAlertSerializer(serializers.ModelSerializer):
    """Serializer for ExpiryAlert model."""
    
    batch_details = ProductBatchSerializer(source='batch', read_only=True)
    store_name = serializers.CharField(source='store.name', read_only=True)
    location_code = serializers.CharField(source='shelf_location.location_code', read_only=True)
    acknowledged_by_name = serializers.CharField(source='acknowledged_by.get_full_name', read_only=True)
    resolved_by_name = serializers.CharField(source='resolved_by.get_full_name', read_only=True)
    
    class Meta:
        model = ExpiryAlert
        fields = '__all__'
        read_only_fields = ('id', 'created_at', 'updated_at', 'acknowledged_at', 'resolved_at')


class TaskSerializer(serializers.ModelSerializer):
    """Serializer for Task model."""
    
    assigned_to_name = serializers.CharField(source='assigned_to.get_full_name', read_only=True)
    assigned_by_name = serializers.CharField(source='assigned_by.get_full_name', read_only=True)
    store_name = serializers.CharField(source='store.name', read_only=True)
    location_code = serializers.CharField(source='shelf_location.location_code', read_only=True)
    batch_number = serializers.CharField(source='batch.batch_number', read_only=True)
    
    class Meta:
        model = Task
        fields = '__all__'
        read_only_fields = ('id', 'created_at', 'updated_at', 'completed_at')


class PhotoEvidenceSerializer(serializers.ModelSerializer):
    """Serializer for PhotoEvidence model."""
    
    store_name = serializers.CharField(source='store.name', read_only=True)
    uploaded_by_name = serializers.CharField(source='uploaded_by.get_full_name', read_only=True)
    
    class Meta:
        model = PhotoEvidence
        fields = '__all__'
        read_only_fields = ('id', 'uploaded_at')


class NotificationPreferenceSerializer(serializers.ModelSerializer):
    """Serializer for NotificationPreference model."""
    
    class Meta:
        model = NotificationPreference
        fields = '__all__'
        read_only_fields = ('id', 'updated_at')


class WastageItemSerializer(serializers.ModelSerializer):
    """Serializer for WastageItem model."""
    
    disposed_by_name = serializers.CharField(source='disposed_by.get_full_name', read_only=True)
    
    class Meta:
        model = WastageItem
        fields = '__all__'
        read_only_fields = ('id', 'created_at', 'total_loss')


class WastageReportSerializer(serializers.ModelSerializer):
    """Serializer for WastageReport model."""
    
    items = WastageItemSerializer(many=True, read_only=True)
    store_name = serializers.CharField(source='store.name', read_only=True)
    prepared_by_name = serializers.CharField(source='prepared_by.get_full_name', read_only=True)
    reviewed_by_name = serializers.CharField(source='reviewed_by.get_full_name', read_only=True)
    approved_by_name = serializers.CharField(source='approved_by.get_full_name', read_only=True)
    
    class Meta:
        model = WastageReport
        fields = '__all__'
        read_only_fields = ('id', 'report_date', 'created_at', 'updated_at')


class ComplianceLogSerializer(serializers.ModelSerializer):
    """Serializer for ComplianceLog model."""
    
    store_name = serializers.CharField(source='store.name', read_only=True)
    logged_by_name = serializers.CharField(source='logged_by.get_full_name', read_only=True)
    reviewed_by_name = serializers.CharField(source='reviewed_by.get_full_name', read_only=True)
    
    class Meta:
        model = ComplianceLog
        fields = '__all__'
        read_only_fields = ('id', 'log_date', 'created_at', 'updated_at')


class SupplierPerformanceSerializer(serializers.ModelSerializer):
    """Serializer for SupplierPerformance model."""
    
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    store_name = serializers.CharField(source='store.name', read_only=True)
    calculated_by_name = serializers.CharField(source='calculated_by.get_full_name', read_only=True)
    
    class Meta:
        model = SupplierPerformance
        fields = '__all__'
        read_only_fields = (
            'id', 'quality_score', 'delivery_score', 'overall_score',
            'performance_status', 'calculated_at'
        )


class DynamicPricingSerializer(serializers.ModelSerializer):
    """Serializer for DynamicPricing model."""
    
    batch_details = ProductBatchSerializer(source='batch', read_only=True)
    store_name = serializers.CharField(source='store.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    approved_by_name = serializers.CharField(source='approved_by.get_full_name', read_only=True)
    
    class Meta:
        model = DynamicPricing
        fields = '__all__'
        read_only_fields = ('id', 'discounted_price', 'created_at', 'updated_at')


# ==================== ANALYTICS SERIALIZERS ====================

class ExpiryAnalyticsSerializer(serializers.Serializer):
    """Serializer for expiry analytics data."""
    
    total_batches = serializers.IntegerField()
    expiring_critical = serializers.IntegerField()
    expiring_high = serializers.IntegerField()
    expiring_medium = serializers.IntegerField()
    total_at_risk_value = serializers.DecimalField(max_digits=12, decimal_places=2)
    top_expiring_products = serializers.ListField()


class WastageAnalyticsSerializer(serializers.Serializer):
    """Serializer for wastage analytics data."""
    
    total_wastage = serializers.IntegerField()
    total_monetary_loss = serializers.DecimalField(max_digits=12, decimal_places=2)
    wastage_by_reason = serializers.DictField()
    wastage_trend = serializers.ListField()


class StoreComparisonSerializer(serializers.Serializer):
    """Serializer for store comparison analytics."""
    
    store_name = serializers.CharField()
    total_wastage = serializers.IntegerField()
    total_loss = serializers.DecimalField(max_digits=12, decimal_places=2)
    expiry_alerts = serializers.IntegerField()
    task_completion_rate = serializers.FloatField()


class DashboardSummarySerializer(serializers.Serializer):
    """Serializer for dashboard summary data."""
    
    total_products = serializers.IntegerField()
    total_batches = serializers.IntegerField()
    critical_alerts = serializers.IntegerField()
    pending_tasks = serializers.IntegerField()
    wastage_this_month = serializers.DecimalField(max_digits=12, decimal_places=2)
    revenue_recovered = serializers.DecimalField(max_digits=12, decimal_places=2)
    top_expiring = serializers.ListField()
    recent_audits = serializers.ListField()
