"""
Product and Category models for inventory management.
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from decimal import Decimal

# Import new feature models
from .smart_pricing_models import (
    PricingRule,
    DynamicPrice,
    PriceChangeHistory,
    CompetitorPrice,
    PriceElasticity,
)

from .iot_models import (
    IoTDevice,
    SensorReading,
    TemperatureMonitoring,
    SmartShelfEvent,
    DoorTrafficAnalytics,
    IoTAlert,
)

from .supplier_models import (
    # Supplier and SupplierPerformance already defined above in this file
    # Only importing new models from supplier_models.py
    AutomatedReorder,
    SupplierCommunication,
    SupplierReview,
)

from .sustainability_models import (
    SustainabilityMetrics,
    ProductCarbonFootprint,
    WasteRecord,
    SustainabilityInitiative,
    GreenSupplierRating,
)

User = get_user_model()


class Category(models.Model):
    """Product category model."""
    
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    icon = models.CharField(max_length=50, blank=True, null=True, help_text="Icon name or emoji")
    color = models.CharField(max_length=7, default="#3498db", help_text="Hex color code")
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='categories')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name_plural = 'Categories'
        ordering = ['name']
    
    def __str__(self):
        return self.name


class Supplier(models.Model):
    """Supplier model for tracking product suppliers."""
    
    name = models.CharField(max_length=255)
    contact_person = models.CharField(max_length=255, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='suppliers')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
    
    def __str__(self):
        return self.name


class Product(models.Model):
    """Product model for inventory management."""
    
    EXPIRY_STATUS_CHOICES = [
        ('expired', 'Expired'),
        ('expiring_soon', 'Expiring Soon'),
        ('fresh', 'Fresh'),
    ]
    
    # Basic Information
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='products')
    supplier = models.ForeignKey(Supplier, on_delete=models.SET_NULL, null=True, blank=True, related_name='products')
    
    # Inventory Information
    barcode = models.CharField(max_length=100, unique=True)
    sku = models.CharField(max_length=100, blank=True, null=True, help_text="Stock Keeping Unit")
    quantity = models.IntegerField(validators=[MinValueValidator(0)], default=0)
    min_stock_level = models.IntegerField(
        validators=[MinValueValidator(0)], 
        default=10,
        help_text="Alert when stock falls below this level"
    )
    
    # Pricing
    cost_price = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        validators=[MinValueValidator(0)],
        help_text="Purchase cost per unit"
    )
    selling_price = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        validators=[MinValueValidator(0)],
        help_text="Retail price per unit"
    )
    
    # Dates
    expiry_date = models.DateField()
    manufacture_date = models.DateField(blank=True, null=True)
    
    # Additional Information
    batch_number = models.CharField(max_length=100, blank=True, null=True)
    location = models.CharField(max_length=255, blank=True, null=True, help_text="Storage location in warehouse")
    image = models.ImageField(upload_to='products/', blank=True, null=True)
    
    # New advanced fields
    store = models.ForeignKey('Store', on_delete=models.SET_NULL, null=True, blank=True, related_name='products')
    reorder_level = models.IntegerField(default=20, validators=[MinValueValidator(0)], help_text="Automatic reorder trigger level")
    reorder_quantity = models.IntegerField(default=50, validators=[MinValueValidator(0)], help_text="Quantity to order when reordering")
    is_featured = models.BooleanField(default=False, help_text="Feature this product on dashboard")
    tags = models.CharField(max_length=500, blank=True, null=True, help_text="Comma-separated tags")
    is_deleted = models.BooleanField(default=False)
    
    # Metadata
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='products')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['barcode']),
            models.Index(fields=['expiry_date']),
            models.Index(fields=['category']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.barcode})"
    
    def get_expiry_status(self):
        """Determine expiry status based on expiry date."""
        if not self.expiry_date:
            return 'unknown'
        
        today = timezone.now().date()
        days_until_expiry = (self.expiry_date - today).days
        
        if days_until_expiry < 0:
            return 'expired'
        elif days_until_expiry <= 7:
            return 'expiring_soon'
        else:
            return 'fresh'

    @property
    def expiry_status(self):
        """Compatibility property for admin/display which returns the expiry status."""
        return self.get_expiry_status()
    
    @property
    def days_until_expiry(self):
        """Calculate days until expiry."""
        if not self.expiry_date:
            return None
        
        today = timezone.now().date()
        return (self.expiry_date - today).days
    
    @property
    def is_low_stock(self):
        """Check if product is low in stock."""
        return self.quantity <= self.min_stock_level
    
    @property
    def profit_margin(self):
        """Calculate profit margin percentage."""
        if self.cost_price == 0:
            return 0
        return ((self.selling_price - self.cost_price) / self.cost_price) * 100
    
    @property
    def total_value(self):
        """Calculate total inventory value."""
        return self.quantity * self.cost_price


class StockMovement(models.Model):
    """Track stock movements (additions, sales, wastage)."""
    
    MOVEMENT_TYPE_CHOICES = [
        ('in', 'Stock In'),
        ('out', 'Stock Out'),
        ('adjustment', 'Adjustment'),
        ('wastage', 'Wastage'),
    ]
    
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='stock_movements')
    movement_type = models.CharField(max_length=20, choices=MOVEMENT_TYPE_CHOICES)
    quantity = models.IntegerField(validators=[MinValueValidator(1)])
    
    # Details
    reason = models.TextField(blank=True, null=True)
    reference_number = models.CharField(max_length=100, blank=True, null=True)
    
    # Price at time of movement
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    
    # Metadata
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='stock_movements')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.movement_type} - {self.product.name} ({self.quantity})"


class Store(models.Model):
    """Enhanced Store model for multi-store management."""
    
    STORE_TYPES = [
        ('main', 'Main Store'),
        ('branch', 'Branch Store'),
        ('warehouse', 'Warehouse'),
        ('franchise', 'Franchise'),
    ]
    
    STORE_STATUS = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('maintenance', 'Under Maintenance'),
        ('closed', 'Permanently Closed'),
    ]
    
    # Basic information
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=20, unique=True)
    store_type = models.CharField(max_length=20, choices=STORE_TYPES, default='branch')
    status = models.CharField(max_length=20, choices=STORE_STATUS, default='active')
    
    # Location information
    address = models.TextField(blank=True, default='')
    city = models.CharField(max_length=100, default='')
    state = models.CharField(max_length=100, default='')
    postal_code = models.CharField(max_length=20, blank=True, default='')
    country = models.CharField(max_length=100, default='USA')
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    
    # Contact information
    phone = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    manager = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='managed_stores')
    
    # Business information
    opening_hours = models.JSONField(default=dict, help_text='Store opening hours by day')
    timezone = models.CharField(max_length=50, default='UTC')
    currency = models.CharField(max_length=10, default='USD')
    
    # Operational settings
    auto_reorder_enabled = models.BooleanField(default=True)
    inter_store_transfers_enabled = models.BooleanField(default=True)
    centralized_inventory = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='created_stores')
    
    class Meta:
        ordering = ['name']
        indexes = [
            models.Index(fields=['code']),
            models.Index(fields=['store_type']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.code})"
    
    @property
    def total_products(self):
        return self.store_inventories.count()
    
    @property
    def total_stock_value(self):
        from django.db.models import Sum, F
        return self.store_inventories.aggregate(
            total=Sum(F('current_stock') * F('product__cost_price'))
        )['total'] or Decimal('0.00')


class ProductFavorite(models.Model):
    """User's favorite products for quick access."""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorite_products')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='favorited_by')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'product')
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.email} - {self.product.name}"


