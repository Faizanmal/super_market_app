"""
Admin configuration for products app.
"""
from django.contrib import admin
from .models import (
    Category, Supplier, Product, StockMovement, Store,
    ProductFavorite, ShoppingList, ShoppingListItem,
    PurchaseOrder, PurchaseOrderItem, ProductReview,
    Notification, AuditLog, Currency, InventoryAdjustment,
    StoreTransfer, PriceHistory, SupplierContract,
    # New expiry management models
    ProductBatch, ShelfLocation, BatchLocation, ReceivingLog,
    ShelfAudit, AuditItem, ExpiryAlert, Task, PhotoEvidence
)

# Import security admin configurations (registers admin classes)
from . import security_admin  # noqa: F401

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    """Admin for Category model."""
    
    list_display = ('name', 'description', 'color', 'created_by', 'created_at')
    list_filter = ('created_at', 'created_by')
    search_fields = ('name', 'description')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):
    """Admin for Supplier model."""
    
    list_display = ('name', 'contact_person', 'email', 'phone', 'created_by', 'created_at')
    list_filter = ('created_at', 'created_by')
    search_fields = ('name', 'contact_person', 'email', 'phone')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    """Admin for Product model."""
    
    list_display = (
        'name', 'barcode', 'category', 'supplier', 'quantity',
        'selling_price', 'expiry_date', 'is_active', 'created_at'
    )
    list_filter = ('is_active', 'category', 'supplier', 'expiry_date', 'created_at')
    search_fields = ('name', 'barcode', 'sku', 'description')
    readonly_fields = ('created_at', 'updated_at', 'expiry_status', 'days_until_expiry', 
                      'is_low_stock', 'profit_margin', 'total_value')
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'description', 'category', 'supplier', 'image')
        }),
        ('Inventory', {
            'fields': ('barcode', 'sku', 'quantity', 'min_stock_level', 'location', 'is_low_stock')
        }),
        ('Pricing', {
            'fields': ('cost_price', 'selling_price', 'profit_margin', 'total_value')
        }),
        ('Dates', {
            'fields': ('manufacture_date', 'expiry_date', 'expiry_status', 'days_until_expiry')
        }),
        ('Additional', {
            'fields': ('batch_number', 'is_active', 'created_by')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(StockMovement)
class StockMovementAdmin(admin.ModelAdmin):
    """Admin for StockMovement model."""
    
    list_display = ('product', 'movement_type', 'quantity', 'unit_price', 'created_by', 'created_at')
    list_filter = ('movement_type', 'created_at', 'created_by')
    search_fields = ('product__name', 'reference_number', 'reason')
    readonly_fields = ('created_at',)
    
    def has_change_permission(self, request, obj=None):
        """Disable editing of stock movements."""
        return False


@admin.register(Store)
class StoreAdmin(admin.ModelAdmin):
    """Admin for Store model."""
    
    list_display = ('name', 'code', 'manager', 'is_active', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('name', 'code', 'address')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(ProductFavorite)
class ProductFavoriteAdmin(admin.ModelAdmin):
    """Admin for ProductFavorite model."""
    
    list_display = ('user', 'product', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('user__email', 'product__name')


@admin.register(ShoppingList)
class ShoppingListAdmin(admin.ModelAdmin):
    """Admin for ShoppingList model."""
    
    list_display = ('name', 'status', 'created_by', 'total_items', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('name', 'notes')
    readonly_fields = ('created_at', 'updated_at', 'total_items', 'completed_items', 'estimated_total')


class ShoppingListItemInline(admin.TabularInline):
    """Inline for ShoppingListItem."""
    model = ShoppingListItem
    extra = 1


@admin.register(ShoppingListItem)
class ShoppingListItemAdmin(admin.ModelAdmin):
    """Admin for ShoppingListItem model."""
    
    list_display = ('item_name', 'shopping_list', 'quantity', 'is_purchased', 'created_at')
    list_filter = ('is_purchased', 'created_at')
    search_fields = ('item_name', 'notes')


class PurchaseOrderItemInline(admin.TabularInline):
    """Inline for PurchaseOrderItem."""
    model = PurchaseOrderItem
    extra = 1


@admin.register(PurchaseOrder)
class PurchaseOrderAdmin(admin.ModelAdmin):
    """Admin for PurchaseOrder model."""
    
    list_display = ('order_number', 'supplier', 'status', 'order_date', 'total_amount', 'created_at')
    list_filter = ('status', 'order_date', 'created_at')
    search_fields = ('order_number', 'supplier__name')
    readonly_fields = ('order_number', 'created_at', 'updated_at', 'total_amount', 'total_items')
    inlines = [PurchaseOrderItemInline]


@admin.register(PurchaseOrderItem)
class PurchaseOrderItemAdmin(admin.ModelAdmin):
    """Admin for PurchaseOrderItem model."""
    
    list_display = ('purchase_order', 'product', 'quantity', 'unit_price', 'total_price')
    search_fields = ('product__name', 'purchase_order__order_number')
    readonly_fields = ('total_price',)


@admin.register(ProductReview)
class ProductReviewAdmin(admin.ModelAdmin):
    """Admin for ProductReview model."""
    
    list_display = ('product', 'user', 'rating', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('product__name', 'user__email', 'review_text')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    """Admin for Notification model."""
    
    list_display = ('title', 'user', 'notification_type', 'priority', 'is_read', 'created_at')
    list_filter = ('notification_type', 'priority', 'is_read', 'created_at')
    search_fields = ('title', 'message', 'user__email')
    readonly_fields = ('created_at', 'read_at')
    
    actions = ['mark_as_read', 'mark_as_unread']
    
    def mark_as_read(self, request, queryset):
        """Bulk mark notifications as read."""
        from django.utils import timezone
        count = queryset.filter(is_read=False).update(is_read=True, read_at=timezone.now())
        self.message_user(request, f"{count} notifications marked as read.")
    
    def mark_as_unread(self, request, queryset):
        """Bulk mark notifications as unread."""
        count = queryset.filter(is_read=True).update(is_read=False, read_at=None)
        self.message_user(request, f"{count} notifications marked as unread.")


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    """Admin for AuditLog model."""
    
    list_display = ('user', 'action', 'model_name', 'object_repr', 'timestamp', 'success')
    list_filter = ('action', 'model_name', 'success', 'timestamp')
    search_fields = ('user__email', 'object_repr', 'changes')
    readonly_fields = ('user', 'action', 'timestamp', 'model_name', 'object_id', 
                      'object_repr', 'changes', 'ip_address', 'user_agent', 'success', 'error_message')
    
    def has_add_permission(self, request):
        """Prevent manual creation of audit logs."""
        return False
    
    def has_delete_permission(self, request, obj=None):
        """Prevent deletion of audit logs."""
        return request.user.is_superuser


@admin.register(Currency)
class CurrencyAdmin(admin.ModelAdmin):
    """Admin for Currency model."""
    
    list_display = ('code', 'name', 'symbol', 'exchange_rate', 'is_base_currency', 'is_active', 'last_updated')
    list_filter = ('is_base_currency', 'is_active')
    search_fields = ('code', 'name')
    readonly_fields = ('last_updated',)


@admin.register(InventoryAdjustment)
class InventoryAdjustmentAdmin(admin.ModelAdmin):
    """Admin for InventoryAdjustment model."""
    
    list_display = ('adjustment_number', 'product', 'adjustment_quantity', 'reason', 
                   'status', 'created_by', 'created_at')
    list_filter = ('status', 'reason', 'created_at')
    search_fields = ('adjustment_number', 'product__name', 'notes')
    readonly_fields = ('adjustment_number', 'created_at', 'approved_at')
    
    actions = ['approve_adjustments', 'reject_adjustments']
    
    def approve_adjustments(self, request, queryset):
        """Bulk approve adjustments."""
        from django.utils import timezone
        count = 0
        for adjustment in queryset.filter(status='pending'):
            adjustment.product.quantity = adjustment.quantity_after
            adjustment.product.save()
            adjustment.status = 'approved'
            adjustment.approved_by = request.user
            adjustment.approved_at = timezone.now()
            adjustment.save()
            count += 1
        self.message_user(request, f"{count} adjustments approved.")
    
    def reject_adjustments(self, request, queryset):
        """Bulk reject adjustments."""
        from django.utils import timezone
        count = queryset.filter(status='pending').update(
            status='rejected',
            approved_by=request.user,
            approved_at=timezone.now()
        )
        self.message_user(request, f"{count} adjustments rejected.")


@admin.register(StoreTransfer)
class StoreTransferAdmin(admin.ModelAdmin):
    """Admin for StoreTransfer model."""
    
    list_display = ('transfer_number', 'from_store', 'to_store', 'product', 
                   'quantity', 'status', 'initiated_at')
    list_filter = ('status', 'initiated_at', 'from_store', 'to_store')
    search_fields = ('transfer_number', 'product__name', 'notes')
    readonly_fields = ('transfer_number', 'initiated_at', 'shipped_at', 'received_at')


@admin.register(PriceHistory)
class PriceHistoryAdmin(admin.ModelAdmin):
    """Admin for PriceHistory model."""
    
    list_display = ('product', 'old_selling_price', 'new_selling_price', 
                   'changed_by', 'changed_at')
    list_filter = ('changed_at', 'changed_by')
    search_fields = ('product__name', 'reason')
    readonly_fields = ('product', 'old_cost_price', 'new_cost_price', 
                      'old_selling_price', 'new_selling_price', 
                      'reason', 'changed_by', 'changed_at')
    
    def has_add_permission(self, request):
        """Prevent manual creation of price history."""
        return False


@admin.register(SupplierContract)
class SupplierContractAdmin(admin.ModelAdmin):
    """Admin for SupplierContract model."""
    
    list_display = ('contract_number', 'supplier', 'start_date', 'end_date', 
                   'status', 'is_active')
    list_filter = ('status', 'start_date', 'end_date')
    search_fields = ('contract_number', 'supplier__name', 'notes')
    readonly_fields = ('created_at', 'updated_at', 'is_active', 'days_until_expiry')
    
    def is_active(self, obj):
        """Display active status."""
        return obj.is_active
    is_active.boolean = True


# ==================== EXPIRY & SHELF MANAGEMENT SYSTEM ADMIN ====================

@admin.register(ProductBatch)
class ProductBatchAdmin(admin.ModelAdmin):
    """Admin for ProductBatch model."""
    
    list_display = ('id', 'product', 'batch_number', 'gtin', 'quantity', 
                   'expiry_date', 'status', 'expiry_status_display', 'store')
    list_filter = ('status', 'store', 'expiry_date', 'supplier')
    search_fields = ('gtin', 'batch_number', 'product__name', 'shipment_number', 'invoice_number')
    readonly_fields = ('days_until_expiry', 'expiry_status', 'total_value', 'received_date', 
                      'created_at', 'updated_at')
    date_hierarchy = 'expiry_date'
    
    fieldsets = (
        ('GS1-128 Information', {
            'fields': ('gtin', 'batch_number', 'gs1_barcode')
        }),
        ('Product & Quantity', {
            'fields': ('product', 'quantity', 'original_quantity')
        }),
        ('Dates', {
            'fields': ('expiry_date', 'manufacture_date', 'received_date')
        }),
        ('Supplier & Shipment', {
            'fields': ('supplier', 'shipment_number', 'invoice_number', 'purchase_order')
        }),
        ('Pricing', {
            'fields': ('unit_cost', 'unit_selling_price', 'total_value')
        }),
        ('Status & Location', {
            'fields': ('status', 'store', 'received_by')
        }),
        ('Expiry Status', {
            'fields': ('days_until_expiry', 'expiry_status'),
            'classes': ('collapse',)
        }),
    )
    
    def expiry_status_display(self, obj):
        """Color-coded expiry status."""
        status = obj.expiry_status
        colors = {'fresh': 'green', 'warning': 'orange', 'critical': 'red', 'expired': 'darkred'}
        return f'<span style="color: {colors.get(status, "black")};">{status.upper()}</span>'
    expiry_status_display.short_description = 'Expiry Status'
    expiry_status_display.allow_tags = True


@admin.register(ShelfLocation)
class ShelfLocationAdmin(admin.ModelAdmin):
    """Admin for ShelfLocation model."""
    
    list_display = ('location_code', 'store', 'aisle', 'section', 'position', 
                   'capacity', 'is_active')
    list_filter = ('store', 'is_active', 'aisle')
    search_fields = ('location_code', 'aisle', 'section', 'description')
    readonly_fields = ('created_at', 'updated_at', 'full_location')


@admin.register(BatchLocation)
class BatchLocationAdmin(admin.ModelAdmin):
    """Admin for BatchLocation model."""
    
    list_display = ('batch', 'shelf_location', 'quantity', 'placed_at', 'placed_by', 'is_active')
    list_filter = ('is_active', 'placed_at', 'shelf_location__store')
    search_fields = ('batch__batch_number', 'shelf_location__location_code')
    readonly_fields = ('placed_at',)


@admin.register(ReceivingLog)
class ReceivingLogAdmin(admin.ModelAdmin):
    """Admin for ReceivingLog model."""
    
    list_display = ('receipt_number', 'store', 'supplier', 'received_date', 
                   'total_items', 'total_value', 'status', 'has_expiry_issues')
    list_filter = ('status', 'has_expiry_issues', 'store', 'received_date')
    search_fields = ('receipt_number', 'shipment_number', 'invoice_number', 
                    'purchase_order', 'supplier__name')
    readonly_fields = ('received_date', 'created_at', 'updated_at')
    date_hierarchy = 'received_date'
    
    fieldsets = (
        ('Reference Numbers', {
            'fields': ('receipt_number', 'shipment_number', 'invoice_number', 'purchase_order')
        }),
        ('Supplier & Store', {
            'fields': ('supplier', 'store')
        }),
        ('Photos', {
            'fields': ('pallet_photo', 'invoice_photo')
        }),
        ('Validation', {
            'fields': ('has_expiry_issues', 'validation_notes')
        }),
        ('Totals', {
            'fields': ('total_items', 'total_value')
        }),
        ('Status & Staff', {
            'fields': ('status', 'received_by', 'approved_by', 'notes')
        }),
    )


@admin.register(ShelfAudit)
class ShelfAuditAdmin(admin.ModelAdmin):
    """Admin for ShelfAudit model."""
    
    list_display = ('audit_number', 'store', 'audit_date', 'scope', 'items_checked', 
                   'items_expired', 'items_near_expiry', 'status')
    list_filter = ('status', 'scope', 'store', 'audit_date')
    search_fields = ('audit_number', 'notes', 'auditor__email')
    readonly_fields = ('audit_date', 'created_at', 'updated_at')
    date_hierarchy = 'audit_date'


@admin.register(AuditItem)
class AuditItemAdmin(admin.ModelAdmin):
    """Admin for AuditItem model."""
    
    list_display = ('audit', 'batch', 'quantity_found', 'quantity_expected', 
                   'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('audit__audit_number', 'batch__batch_number', 'notes')
    readonly_fields = ('created_at',)


@admin.register(ExpiryAlert)
class ExpiryAlertAdmin(admin.ModelAdmin):
    """Admin for ExpiryAlert model."""
    
    list_display = ('id', 'batch', 'severity', 'days_until_expiry', 'quantity_at_risk', 
                   'estimated_loss', 'is_acknowledged', 'is_resolved')
    list_filter = ('severity', 'is_acknowledged', 'is_resolved', 'store', 'created_at')
    search_fields = ('batch__batch_number', 'batch__product__name')
    readonly_fields = ('created_at', 'updated_at', 'acknowledged_at', 'resolved_at')
    
    fieldsets = (
        ('Alert Details', {
            'fields': ('batch', 'store', 'shelf_location', 'severity', 'days_until_expiry')
        }),
        ('Risk Assessment', {
            'fields': ('quantity_at_risk', 'estimated_loss')
        }),
        ('Suggested Actions', {
            'fields': ('suggested_action', 'suggested_discount')
        }),
        ('Acknowledgment', {
            'fields': ('is_acknowledged', 'acknowledged_by', 'acknowledged_at')
        }),
        ('Resolution', {
            'fields': ('is_resolved', 'resolution_action', 'resolved_by', 
                      'resolved_at', 'resolution_notes')
        }),
    )


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    """Admin for Task model."""
    
    list_display = ('title', 'assigned_to', 'task_type', 'priority', 'due_date', 
                   'status', 'store')
    list_filter = ('task_type', 'priority', 'status', 'store', 'due_date')
    search_fields = ('title', 'description', 'assigned_to__email')
    readonly_fields = ('created_at', 'updated_at', 'completed_at')
    date_hierarchy = 'due_date'
    
    fieldsets = (
        ('Task Information', {
            'fields': ('title', 'description', 'task_type', 'priority')
        }),
        ('Assignment', {
            'fields': ('assigned_to', 'assigned_by', 'store')
        }),
        ('References', {
            'fields': ('shelf_location', 'batch', 'alert')
        }),
        ('Timing', {
            'fields': ('due_date', 'status')
        }),
        ('Completion', {
            'fields': ('completed_at', 'completion_notes', 'completion_photo')
        }),
    )


@admin.register(PhotoEvidence)
class PhotoEvidenceAdmin(admin.ModelAdmin):
    """Admin for PhotoEvidence model."""
    
    list_display = ('id', 'photo_type', 'store', 'uploaded_by', 'uploaded_at', 
                   'caption')
    list_filter = ('photo_type', 'store', 'uploaded_at')
    search_fields = ('caption', 'description', 'uploaded_by__email')
    readonly_fields = ('uploaded_at',)
    
    fieldsets = (
        ('Photo Information', {
            'fields': ('image', 'caption', 'description', 'photo_type')
        }),
        ('References', {
            'fields': ('batch', 'receiving_log', 'audit', 'task', 'shelf_location')
        }),
        ('Metadata', {
            'fields': ('store', 'uploaded_by', 'uploaded_at')
        }),
        ('Location', {
            'fields': ('latitude', 'longitude')
        }),
    )
