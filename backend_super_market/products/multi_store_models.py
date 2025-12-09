"""
Enhanced Multi-Store Management Models
Supports multiple store locations, inter-store transfers, and comparative analytics
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from decimal import Decimal
import uuid
 
User = get_user_model()

class Store(models.Model):
    """Store location model for multi-store management"""
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
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=20, unique=True)
    store_type = models.CharField(max_length=20, choices=STORE_TYPES, default='branch')
    status = models.CharField(max_length=20, choices=STORE_STATUS, default='active')
    
    # Location information
    address = models.TextField()
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    postal_code = models.CharField(max_length=20)
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
    def is_active(self):
        return self.status == 'active'
    
    @property
    def total_products(self):
        return self.store_inventories.count()
    
    @property
    def total_stock_value(self):
        from django.db.models import Sum, F
        return self.store_inventories.aggregate(
            total=Sum(F('quantity') * F('product__cost_price'))
        )['total'] or Decimal('0.00')

class StoreInventory(models.Model):
    """Store-specific inventory levels"""
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='store_inventories')
    product = models.ForeignKey('products.Product', on_delete=models.CASCADE, related_name='store_inventories')
    
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
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    transfer_number = models.CharField(max_length=50, unique=True)
    
    # Transfer details
    from_store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='outgoing_transfers')
    to_store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='incoming_transfers')
    product = models.ForeignKey('products.Product', on_delete=models.CASCADE)
    
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
    requested_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='requested_transfers')
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_transfers')
    received_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='received_transfers')
    
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

class StoreComparison(models.Model):
    """Model for storing store comparison analytics"""
    COMPARISON_PERIODS = [
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
        ('yearly', 'Yearly'),
    ]
    
    stores = models.ManyToManyField(Store, related_name='comparisons')
    comparison_date = models.DateField()
    period = models.CharField(max_length=20, choices=COMPARISON_PERIODS)
    
    # Metrics
    metrics_data = models.JSONField(default=dict)
    
    # Performance indicators
    best_performing_store = models.ForeignKey(Store, on_delete=models.SET_NULL, null=True, blank=True, related_name='best_performance_records')
    worst_performing_store = models.ForeignKey(Store, on_delete=models.SET_NULL, null=True, blank=True, related_name='worst_performance_records')
    
    # Analysis results
    insights = models.TextField(blank=True)
    recommendations = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    class Meta:
        ordering = ['-comparison_date']
        indexes = [
            models.Index(fields=['comparison_date']),
            models.Index(fields=['period']),
        ]
    
    def __str__(self):
        return f"Store Comparison - {self.comparison_date} ({self.period})"

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