class ShoppingList(models.Model):
    """Shopping list model for tracking items to purchase."""
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    name = models.CharField(max_length=255, default='My Shopping List')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    notes = models.TextField(blank=True, null=True)
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='shopping_lists')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} - {self.status}"
    
    @property
    def total_items(self):
        return self.items.count()
    
    @property
    def completed_items(self):
        return self.items.filter(is_purchased=True).count()
    
    @property
    def estimated_total(self):
        """Calculate estimated total cost."""
        return sum(item.estimated_cost for item in self.items.all())


class ShoppingListItem(models.Model):
    """Items in a shopping list."""
    
    shopping_list = models.ForeignKey(ShoppingList, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, null=True, blank=True)
    
    # Can be free-form if product is not in inventory yet
    item_name = models.CharField(max_length=255)
    quantity = models.IntegerField(validators=[MinValueValidator(1)], default=1)
    estimated_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    is_purchased = models.BooleanField(default=False)
    notes = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['is_purchased', '-created_at']
    
    def __str__(self):
        return f"{self.item_name} x{self.quantity}"
    
    @property
    def estimated_cost(self):
        """Calculate total cost for this item."""
        return self.quantity * self.estimated_price


class PurchaseOrder(models.Model):
    """Purchase orders for supplier orders."""
    
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('sent', 'Sent to Supplier'),
        ('confirmed', 'Confirmed'),
        ('received', 'Received'),
        ('cancelled', 'Cancelled'),
    ]
    
    order_number = models.CharField(max_length=100, unique=True)
    supplier = models.ForeignKey(Supplier, on_delete=models.CASCADE, related_name='purchase_orders')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    order_date = models.DateField(default=timezone.now)
    expected_delivery = models.DateField(blank=True, null=True)
    actual_delivery = models.DateField(blank=True, null=True)
    
    notes = models.TextField(blank=True, null=True)
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='purchase_orders')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"PO-{self.order_number} - {self.supplier.name}"
    
    @property
    def total_amount(self):
        """Calculate total order amount."""
        return sum(item.total_price for item in self.items.all())
    
    @property
    def total_items(self):
        return self.items.count()


class PurchaseOrderItem(models.Model):
    """Items in a purchase order."""
    
    purchase_order = models.ForeignKey(PurchaseOrder, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    
    quantity = models.IntegerField(validators=[MinValueValidator(1)])
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    received_quantity = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    
    notes = models.TextField(blank=True, null=True)
    
    class Meta:
        ordering = ['id']
    
    def __str__(self):
        return f"{self.product.name} x{self.quantity}"
    
    @property
    def total_price(self):
        """Calculate total price for this item."""
        return self.quantity * self.unit_price
    
    @property
    def is_fully_received(self):
        return self.received_quantity >= self.quantity


class ProductReview(models.Model):
    """Customer reviews and ratings for products."""
    
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='product_reviews')
    
    rating = models.IntegerField(validators=[MinValueValidator(1)], help_text="Rating from 1-5")
    review_text = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('product', 'user')
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.product.name} - {self.rating}/5"


class Notification(models.Model):
    """Real-time notifications for users."""
    
    NOTIFICATION_TYPES = [
        ('low_stock', 'Low Stock Alert'),
        ('expiry_warning', 'Expiry Warning'),
        ('expiry_critical', 'Product Expired'),
        ('reorder_suggestion', 'Reorder Suggestion'),
        ('price_change', 'Price Changed'),
        ('new_order', 'New Purchase Order'),
        ('order_received', 'Order Received'),
        ('system', 'System Notification'),
        ('info', 'Information'),
    ]
    
    PRIORITY_LEVELS = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    priority = models.CharField(max_length=10, choices=PRIORITY_LEVELS, default='medium')
    
    title = models.CharField(max_length=255)
    message = models.TextField()
    
    # Related objects (optional)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, null=True, blank=True, related_name='notifications')
    purchase_order = models.ForeignKey(PurchaseOrder, on_delete=models.CASCADE, null=True, blank=True, related_name='notifications')
    
    # Metadata
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    action_url = models.CharField(max_length=500, blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_read']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.user.email}"
    
    def mark_as_read(self):
        """Mark notification as read."""
        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save()


class AuditLog(models.Model):
    """Comprehensive audit logging for all critical operations."""
    
    ACTION_TYPES = [
        ('create', 'Created'),
        ('update', 'Updated'),
        ('delete', 'Deleted'),
        ('view', 'Viewed'),
        ('export', 'Exported'),
        ('import', 'Imported'),
        ('login', 'Logged In'),
        ('logout', 'Logged Out'),
        ('stock_in', 'Stock Added'),
        ('stock_out', 'Stock Removed'),
        ('price_change', 'Price Changed'),
        ('transfer', 'Transferred'),
    ]
    
    # Who & When
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='audit_logs')
    action = models.CharField(max_length=20, choices=ACTION_TYPES)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    # What
    model_name = models.CharField(max_length=100)
    object_id = models.CharField(max_length=100, null=True, blank=True)
    object_repr = models.CharField(max_length=500, blank=True)
    
    # Details
    changes = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=500, blank=True, null=True)
    
    # Context
    success = models.BooleanField(default=True)
    error_message = models.TextField(blank=True, null=True)
    
    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['user', 'timestamp']),
            models.Index(fields=['model_name', 'object_id']),
            models.Index(fields=['action']),
        ]
    
    def __str__(self):
        return f"{self.user} - {self.action} - {self.model_name} ({self.timestamp})"


class Currency(models.Model):
    """Multi-currency support."""
    
    code = models.CharField(max_length=3, unique=True, help_text="ISO 4217 currency code (e.g., USD, EUR)")
    name = models.CharField(max_length=100)
    symbol = models.CharField(max_length=10)
    exchange_rate = models.DecimalField(
        max_digits=12,
        decimal_places=6,
        default=1.0,
        help_text="Exchange rate to base currency"
    )
    is_base_currency = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    
    last_updated = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name_plural = 'Currencies'
        ordering = ['code']
    
    def __str__(self):
        return f"{self.code} ({self.symbol})"
    
    def save(self, *args, **kwargs):
        """Ensure only one base currency exists."""
        if self.is_base_currency:
            Currency.objects.filter(is_base_currency=True).update(is_base_currency=False)
            self.exchange_rate = 1.0
        super().save(*args, **kwargs)


