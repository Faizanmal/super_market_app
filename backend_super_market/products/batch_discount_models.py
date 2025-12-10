"""
Batch Discount Engine Models
Automatically applies discounts to products nearing expiry to reduce waste.
"""
from django.db import models
from django.conf import settings
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal


class DiscountRule(models.Model):
    """
    Rules for automatic discount application based on expiry proximity.
    """
    DISCOUNT_TYPE_CHOICES = [
        ('percentage', 'Percentage Off'),
        ('fixed', 'Fixed Amount Off'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('paused', 'Paused'),
        ('expired', 'Expired'),
    ]
    
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    
    # Time-based trigger (days until expiry)
    days_before_expiry = models.PositiveIntegerField(
        help_text="Apply discount when product is this many days from expiry"
    )
    
    # Discount configuration
    discount_type = models.CharField(max_length=20, choices=DISCOUNT_TYPE_CHOICES, default='percentage')
    discount_value = models.DecimalField(max_digits=10, decimal_places=2)
    max_discount_percentage = models.DecimalField(
        max_digits=5, decimal_places=2, default=50.00,
        help_text="Maximum discount percentage (for safety)"
    )
    
    # Scope - which products this applies to
    apply_to_all = models.BooleanField(default=True)
    categories = models.ManyToManyField('Category', blank=True, related_name='discount_rules')
    products = models.ManyToManyField('Product', blank=True, related_name='discount_rules')
    
    # Status and ownership
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    priority = models.PositiveIntegerField(default=1, help_text="Higher priority rules apply first")
    
    # Metadata
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-priority', 'days_before_expiry']
        indexes = [
            models.Index(fields=['status', 'days_before_expiry']),
            models.Index(fields=['created_by', 'status']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.discount_value}{'%' if self.discount_type == 'percentage' else '$'} off)"


class BatchDiscount(models.Model):
    """
    Applied batch discounts tracked for analytics and auditing.
    """
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
        ('completed', 'Completed'),
    ]
    
    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='batch_discounts')
    rule = models.ForeignKey(DiscountRule, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Original and discounted prices
    original_price = models.DecimalField(max_digits=10, decimal_places=2)
    discounted_price = models.DecimalField(max_digits=10, decimal_places=2)
    discount_percentage = models.DecimalField(max_digits=5, decimal_places=2)
    
    # Validity
    start_date = models.DateTimeField(default=timezone.now)
    end_date = models.DateTimeField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    
    # Tracking
    quantity_at_discount = models.PositiveIntegerField(default=0)
    quantity_sold_at_discount = models.PositiveIntegerField(default=0)
    
    # Metadata
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'end_date']),
            models.Index(fields=['product', 'status']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - {self.discount_percentage}% off"
    
    @property
    def is_active(self):
        now = timezone.now()
        return self.status == 'active' and self.start_date <= now <= self.end_date
    
    @property
    def savings_amount(self):
        return self.original_price - self.discounted_price


class DiscountNotification(models.Model):
    """
    Notifications sent about discounts to customers or staff.
    """
    CHANNEL_CHOICES = [
        ('push', 'Push Notification'),
        ('email', 'Email'),
        ('sms', 'SMS'),
        ('in_app', 'In-App'),
    ]
    
    batch_discount = models.ForeignKey(BatchDiscount, on_delete=models.CASCADE, related_name='notifications')
    channel = models.CharField(max_length=20, choices=CHANNEL_CHOICES)
    
    recipient_count = models.PositiveIntegerField(default=0)
    sent_at = models.DateTimeField(null=True, blank=True)
    message = models.TextField()
    
    # Tracking engagement
    opened_count = models.PositiveIntegerField(default=0)
    clicked_count = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Notification for {self.batch_discount.product.name} via {self.channel}"


class DiscountAnalytics(models.Model):
    """
    Daily analytics for discount performance.
    """
    date = models.DateField()
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    
    # Counts
    total_discounts_applied = models.PositiveIntegerField(default=0)
    total_products_discounted = models.PositiveIntegerField(default=0)
    
    # Value metrics
    total_original_value = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    total_discounted_value = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    total_sold_value = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    
    # Waste reduction
    waste_prevented_value = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    waste_prevented_quantity = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['date', 'created_by']
        ordering = ['-date']
    
    def __str__(self):
        return f"Discount Analytics for {self.date}"
