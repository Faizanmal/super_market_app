"""
Supplier Portal Models - Additional Features
Note: Base Supplier, SupplierPerformance, and SupplierContract are already in products.models
This file contains only new additional features for supplier management
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone

User = get_user_model()


class AutomatedReorder(models.Model):
    """
    Automated reorder rules and history
    """
    supplier = models.ForeignKey('products.Supplier', on_delete=models.CASCADE, related_name='reorder_rules')
    product = models.ForeignKey('products.Product', on_delete=models.CASCADE, related_name='reorder_rules')
    
    # Reorder settings
    reorder_point = models.IntegerField(help_text="Stock level that triggers reorder")
    reorder_quantity = models.IntegerField(help_text="Quantity to order when reorder point is reached")
    safety_stock = models.IntegerField(default=0, help_text="Minimum safety stock level")
    lead_time_days = models.IntegerField(help_text="Expected delivery time in days")
    
    # Status
    is_active = models.BooleanField(default=True)
    last_order_date = models.DateTimeField(null=True, blank=True)
    next_check_date = models.DateTimeField(default=timezone.now)
    
    # Statistics
    total_orders_placed = models.IntegerField(default=0)
    total_quantity_ordered = models.IntegerField(default=0)
    average_fulfillment_days = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['supplier', 'product']
    
    def __str__(self):
        return f"Reorder Rule: {self.product.name} from {self.supplier.name}"
    
    def should_reorder(self):
        """Check if reorder should be triggered"""
        from .models import Product
        try:
            product = Product.objects.get(pk=self.product_id)
            current_stock = product.quantity
            return current_stock <= self.reorder_point
        except Product.DoesNotExist:
            return False
    
    def calculate_order_quantity(self):
        """Calculate optimal order quantity"""
        from .models import Product
        try:
            product = Product.objects.get(pk=self.product_id)
            current_stock = product.quantity
            shortage = max(0, self.reorder_point - current_stock)
            return max(self.reorder_quantity, shortage + self.safety_stock)
        except Product.DoesNotExist:
            return self.reorder_quantity


class SupplierCommunication(models.Model):
    """
    Track all communications with suppliers
    """
    supplier = models.ForeignKey('products.Supplier', on_delete=models.CASCADE, related_name='communications')
    
    # Communication details
    communication_type = models.CharField(max_length=20, choices=[
        ('email', 'Email'),
        ('phone', 'Phone'),
        ('meeting', 'Meeting'),
        ('portal', 'Portal Message'),
        ('other', 'Other'),
    ])
    subject = models.CharField(max_length=200)
    message = models.TextField()
    direction = models.CharField(max_length=10, choices=[
        ('inbound', 'Inbound'),
        ('outbound', 'Outbound'),
    ])
    
    # Status
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('sent', 'Sent'),
        ('received', 'Received'),
        ('replied', 'Replied'),
        ('resolved', 'Resolved'),
    ], default='pending')
    
    # Related user
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    
    # Optional attachments
    attachment = models.FileField(upload_to='supplier_communications/', null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.communication_type}: {self.subject} - {self.supplier.name}"


class SupplierReview(models.Model):
    """
    Staff reviews and ratings for suppliers
    """
    supplier = models.ForeignKey('products.Supplier', on_delete=models.CASCADE, related_name='reviews')
    reviewer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='supplier_reviews')
    
    # Ratings (1-5 scale)
    overall_rating = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    quality_rating = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    delivery_rating = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    communication_rating = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    value_rating = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="Price vs quality value rating"
    )
    
    # Review content
    title = models.CharField(max_length=200)
    comment = models.TextField()
    pros = models.TextField(blank=True)
    cons = models.TextField(blank=True)
    
    # Recommendation
    would_recommend = models.BooleanField(default=True)
    
    # Status
    is_verified = models.BooleanField(default=False, help_text="Verified by manager")
    is_public = models.BooleanField(default=True, help_text="Visible to supplier")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['supplier', 'reviewer', 'created_at']
    
    def __str__(self):
        return f"{self.reviewer.username}'s review of {self.supplier.name} ({self.overall_rating}★)"