class InventoryAdjustment(models.Model):
    """Detailed inventory adjustments with approval workflow."""
    
    STATUS_CHOICES = [
        ('pending', 'Pending Approval'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('completed', 'Completed'),
    ]
    
    REASON_CHOICES = [
        ('damage', 'Damaged Goods'),
        ('theft', 'Theft/Loss'),
        ('recount', 'Physical Recount'),
        ('return', 'Customer Return'),
        ('expired', 'Expired Product'),
        ('system_error', 'System Error Correction'),
        ('transfer', 'Store Transfer'),
        ('other', 'Other'),
    ]
    
    adjustment_number = models.CharField(max_length=50, unique=True, editable=False)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='adjustments')
    
    quantity_before = models.IntegerField()
    quantity_after = models.IntegerField()
    adjustment_quantity = models.IntegerField(help_text="Positive for increase, negative for decrease")
    
    reason = models.CharField(max_length=20, choices=REASON_CHOICES)
    notes = models.TextField(blank=True, null=True)
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Approval workflow
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_adjustments')
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_adjustments')
    
    created_at = models.DateTimeField(auto_now_add=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    
    # Evidence
    photo_evidence = models.ImageField(upload_to='adjustments/', null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.adjustment_number} - {self.product.name}"
    
    def save(self, *args, **kwargs):
        """Generate adjustment number if not exists."""
        if not self.adjustment_number:
            from datetime import datetime
            self.adjustment_number = f"ADJ{datetime.now().strftime('%Y%m%d%H%M%S')}"
        super().save(*args, **kwargs)


class StoreTransfer(models.Model):
    """Track inventory transfers between stores."""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_transit', 'In Transit'),
        ('received', 'Received'),
        ('cancelled', 'Cancelled'),
    ]
    
    transfer_number = models.CharField(max_length=50, unique=True, editable=False)
    
    from_store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='transfers_out')
    to_store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='transfers_in')
    
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='transfers')
    quantity = models.IntegerField(validators=[MinValueValidator(1)])
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    notes = models.TextField(blank=True, null=True)
    
    # Tracking
    initiated_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='initiated_transfers')
    received_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='received_transfers')
    
    initiated_at = models.DateTimeField(auto_now_add=True)
    shipped_at = models.DateTimeField(null=True, blank=True)
    received_at = models.DateTimeField(null=True, blank=True)
    expected_arrival = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-initiated_at']
    
    def __str__(self):
        return f"{self.transfer_number}: {self.from_store} → {self.to_store}"
    
    def save(self, *args, **kwargs):
        """Generate transfer number if not exists."""
        if not self.transfer_number:
            from datetime import datetime
            self.transfer_number = f"TRF{datetime.now().strftime('%Y%m%d%H%M%S')}"
        super().save(*args, **kwargs)


class PriceHistory(models.Model):
    """Track all price changes for products."""
    
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='price_history')
    
    old_cost_price = models.DecimalField(max_digits=10, decimal_places=2)
    new_cost_price = models.DecimalField(max_digits=10, decimal_places=2)
    
    old_selling_price = models.DecimalField(max_digits=10, decimal_places=2)
    new_selling_price = models.DecimalField(max_digits=10, decimal_places=2)
    
    reason = models.CharField(max_length=500, blank=True, null=True)
    changed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='price_changes')
    changed_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-changed_at']
        verbose_name_plural = 'Price Histories'
    
    def __str__(self):
        return f"{self.product.name} - {self.changed_at}"
    
    @property
    def cost_price_change_percent(self):
        """Calculate cost price change percentage."""
        if self.old_cost_price == 0:
            return 0
        return ((self.new_cost_price - self.old_cost_price) / self.old_cost_price) * 100
    
    @property
    def selling_price_change_percent(self):
        """Calculate selling price change percentage."""
        if self.old_selling_price == 0:
            return 0
        return ((self.new_selling_price - self.old_selling_price) / self.old_selling_price) * 100


class SupplierContract(models.Model):
    """Manage supplier contracts and agreements."""
    
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('terminated', 'Terminated'),
    ]
    
    contract_number = models.CharField(max_length=100, unique=True)
    supplier = models.ForeignKey(Supplier, on_delete=models.CASCADE, related_name='contracts')
    
    start_date = models.DateField()
    end_date = models.DateField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    # Terms
    payment_terms = models.CharField(max_length=255, help_text="e.g., Net 30, Net 60")
    minimum_order_value = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    discount_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    
    # Documents
    contract_document = models.FileField(upload_to='contracts/', null=True, blank=True)
    notes = models.TextField(blank=True, null=True)
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='supplier_contracts')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.contract_number} - {self.supplier.name}"
    
    @property
    def is_active(self):
        """Check if contract is currently active."""
        today = timezone.now().date()
        return self.status == 'active' and self.start_date <= today <= self.end_date
    
    @property
    def days_until_expiry(self):
        """Days until contract expires."""
        if not self.end_date:
            return None
        return (self.end_date - timezone.now().date()).days


# ==================== EXPIRY & SHELF MANAGEMENT SYSTEM MODELS ====================

