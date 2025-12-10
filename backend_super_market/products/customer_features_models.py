"""
Customer Features Models
Shopping Lists and Digital Receipts with Warranty Tracking.
"""
from django.db import models
from django.conf import settings
from django.utils import timezone
from decimal import Decimal
import uuid


class ShoppingList(models.Model):
    """
    Customer shopping lists for planning purchases.
    """
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('archived', 'Archived'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    
    # Owner and sharing
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='shopping_lists')
    is_shared = models.BooleanField(default=False)
    share_code = models.CharField(max_length=20, unique=True, blank=True, null=True)
    shared_with = models.ManyToManyField(settings.AUTH_USER_MODEL, blank=True, related_name='shared_shopping_lists')
    
    # Store association
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.SET_NULL, null=True, blank=True)
    
    # Status and scheduling
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    planned_date = models.DateField(null=True, blank=True)
    completed_date = models.DateTimeField(null=True, blank=True)
    
    # Budget tracking
    estimated_total = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    actual_total = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    budget_limit = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-updated_at']
    
    def __str__(self):
        return f"{self.name} by {self.owner.username}"
    
    def generate_share_code(self):
        import random
        import string
        self.share_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        self.save()
        return self.share_code


class ShoppingListItem(models.Model):
    """
    Individual items in a shopping list.
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_cart', 'In Cart'),
        ('purchased', 'Purchased'),
        ('unavailable', 'Unavailable'),
        ('removed', 'Removed'),
    ]
    
    shopping_list = models.ForeignKey(ShoppingList, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey('Product', on_delete=models.CASCADE, null=True, blank=True)
    
    # Manual entry option
    custom_name = models.CharField(max_length=200, blank=True)
    custom_note = models.TextField(blank=True)
    
    # Quantity and pricing
    quantity = models.PositiveIntegerField(default=1)
    estimated_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    actual_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Status and priority
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    priority = models.PositiveSmallIntegerField(default=1)  # 1=high, 2=medium, 3=low
    is_essential = models.BooleanField(default=False)
    
    # Store aisle navigation
    aisle_location = models.CharField(max_length=50, blank=True)
    shelf_location = models.CharField(max_length=50, blank=True)
    
    # Timestamps
    added_at = models.DateTimeField(auto_now_add=True)
    checked_off_at = models.DateTimeField(null=True, blank=True)
    added_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    
    class Meta:
        ordering = ['priority', 'added_at']
    
    def __str__(self):
        name = self.product.name if self.product else self.custom_name
        return f"{name} x{self.quantity}"


class DigitalReceipt(models.Model):
    """
    Digital receipts for purchases with itemized details.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    receipt_number = models.CharField(max_length=50, unique=True)
    
    # Customer and store
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='receipts')
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.SET_NULL, null=True, blank=True)
    cashier = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='processed_receipts')
    
    # Transaction details
    transaction_date = models.DateTimeField(default=timezone.now)
    
    # Totals
    subtotal = models.DecimalField(max_digits=12, decimal_places=2)
    tax_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    
    # Payment info
    payment_method = models.CharField(max_length=50)  # cash, card, mobile, etc.
    payment_reference = models.CharField(max_length=100, blank=True)
    
    # QR code for verification
    qr_code = models.TextField(blank=True)  # Base64 encoded QR image or data
    
    # Attachments
    pdf_url = models.URLField(blank=True)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-transaction_date']
    
    def __str__(self):
        return f"Receipt #{self.receipt_number}"


class ReceiptItem(models.Model):
    """
    Individual items in a receipt.
    """
    receipt = models.ForeignKey(DigitalReceipt, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey('Product', on_delete=models.SET_NULL, null=True, blank=True)
    
    # Item details (stored separately for historical accuracy)
    product_name = models.CharField(max_length=200)
    product_sku = models.CharField(max_length=100, blank=True)
    barcode = models.CharField(max_length=100, blank=True)
    
    # Quantity and pricing
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    total_price = models.DecimalField(max_digits=12, decimal_places=2)
    
    # Warranty info
    has_warranty = models.BooleanField(default=False)
    warranty_months = models.PositiveIntegerField(default=0)
    warranty_expiry = models.DateField(null=True, blank=True)
    
    class Meta:
        ordering = ['id']
    
    def __str__(self):
        return f"{self.product_name} x{self.quantity}"


class WarrantyTracker(models.Model):
    """
    Track warranties for purchased items.
    """
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('expiring_soon', 'Expiring Soon'),
        ('expired', 'Expired'),
        ('claimed', 'Claimed'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='warranties')
    receipt_item = models.OneToOneField(ReceiptItem, on_delete=models.CASCADE, related_name='warranty')
    
    # Warranty details
    product_name = models.CharField(max_length=200)
    serial_number = models.CharField(max_length=100, blank=True)
    
    # Dates
    purchase_date = models.DateField()
    warranty_start_date = models.DateField()
    warranty_end_date = models.DateField()
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    
    # Reminder settings
    reminder_days_before = models.PositiveIntegerField(default=30)
    reminder_sent = models.BooleanField(default=False)
    reminder_sent_at = models.DateTimeField(null=True, blank=True)
    
    # Additional info
    warranty_terms = models.TextField(blank=True)
    claim_instructions = models.TextField(blank=True)
    manufacturer_contact = models.CharField(max_length=200, blank=True)
    
    # Documents
    warranty_document_url = models.URLField(blank=True)
    proof_of_purchase_url = models.URLField(blank=True)
    
    # Claim history
    times_claimed = models.PositiveSmallIntegerField(default=0)
    last_claim_date = models.DateField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['warranty_end_date']
        indexes = [
            models.Index(fields=['customer', 'status']),
            models.Index(fields=['warranty_end_date']),
        ]
    
    def __str__(self):
        return f"Warranty for {self.product_name}"
    
    @property
    def days_remaining(self):
        if self.warranty_end_date:
            return (self.warranty_end_date - timezone.now().date()).days
        return 0
    
    def update_status(self):
        today = timezone.now().date()
        if self.warranty_end_date < today:
            self.status = 'expired'
        elif self.days_remaining <= self.reminder_days_before:
            self.status = 'expiring_soon'
        else:
            self.status = 'active'
        self.save()


class WarrantyClaim(models.Model):
    """
    Track warranty claims made by customers.
    """
    STATUS_CHOICES = [
        ('submitted', 'Submitted'),
        ('under_review', 'Under Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('completed', 'Completed'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    warranty = models.ForeignKey(WarrantyTracker, on_delete=models.CASCADE, related_name='claims')
    
    # Claim details
    claim_date = models.DateTimeField(default=timezone.now)
    issue_description = models.TextField()
    
    # Status tracking
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='submitted')
    resolution = models.TextField(blank=True)
    resolution_date = models.DateTimeField(null=True, blank=True)
    
    # Outcome
    replacement_provided = models.BooleanField(default=False)
    repair_done = models.BooleanField(default=False)
    refund_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    
    # Supporting documents
    images = models.JSONField(default=list)  # List of image URLs
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-claim_date']
    
    def __str__(self):
        return f"Claim for {self.warranty.product_name}"