class ProductBatch(models.Model):
    """
    Batch-level tracking for products with GS1-128 barcode support.
    Enables precise expiry management and traceability.
    """
    
    # GS1-128 Barcode Information
    gtin = models.CharField(max_length=14, help_text="Global Trade Item Number (AI 01)")
    batch_number = models.CharField(max_length=100, help_text="Batch/Lot Number (AI 10)")
    gs1_barcode = models.CharField(max_length=200, blank=True, null=True, help_text="Full GS1-128 barcode string")
    
    # Product Reference
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='batches')
    
    # Batch Details
    quantity = models.IntegerField(validators=[MinValueValidator(0)], default=0)
    original_quantity = models.IntegerField(validators=[MinValueValidator(0)], help_text="Initial quantity received")
    
    # Dates from GS1
    expiry_date = models.DateField(help_text="Expiry Date (AI 17)")
    manufacture_date = models.DateField(blank=True, null=True, help_text="Production Date (AI 11)")
    received_date = models.DateTimeField(auto_now_add=True)
    
    # Supplier & Shipment
    supplier = models.ForeignKey(Supplier, on_delete=models.SET_NULL, null=True, related_name='batches')
    shipment_number = models.CharField(max_length=100, blank=True, null=True)
    invoice_number = models.CharField(max_length=100, blank=True, null=True)
    purchase_order = models.CharField(max_length=100, blank=True, null=True)
    
    # Pricing at time of receipt
    unit_cost = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    unit_selling_price = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    
    # Status
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('depleted', 'Depleted'),
        ('expired', 'Expired'),
        ('recalled', 'Recalled'),
        ('damaged', 'Damaged'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    
    # Store & Location
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='batches')
    
    # Metadata
    received_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='received_batches')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['expiry_date', '-created_at']
        unique_together = ['gtin', 'batch_number', 'store']
        indexes = [
            models.Index(fields=['gtin', 'batch_number']),
            models.Index(fields=['expiry_date']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - Batch {self.batch_number} (Exp: {self.expiry_date})"
    
    @property
    def days_until_expiry(self):
        """Calculate days until expiry."""
        return (self.expiry_date - timezone.now().date()).days
    
    @property
    def expiry_status(self):
        """Determine expiry status."""
        days = self.days_until_expiry
        if days < 0:
            return 'expired'
        elif days <= 7:
            return 'critical'
        elif days <= 30:
            return 'warning'
        else:
            return 'fresh'
    
    @property
    def total_value(self):
        """Calculate total inventory value for this batch."""
        return self.quantity * self.unit_cost


class ShelfLocation(models.Model):
    """
    Physical shelf/storage location in store with QR code support.
    Maps store layout for easy navigation and accountability.
    """
    
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='shelf_locations')
    
    # Location Hierarchy
    aisle = models.CharField(max_length=50, help_text="Aisle number/name (e.g., 'A3', 'Dairy Aisle')")
    section = models.CharField(max_length=50, help_text="Section within aisle (e.g., 'Top Shelf', 'Section 2')")
    position = models.CharField(max_length=50, blank=True, null=True, help_text="Specific position (e.g., 'Left Corner')")
    
    # Full location code
    location_code = models.CharField(max_length=100, unique=True, help_text="Unique code like 'A3-S2-L'")
    
    # QR Code
    qr_code = models.CharField(max_length=200, blank=True, null=True, help_text="QR code for this location")
    qr_code_image = models.ImageField(upload_to='shelf_qr_codes/', blank=True, null=True)
    
    # Capacity
    capacity = models.IntegerField(blank=True, null=True, help_text="Maximum units this location can hold")
    
    # Description & Notes
    description = models.TextField(blank=True, null=True)
    
    # Layout coordinates (optional for map view)
    x_coordinate = models.FloatField(blank=True, null=True)
    y_coordinate = models.FloatField(blank=True, null=True)
    
    # Metadata
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_locations')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['aisle', 'section', 'position']
        unique_together = ['store', 'aisle', 'section', 'position']
    
    def __str__(self):
        return f"{self.store.code} - {self.location_code}"
    
    @property
    def full_location(self):
        """Get full location description."""
        parts = [f"Aisle {self.aisle}", f"Section {self.section}"]
        if self.position:
            parts.append(self.position)
        return " → ".join(parts)


class BatchLocation(models.Model):
    """
    Links product batches to specific shelf locations.
    Tracks exactly where each batch is stored.
    """
    
    batch = models.ForeignKey(ProductBatch, on_delete=models.CASCADE, related_name='locations')
    shelf_location = models.ForeignKey(ShelfLocation, on_delete=models.CASCADE, related_name='batches')
    
    quantity = models.IntegerField(validators=[MinValueValidator(0)], help_text="Quantity at this location")
    
    # Placement details
    placed_at = models.DateTimeField(auto_now_add=True)
    placed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='placed_batches')
    
    # Photo evidence
    placement_photo = models.ImageField(upload_to='shelf_photos/', blank=True, null=True)
    
    # Notes
    notes = models.TextField(blank=True, null=True)
    
    is_active = models.BooleanField(default=True, help_text="False when batch is removed from this location")
    
    class Meta:
        ordering = ['-placed_at']
        unique_together = ['batch', 'shelf_location']
    
    def __str__(self):
        return f"{self.batch} @ {self.shelf_location.location_code}"


class ReceivingLog(models.Model):
    """
    Complete log of warehouse/receiving gate activities.
    Captures all inbound stock with photos and validation.
    """
    
    # Reference Numbers
    receipt_number = models.CharField(max_length=100, unique=True)
    shipment_number = models.CharField(max_length=100, blank=True, null=True)
    invoice_number = models.CharField(max_length=100, blank=True, null=True)
    purchase_order = models.CharField(max_length=100, blank=True, null=True)
    
    # Supplier
    supplier = models.ForeignKey(Supplier, on_delete=models.SET_NULL, null=True, related_name='receiving_logs')
    
    # Store
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='receiving_logs')
    
    # Date & Time
    received_date = models.DateTimeField(auto_now_add=True)
    
    # Batches received
    batches = models.ManyToManyField(ProductBatch, related_name='receiving_logs')
    
    # Photo evidence (pallet/carton photos)
    pallet_photo = models.ImageField(upload_to='receiving_photos/', blank=True, null=True)
    invoice_photo = models.ImageField(upload_to='receiving_photos/', blank=True, null=True)
    
    # Validation
    has_expiry_issues = models.BooleanField(default=False, help_text="True if any items are expired/near-expiry on arrival")
    validation_notes = models.TextField(blank=True, null=True)
    
    # Totals
    total_items = models.IntegerField(default=0)
    total_value = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    # Status
    STATUS_CHOICES = [
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('partial', 'Partially Accepted'),
        ('rejected', 'Rejected'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Staff
    received_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='receiving_activities')
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_receivings')
    
    # Notes
    notes = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-received_date']
    
    def __str__(self):
        return f"Receipt {self.receipt_number} - {self.received_date.date()}"


class ShelfAudit(models.Model):
    """
    Periodic shelf audit/inspection logs.
    Staff verify shelf stock and expiry status with photo evidence.
    """
    
    # Audit Details
    audit_number = models.CharField(max_length=100, unique=True)
    audit_date = models.DateTimeField(auto_now_add=True)
    
    # Location
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='shelf_audits')
    shelf_location = models.ForeignKey(ShelfLocation, on_delete=models.SET_NULL, null=True, blank=True, related_name='audits')
    
    # Scope
    SCOPE_CHOICES = [
        ('full_store', 'Full Store Audit'),
        ('category', 'Category Audit'),
        ('location', 'Location Audit'),
        ('random', 'Random Spot Check'),
    ]
    scope = models.CharField(max_length=20, choices=SCOPE_CHOICES, default='location')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='audits')
    
    # Findings
    items_checked = models.IntegerField(default=0)
    items_expired = models.IntegerField(default=0)
    items_near_expiry = models.IntegerField(default=0)
    items_damaged = models.IntegerField(default=0)
    items_misplaced = models.IntegerField(default=0)
    
    # Photo Evidence
    audit_photos = models.JSONField(blank=True, null=True, help_text="Array of photo URLs")
    
    # Status
    STATUS_CHOICES = [
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('flagged', 'Issues Flagged'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='in_progress')
    
    # Staff
    auditor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='conducted_audits')
    
    # Notes & Actions
    notes = models.TextField(blank=True, null=True)
    action_required = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-audit_date']
    
    def __str__(self):
        return f"Audit {self.audit_number} - {self.audit_date.date()}"


class AuditItem(models.Model):
    """Individual item checked during shelf audit."""
    
    audit = models.ForeignKey(ShelfAudit, on_delete=models.CASCADE, related_name='audit_items')
    batch = models.ForeignKey(ProductBatch, on_delete=models.CASCADE, related_name='audit_records')
    
    # Findings
    quantity_found = models.IntegerField(validators=[MinValueValidator(0)])
    quantity_expected = models.IntegerField(blank=True, null=True)
    
    STATUS_CHOICES = [
        ('ok', 'OK'),
        ('expired', 'Expired'),
        ('near_expiry', 'Near Expiry'),
        ('damaged', 'Damaged'),
        ('misplaced', 'Misplaced'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ok')
    
    # Photo
    photo = models.ImageField(upload_to='audit_photos/', blank=True, null=True)
    
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.audit.audit_number} - {self.batch.product.name}"


class ExpiryAlert(models.Model):
    """
    Automated expiry alerts and notifications.
    Proactively notifies staff of expiring products.
    """
    
    batch = models.ForeignKey(ProductBatch, on_delete=models.CASCADE, related_name='expiry_alerts')
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='expiry_alerts')
    shelf_location = models.ForeignKey(ShelfLocation, on_delete=models.SET_NULL, null=True, blank=True, related_name='alerts')
    
    # Alert Level
    SEVERITY_CHOICES = [
        ('critical', 'Critical (< 7 days)'),
        ('high', 'High (7-15 days)'),
        ('medium', 'Medium (15-30 days)'),
        ('low', 'Low (30+ days)'),
    ]
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES)
    
    # Alert Details
    days_until_expiry = models.IntegerField()
    quantity_at_risk = models.IntegerField()
    estimated_loss = models.DecimalField(max_digits=10, decimal_places=2, help_text="Potential monetary loss")
    
    # Suggested Actions
    ACTION_CHOICES = [
        ('discount', 'Apply Discount'),
        ('clearance', 'Move to Clearance'),
        ('return', 'Return to Supplier'),
        ('dispose', 'Dispose'),
        ('none', 'No Action Needed'),
    ]
    suggested_action = models.CharField(max_length=20, choices=ACTION_CHOICES, default='none')
    suggested_discount = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True, help_text="Suggested discount %")
    
    # Status
    is_acknowledged = models.BooleanField(default=False)
    acknowledged_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='acknowledged_alerts')
    acknowledged_at = models.DateTimeField(blank=True, null=True)
    
    is_resolved = models.BooleanField(default=False)
    resolution_action = models.CharField(max_length=20, choices=ACTION_CHOICES, blank=True, null=True)
    resolved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='resolved_alerts')
    resolved_at = models.DateTimeField(blank=True, null=True)
    resolution_notes = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['days_until_expiry', '-created_at']
        indexes = [
            models.Index(fields=['severity', 'is_resolved']),
            models.Index(fields=['days_until_expiry']),
        ]
    
    def __str__(self):
        return f"{self.severity.upper()} - {self.batch.product.name} ({self.days_until_expiry} days)"


class Task(models.Model):
    """
    Staff task management for expiry-related actions.
    Assigns specific activities to team members.
    """
    
    # Task Details
    title = models.CharField(max_length=255)
    description = models.TextField()
    
    # Assignment
    assigned_to = models.ForeignKey(User, on_delete=models.CASCADE, related_name='assigned_tasks')
    assigned_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_tasks')
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='tasks')
    
    # Type
    TASK_TYPE_CHOICES = [
        ('shelf_check', 'Shelf Check'),
        ('expiry_review', 'Expiry Review'),
        ('restock', 'Restock Items'),
        ('dispose', 'Dispose Items'),
        ('discount', 'Apply Discount'),
        ('receive', 'Receive Shipment'),
        ('audit', 'Conduct Audit'),
        ('other', 'Other'),
    ]
    task_type = models.CharField(max_length=20, choices=TASK_TYPE_CHOICES)
    
    # Priority
    PRIORITY_CHOICES = [
        ('urgent', 'Urgent'),
        ('high', 'High'),
        ('medium', 'Medium'),
        ('low', 'Low'),
    ]
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    
    # References
    shelf_location = models.ForeignKey(ShelfLocation, on_delete=models.SET_NULL, null=True, blank=True, related_name='tasks')
    batch = models.ForeignKey(ProductBatch, on_delete=models.SET_NULL, null=True, blank=True, related_name='tasks')
    alert = models.ForeignKey(ExpiryAlert, on_delete=models.SET_NULL, null=True, blank=True, related_name='tasks')
    
    # Timing
    due_date = models.DateTimeField()
    
    # Status
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Completion
    completed_at = models.DateTimeField(blank=True, null=True)
    completion_notes = models.TextField(blank=True, null=True)
    completion_photo = models.ImageField(upload_to='task_photos/', blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['due_date', '-priority', '-created_at']
    
    def __str__(self):
        return f"{self.title} - {self.assigned_to.get_full_name()}"

class PhotoEvidence(models.Model):
    """
    Centralized photo management for accountability and compliance.
    Links photos to various entities (batches, audits, tasks, etc.)
    """
    
    # Photo Details
    image = models.ImageField(upload_to='evidence_photos/')
    caption = models.CharField(max_length=255, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    
    # Context
    PHOTO_TYPE_CHOICES = [
        ('receiving', 'Receiving/Warehouse'),
        ('shelf_placement', 'Shelf Placement'),
        ('audit', 'Audit'),
        ('task_completion', 'Task Completion'),
        ('expiry_issue', 'Expiry Issue'),
        ('damage', 'Damage Report'),
        ('other', 'Other'),
    ]
    photo_type = models.CharField(max_length=20, choices=PHOTO_TYPE_CHOICES)
    
    # References (optional linkage)
    batch = models.ForeignKey(ProductBatch, on_delete=models.SET_NULL, null=True, blank=True, related_name='photos')
    receiving_log = models.ForeignKey(ReceivingLog, on_delete=models.SET_NULL, null=True, blank=True, related_name='photos')
    audit = models.ForeignKey(ShelfAudit, on_delete=models.SET_NULL, null=True, blank=True, related_name='photos')
    task = models.ForeignKey(Task, on_delete=models.SET_NULL, null=True, blank=True, related_name='photos')
    shelf_location = models.ForeignKey(ShelfLocation, on_delete=models.SET_NULL, null=True, blank=True, related_name='photos')
    
    # Metadata
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='photos')
    uploaded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='uploaded_photos')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    # GPS location (optional)
    latitude = models.FloatField(blank=True, null=True)
    longitude = models.FloatField(blank=True, null=True)
    
    class Meta:
        ordering = ['-uploaded_at']
        verbose_name_plural = 'Photo Evidence'
    
    def __str__(self):
        return f"{self.photo_type} - {self.uploaded_at.date()}"


class NotificationPreference(models.Model):
    """
    User preferences for expiry alerts and notifications.
    Controls when and how users receive alerts.
    """
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='notification_preferences')
    
    # Email Notifications
    email_enabled = models.BooleanField(default=True)
    email_expiry_critical = models.BooleanField(default=True, help_text="Email for critical expiry (<7 days)")
    email_expiry_high = models.BooleanField(default=True, help_text="Email for high priority (7-15 days)")
    email_expiry_medium = models.BooleanField(default=False, help_text="Email for medium priority (15-30 days)")
    
    # Push Notifications
    push_enabled = models.BooleanField(default=True)
    push_expiry_critical = models.BooleanField(default=True)
    push_expiry_high = models.BooleanField(default=True)
    push_expiry_medium = models.BooleanField(default=False)
    push_task_assigned = models.BooleanField(default=True)
    push_task_due = models.BooleanField(default=True)
    
    # Digest Settings
    daily_digest = models.BooleanField(default=True, help_text="Receive daily summary email")
    weekly_digest = models.BooleanField(default=True, help_text="Receive weekly report")
    digest_time = models.TimeField(default='08:00', help_text="Time to send daily digest")
    
    # FCM Token for push notifications
    fcm_token = models.CharField(max_length=255, blank=True, null=True)
    
    # Quiet Hours
    quiet_hours_enabled = models.BooleanField(default=False)
    quiet_hours_start = models.TimeField(blank=True, null=True)
    quiet_hours_end = models.TimeField(blank=True, null=True)
    
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name_plural = 'Notification Preferences'
    
    def __str__(self):
        return f"Notification Preferences - {self.user.email}"


class WastageReport(models.Model):
    """
    Detailed wastage/loss reporting for expired or damaged products.
    Tracks monetary loss and reasons for compliance and analysis.
    """
    
    # Report Details
    report_number = models.CharField(max_length=100, unique=True)
    report_date = models.DateTimeField(auto_now_add=True)
    
    # Store
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='wastage_reports')
    
    # Reporting Period
    period_start = models.DateField()
    period_end = models.DateField()
    
    # Summary
    total_items_wasted = models.IntegerField(default=0)
    total_monetary_loss = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    # Breakdown by Reason
    WASTAGE_REASON_CHOICES = [
        ('expired', 'Expired'),
        ('near_expiry', 'Near Expiry (Unsold)'),
        ('damaged', 'Damaged'),
        ('recalled', 'Product Recall'),
        ('quality_issue', 'Quality Issue'),
        ('overstock', 'Overstock/Excess'),
        ('other', 'Other'),
    ]
    
    # Status
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('submitted', 'Submitted'),
        ('reviewed', 'Reviewed'),
        ('approved', 'Approved'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    # Compliance
    regulatory_report_filed = models.BooleanField(default=False)
    regulatory_reference = models.CharField(max_length=100, blank=True, null=True)
    
    # Staff
    prepared_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='prepared_wastage_reports')
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_wastage_reports')
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_wastage_reports')
    
    # Notes
    notes = models.TextField(blank=True, null=True)
    corrective_actions = models.TextField(blank=True, null=True, help_text="Actions taken to prevent future wastage")
    
    # Export
    report_pdf = models.FileField(upload_to='wastage_reports/', blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-report_date']
    
    def __str__(self):
        return f"Wastage Report {self.report_number} - {self.store.name}"


class WastageItem(models.Model):
    """Individual items in a wastage report."""
    
    wastage_report = models.ForeignKey(WastageReport, on_delete=models.CASCADE, related_name='items')
    batch = models.ForeignKey(ProductBatch, on_delete=models.SET_NULL, null=True, related_name='wastage_records')
    
    # Product details (snapshot in case batch is deleted)
    product_name = models.CharField(max_length=255)
    batch_number = models.CharField(max_length=100)
    expiry_date = models.DateField()
    
    # Wastage Details
    quantity_wasted = models.IntegerField(validators=[MinValueValidator(1)])
    unit_cost = models.DecimalField(max_digits=10, decimal_places=2)
    total_loss = models.DecimalField(max_digits=12, decimal_places=2)
    
    REASON_CHOICES = [
        ('expired', 'Expired'),
        ('near_expiry', 'Near Expiry (Unsold)'),
        ('damaged', 'Damaged'),
        ('recalled', 'Product Recall'),
        ('quality_issue', 'Quality Issue'),
        ('overstock', 'Overstock/Excess'),
        ('other', 'Other'),
    ]
    reason = models.CharField(max_length=20, choices=REASON_CHOICES)
    
    # Disposal
    disposal_method = models.CharField(max_length=100, blank=True, null=True, help_text="How item was disposed")
    disposal_date = models.DateField(blank=True, null=True)
    disposed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='disposed_items')
    
    # Evidence
    photo = models.ImageField(upload_to='wastage_photos/', blank=True, null=True)
    
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.product_name} - {self.quantity_wasted} units"
    
    def save(self, *args, **kwargs):
        """Calculate total loss automatically."""
        self.total_loss = self.quantity_wasted * self.unit_cost
        super().save(*args, **kwargs)


class ComplianceLog(models.Model):
    """
    Regulatory compliance and audit trail.
    Records all compliance-related activities for inspections.
    """
    
    # Log Details
    log_number = models.CharField(max_length=100, unique=True)
    log_date = models.DateTimeField(auto_now_add=True)
    
    # Store
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='compliance_logs')
    
    # Type
    LOG_TYPE_CHOICES = [
        ('inspection', 'Regulatory Inspection'),
        ('internal_audit', 'Internal Audit'),
        ('fssai', 'FSSAI Compliance'),
        ('supplier_audit', 'Supplier Audit'),
        ('batch_recall', 'Batch Recall'),
        ('expiry_disposal', 'Expiry Product Disposal'),
        ('training', 'Staff Training'),
        ('incident', 'Incident Report'),
        ('other', 'Other'),
    ]
    log_type = models.CharField(max_length=20, choices=LOG_TYPE_CHOICES)
    
    # Details
    title = models.CharField(max_length=255)
    description = models.TextField()
    
    # Regulatory Reference
    regulation_reference = models.CharField(max_length=200, blank=True, null=True, help_text="e.g., FSSAI License No.")
    inspector_name = models.CharField(max_length=255, blank=True, null=True)
    inspector_id = models.CharField(max_length=100, blank=True, null=True)
    
    # Outcome
    OUTCOME_CHOICES = [
        ('compliant', 'Compliant'),
        ('non_compliant', 'Non-Compliant'),
        ('partial', 'Partially Compliant'),
        ('pending', 'Pending Review'),
    ]
    outcome = models.CharField(max_length=20, choices=OUTCOME_CHOICES, blank=True, null=True)
    
    # Actions Required
    actions_required = models.TextField(blank=True, null=True)
    action_deadline = models.DateField(blank=True, null=True)
    action_completed = models.BooleanField(default=False)
    action_completion_date = models.DateField(blank=True, null=True)
    
    # Documents
    supporting_documents = models.JSONField(blank=True, null=True, help_text="Array of document URLs")
    certificate_issued = models.BooleanField(default=False)
    certificate_file = models.FileField(upload_to='compliance_certificates/', blank=True, null=True)
    
    # Staff
    logged_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='compliance_logs')
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_compliance_logs')
    
    # Related Records
    batches = models.ManyToManyField(ProductBatch, blank=True, related_name='compliance_logs')
    wastage_reports = models.ManyToManyField(WastageReport, blank=True, related_name='compliance_logs')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-log_date']
    
    def __str__(self):
        return f"{self.log_type} - {self.title} ({self.log_date.date()})"


class SupplierPerformance(models.Model):
    """
    Track supplier performance metrics for accountability.
    Monitors expiry issues, quality, and delivery performance.
    """
    
    supplier = models.ForeignKey(Supplier, on_delete=models.CASCADE, related_name='performance_records')
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='supplier_performance')
    
    # Time Period
    period_start = models.DateField()
    period_end = models.DateField()
    
    # Delivery Metrics
    total_deliveries = models.IntegerField(default=0)
    on_time_deliveries = models.IntegerField(default=0)
    late_deliveries = models.IntegerField(default=0)
    avg_delay_days = models.FloatField(default=0, help_text="Average delay in days")
    
    # Quality Metrics
    total_items_received = models.IntegerField(default=0)
    items_with_expiry_issues = models.IntegerField(default=0, help_text="Items expired or near-expiry on arrival")
    items_damaged = models.IntegerField(default=0)
    items_rejected = models.IntegerField(default=0)
    
    # Financial Impact
    total_value_received = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    value_of_issues = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text="Cost of rejected/damaged items")
    
    # Performance Score (0-100)
    quality_score = models.FloatField(default=0, help_text="0-100 based on quality metrics")
    delivery_score = models.FloatField(default=0, help_text="0-100 based on delivery metrics")
    overall_score = models.FloatField(default=0, help_text="Weighted average of all metrics")
    
    # Status
    STATUS_CHOICES = [
        ('excellent', 'Excellent'),
        ('good', 'Good'),
        ('acceptable', 'Acceptable'),
        ('poor', 'Poor'),
        ('critical', 'Critical'),
    ]
    performance_status = models.CharField(max_length=20, choices=STATUS_CHOICES, blank=True, null=True)
    
    # Notes & Actions
    notes = models.TextField(blank=True, null=True)
    action_plan = models.TextField(blank=True, null=True, help_text="Improvement plan for poor performers")
    
    # Metadata
    calculated_at = models.DateTimeField(auto_now=True)
    calculated_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='supplier_performance_calcs')
    
    class Meta:
        ordering = ['-period_end', 'overall_score']
        unique_together = ['supplier', 'store', 'period_start', 'period_end']
    
    def __str__(self):
        return f"{self.supplier.name} - {self.period_start} to {self.period_end} (Score: {self.overall_score})"
    
    def calculate_scores(self):
        """Calculate performance scores based on metrics."""
        # Quality Score (40% weight)
        if self.total_items_received > 0:
            issue_rate = (self.items_with_expiry_issues + self.items_damaged + self.items_rejected) / self.total_items_received
            self.quality_score = max(0, 100 - (issue_rate * 100))
        else:
            self.quality_score = 0
        
        # Delivery Score (30% weight)
        if self.total_deliveries > 0:
            on_time_rate = self.on_time_deliveries / self.total_deliveries
            delay_penalty = min(30, self.avg_delay_days * 3)  # Max 30 points penalty
            self.delivery_score = max(0, (on_time_rate * 100) - delay_penalty)
        else:
            self.delivery_score = 0
        
        # Overall Score (weighted average)
        self.overall_score = (self.quality_score * 0.4) + (self.delivery_score * 0.3) + (70 * 0.3)  # 30% baseline
        
        # Set status based on overall score
        if self.overall_score >= 90:
            self.performance_status = 'excellent'
        elif self.overall_score >= 75:
            self.performance_status = 'good'
        elif self.overall_score >= 60:
            self.performance_status = 'acceptable'
        elif self.overall_score >= 40:
            self.performance_status = 'poor'
        else:
            self.performance_status = 'critical'
        
        self.save()


class DynamicPricing(models.Model):
    """
    Automated dynamic pricing for near-expiry products.
    Reduces waste by automatically suggesting discounts.
    """
    
    batch = models.ForeignKey(ProductBatch, on_delete=models.CASCADE, related_name='dynamic_pricing')
    store = models.ForeignKey('Store', on_delete=models.CASCADE, related_name='dynamic_pricing')
    
    # Pricing Details
    original_price = models.DecimalField(max_digits=10, decimal_places=2)
    discount_percentage = models.DecimalField(max_digits=5, decimal_places=2, help_text="Discount %")
    discounted_price = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Timing
    effective_from = models.DateTimeField()
    effective_until = models.DateTimeField(blank=True, null=True)
    
    # Reason
    REASON_CHOICES = [
        ('near_expiry', 'Near Expiry'),
        ('expiring_soon', 'Expiring Soon'),
        ('overstock', 'Overstock'),
        ('clearance', 'Clearance'),
        ('promotional', 'Promotional'),
    ]
    reason = models.CharField(max_length=20, choices=REASON_CHOICES)
    days_to_expiry = models.IntegerField(blank=True, null=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    is_synced_to_pos = models.BooleanField(default=False, help_text="Synced to Point of Sale system")
    
    # Results
    quantity_sold = models.IntegerField(default=0)
    revenue_generated = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    waste_prevented = models.IntegerField(default=0, help_text="Units that would have expired")
    
    # Approval
    STATUS_CHOICES = [
        ('pending', 'Pending Approval'),
        ('approved', 'Approved'),
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('rejected', 'Rejected'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_pricing')
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_pricing')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.batch.product.name} - {self.discount_percentage}% off"
    
    def save(self, *args, **kwargs):
        """Calculate discounted price automatically."""
        discount_amount = (self.original_price * self.discount_percentage) / 100
        self.discounted_price = self.original_price - discount_amount
        super().save(*args, **kwargs)


# Multi-Store Management Models

class StoreInventory(models.Model):
    """Store-specific inventory levels"""
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='store_inventories')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='store_inventories')
    
    # Stock levels
    current_stock = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    min_stock_level = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    max_stock_level = models.IntegerField(default=100, validators=[MinValueValidator(1)])
    reorder_point = models.IntegerField(default=10, validators=[MinValueValidator(0)])
    reorder_quantity = models.IntegerField(default=50, validators=[MinValueValidator(1)])
    
    # Store-specific pricing
    store_cost_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    store_selling_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Location within store
    aisle = models.CharField(max_length=20, blank=True)
    shelf = models.CharField(max_length=20, blank=True)
    bin_location = models.CharField(max_length=50, blank=True)
    
    # Settings
    is_active = models.BooleanField(default=True)
    auto_reorder = models.BooleanField(default=True)
    last_reorder_date = models.DateTimeField(null=True, blank=True)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['store', 'product']
        indexes = [
            models.Index(fields=['store', 'product']),
            models.Index(fields=['current_stock']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.store.name} - {self.product.name}: {self.current_stock}"
    
    @property
    def stock_percentage(self):
        if self.max_stock_level > 0:
            return (self.current_stock / self.max_stock_level) * 100
        return 0
    
    @property
    def needs_reorder(self):
        return self.current_stock <= self.reorder_point
    
    @property
    def is_overstocked(self):
        return self.current_stock > self.max_stock_level
    
    @property
    def is_understocked(self):
        return self.current_stock < self.min_stock_level


class InterStoreTransfer(models.Model):
    """Model for tracking transfers between stores"""
    TRANSFER_STATUS = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('in_transit', 'In Transit'),
        ('received', 'Received'),
        ('cancelled', 'Cancelled'),
        ('rejected', 'Rejected'),
    ]
    
    TRANSFER_REASONS = [
        ('rebalancing', 'Stock Rebalancing'),
        ('emergency', 'Emergency Request'),
        ('excess_stock', 'Excess Stock'),
        ('promotional', 'Promotional Event'),
        ('maintenance', 'Store Maintenance'),
        ('seasonal', 'Seasonal Adjustment'),
    ]
    
    transfer_number = models.CharField(max_length=50, unique=True)
    
    # Transfer details
    from_store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='outgoing_transfers')
    to_store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='incoming_transfers')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    
    # Quantities
    requested_quantity = models.IntegerField(validators=[MinValueValidator(1)])
    approved_quantity = models.IntegerField(null=True, blank=True, validators=[MinValueValidator(0)])
    received_quantity = models.IntegerField(null=True, blank=True, validators=[MinValueValidator(0)])
    
    # Status and reason
    status = models.CharField(max_length=20, choices=TRANSFER_STATUS, default='pending')
    reason = models.CharField(max_length=20, choices=TRANSFER_REASONS, default='rebalancing')
    notes = models.TextField(blank=True)
    
    # Dates
    requested_date = models.DateTimeField(auto_now_add=True)
    approved_date = models.DateTimeField(null=True, blank=True)
    shipped_date = models.DateTimeField(null=True, blank=True)
    received_date = models.DateTimeField(null=True, blank=True)
    expected_delivery = models.DateTimeField(null=True, blank=True)
    
    # Users
    requested_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='requested_inter_store_transfers')
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_inter_store_transfers')
    received_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='received_inter_store_transfers')
    
    # Cost tracking
    transfer_cost = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    unit_cost = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    class Meta:
        ordering = ['-requested_date']
        indexes = [
            models.Index(fields=['transfer_number']),
            models.Index(fields=['status']),
            models.Index(fields=['from_store', 'to_store']),
            models.Index(fields=['requested_date']),
        ]
    
    def __str__(self):
        return f"{self.transfer_number}: {self.from_store.code} → {self.to_store.code}"
    
    def save(self, *args, **kwargs):
        if not self.transfer_number:
            self.transfer_number = self.generate_transfer_number()
        super().save(*args, **kwargs)
    
    def generate_transfer_number(self):
        from django.utils import timezone
        date_str = timezone.now().strftime('%Y%m%d')
        count = InterStoreTransfer.objects.filter(
            requested_date__date=timezone.now().date()
        ).count() + 1
        return f"TRF-{date_str}-{count:04d}"
    
    @property
    def is_pending_approval(self):
        return self.status == 'pending'
    
    @property
    def is_in_progress(self):
        return self.status in ['approved', 'in_transit']
    
    @property
    def is_completed(self):
        return self.status == 'received'
    
    @property
    def total_value(self):
        quantity = self.approved_quantity or self.requested_quantity
        unit_price = self.unit_cost or self.product.cost_price or Decimal('0.00')
        return quantity * unit_price


class StorePerformanceMetrics(models.Model):
    """Daily performance metrics for each store"""
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='performance_metrics')
    date = models.DateField()
    
    # Sales metrics
    total_sales = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    total_transactions = models.IntegerField(default=0)
    average_transaction_value = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    
    # Inventory metrics
    total_products = models.IntegerField(default=0)
    total_stock_value = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    products_out_of_stock = models.IntegerField(default=0)
    products_low_stock = models.IntegerField(default=0)
    products_overstocked = models.IntegerField(default=0)
    
    # Operational metrics
    products_expired = models.IntegerField(default=0)
    wastage_value = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    transfers_sent = models.IntegerField(default=0)
    transfers_received = models.IntegerField(default=0)
    
    # Efficiency metrics
    inventory_turnover = models.DecimalField(max_digits=8, decimal_places=4, default=Decimal('0.0000'))
    stock_accuracy = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('100.00'), validators=[MinValueValidator(0), MaxValueValidator(100)])
    
    class Meta:
        unique_together = ['store', 'date']
        ordering = ['-date']
        indexes = [
            models.Index(fields=['store', 'date']),
            models.Index(fields=['date']),
        ]
    
    def __str__(self):
        return f"{self.store.name} - {self.date}"
    
    @property
    def stock_health_score(self):
        """Calculate overall stock health score (0-100)"""
        if self.total_products == 0:
            return 0
        
        # Base score
        score = 100
        
        # Deduct for out of stock items
        if self.products_out_of_stock > 0:
            score -= (self.products_out_of_stock / self.total_products) * 30
        
        # Deduct for low stock items
        if self.products_low_stock > 0:
            score -= (self.products_low_stock / self.total_products) * 20
        
        # Deduct for overstocked items
        if self.products_overstocked > 0:
            score -= (self.products_overstocked / self.total_products) * 15
        
        # Deduct for expired items
        if self.products_expired > 0:
            score -= (self.products_expired / self.total_products) * 25
        
        # Apply stock accuracy
        score *= (self.stock_accuracy / 100)
        
        return max(0, min(100, score))


class StoreUser(models.Model):
    """Extended user model for store-specific permissions"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='store_profile')
    assigned_stores = models.ManyToManyField(Store, related_name='assigned_users', blank=True)
    primary_store = models.ForeignKey(Store, on_delete=models.SET_NULL, null=True, blank=True, related_name='primary_users')
    
    # Store-specific permissions
    can_manage_inventory = models.BooleanField(default=True)
    can_approve_transfers = models.BooleanField(default=False)
    can_view_analytics = models.BooleanField(default=True)
    can_manage_users = models.BooleanField(default=False)
    
    # Preferences
    default_store_view = models.CharField(max_length=20, choices=[
        ('single', 'Single Store'),
        ('multi', 'Multi Store'),
        ('comparison', 'Store Comparison'),
    ], default='single')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.username} - Store Profile"
    
    @property
    def accessible_stores(self):
        """Get all stores the user can access"""
        if self.user.is_superuser:
            return Store.objects.all()
        return self.assigned_stores.filter(status='active')


# Export all models
__all__ = [
    'Category',
    'Supplier',
    'Product',
    'ProductBatch',
    'ExpiryAlert',
    'Store',
    'ShelfLocation',
    'StoreTransfer',
    'StoreUser',
    # Smart Pricing
    'PricingRule',
    'DynamicPrice',
    'PriceChangeHistory',
    'CompetitorPrice',
    'PriceElasticity',
    # IoT
    'IoTDevice',
    'SensorReading',
    'TemperatureMonitoring',
    'SmartShelfEvent',
    'DoorTrafficAnalytics',
    'IoTAlert',
    # Suppliers (Enhanced)
    'SupplierPerformance',
    'SupplierContract',
    'AutomatedReorder',
    'SupplierCommunication',
    'SupplierReview',
    # Sustainability
    'SustainabilityMetrics',
    'ProductCarbonFootprint',
    'WasteRecord',
    'SustainabilityInitiative',
    'GreenSupplierRating',
]
