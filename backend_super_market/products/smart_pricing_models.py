"""
Smart Pricing and Dynamic Optimization Models
Implements AI-powered pricing recommendations based on expiry dates, demand, and competition
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from decimal import Decimal
import json

User = get_user_model()


class PricingRule(models.Model):
    """
    Define rules for dynamic pricing based on various conditions
    """
    RULE_TYPE_CHOICES = [
        ('expiry', 'Expiry-Based'),
        ('demand', 'Demand-Based'),
        ('competitor', 'Competitor-Based'),
        ('clearance', 'Clearance'),
        ('seasonal', 'Seasonal'),
        ('bundle', 'Bundle Discount'),
    ]
    
    CONDITION_OPERATOR_CHOICES = [
        ('lt', 'Less Than'),
        ('lte', 'Less Than or Equal'),
        ('gt', 'Greater Than'),
        ('gte', 'Greater Than or Equal'),
        ('eq', 'Equal'),
        ('between', 'Between'),
    ]
    
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    rule_type = models.CharField(max_length=20, choices=RULE_TYPE_CHOICES)
    priority = models.IntegerField(default=0, help_text="Higher priority rules are applied first")
    
    # Condition parameters
    condition_field = models.CharField(max_length=100, help_text="Field to check (e.g., 'days_to_expiry', 'stock_level')")
    condition_operator = models.CharField(max_length=10, choices=CONDITION_OPERATOR_CHOICES)
    condition_value = models.CharField(max_length=200, help_text="Value to compare against (JSON for 'between')")
    
    # Discount parameters
    discount_type = models.CharField(max_length=10, choices=[('percent', 'Percentage'), ('fixed', 'Fixed Amount')])
    discount_value = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    max_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=50, validators=[MinValueValidator(0), MaxValueValidator(100)])
    
    # Application settings
    applies_to_categories = models.JSONField(default=list, blank=True, help_text="List of category IDs")
    applies_to_products = models.JSONField(default=list, blank=True, help_text="List of product IDs")
    min_original_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    max_original_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    start_date = models.DateTimeField(null=True, blank=True)
    end_date = models.DateTimeField(null=True, blank=True)
    
    # Tracking
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='pricing_rules')
    
    # Statistics
    times_applied = models.IntegerField(default=0)
    total_revenue_impact = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    class Meta:
        ordering = ['-priority', '-created_at']
        indexes = [
            models.Index(fields=['rule_type', 'is_active']),
            models.Index(fields=['priority']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.get_rule_type_display()})"
    
    def is_valid_now(self):
        """Check if rule is currently valid"""
        now = timezone.now()
        if not self.is_active:
            return False
        if self.start_date and now < self.start_date:
            return False
        if self.end_date and now > self.end_date:
            return False
        return True
    
    def evaluate_condition(self, value):
        """Evaluate if the condition is met for a given value"""
        try:
            if self.condition_operator == 'lt':
                return value < Decimal(self.condition_value)
            elif self.condition_operator == 'lte':
                return value <= Decimal(self.condition_value)
            elif self.condition_operator == 'gt':
                return value > Decimal(self.condition_value)
            elif self.condition_operator == 'gte':
                return value >= Decimal(self.condition_value)
            elif self.condition_operator == 'eq':
                return value == Decimal(self.condition_value)
            elif self.condition_operator == 'between':
                range_values = json.loads(self.condition_value)
                return Decimal(range_values[0]) <= value <= Decimal(range_values[1])
        except (ValueError, json.JSONDecodeError, IndexError):
            return False
        return False
    
    def calculate_discount(self, original_price):
        """Calculate the discount amount for a given price"""
        if self.discount_type == 'percent':
            discount = original_price * (self.discount_value / 100)
        else:  # fixed
            discount = self.discount_value
        
        # Ensure discount doesn't exceed max_discount_percent
        max_discount = original_price * (self.max_discount_percent / 100)
        return min(discount, max_discount)


class DynamicPrice(models.Model):
    """
    Store dynamically calculated prices for products
    """
    product = models.ForeignKey('products.Product', on_delete=models.CASCADE, related_name='dynamic_prices')
    
    # Original pricing
    original_price = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Dynamic pricing
    suggested_price = models.DecimalField(max_digits=10, decimal_places=2)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2)
    discount_percent = models.DecimalField(max_digits=5, decimal_places=2)
    
    # Applied rules
    applied_rules = models.JSONField(default=list, help_text="List of rule IDs that were applied")
    pricing_factors = models.JSONField(default=dict, help_text="Factors considered in pricing")
    
    # Status
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('rejected', 'Rejected'),
    ], default='pending')
    
    # Validity
    valid_from = models.DateTimeField(default=timezone.now)
    valid_until = models.DateTimeField(null=True, blank=True)
    
    # Approval tracking
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_prices')
    reviewed_at = models.DateTimeField(null=True, blank=True)
    review_notes = models.TextField(blank=True)
    
    # Performance tracking
    times_sold = models.IntegerField(default=0)
    revenue_generated = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['product', 'status']),
            models.Index(fields=['valid_from', 'valid_until']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - {self.suggested_price} (was {self.original_price})"
    
    def is_valid_now(self):
        """Check if this dynamic price is currently valid"""
        now = timezone.now()
        if self.status != 'active':
            return False
        if now < self.valid_from:
            return False
        if self.valid_until and now > self.valid_until:
            return False
        return True
    
    def approve(self, user, notes=''):
        """Approve the dynamic price"""
        self.status = 'approved'
        self.reviewed_by = user
        self.reviewed_at = timezone.now()
        self.review_notes = notes
        self.save()
    
    def activate(self):
        """Activate the dynamic price"""
        self.status = 'active'
        self.save()
    
    def expire(self):
        """Mark the dynamic price as expired"""
        self.status = 'expired'
        self.save()


class PriceChangeHistory(models.Model):
    """
    Track all price changes for audit and analysis
    """
    product = models.ForeignKey('products.Product', on_delete=models.CASCADE, related_name='smart_price_history')
    
    # Price change details
    old_price = models.DecimalField(max_digits=10, decimal_places=2)
    new_price = models.DecimalField(max_digits=10, decimal_places=2)
    price_difference = models.DecimalField(max_digits=10, decimal_places=2)
    percent_change = models.DecimalField(max_digits=5, decimal_places=2)
    
    # Reason for change
    change_type = models.CharField(max_length=20, choices=[
        ('manual', 'Manual Adjustment'),
        ('dynamic', 'Dynamic Pricing'),
        ('promotion', 'Promotion'),
        ('clearance', 'Clearance'),
        ('cost_change', 'Cost Change'),
        ('competitor', 'Competitor Match'),
    ])
    reason = models.TextField()
    
    # Dynamic pricing info (if applicable)
    dynamic_price = models.ForeignKey(DynamicPrice, on_delete=models.SET_NULL, null=True, blank=True)
    applied_rules = models.JSONField(default=list)
    
    # Tracking
    changed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    changed_at = models.DateTimeField(auto_now_add=True)
    
    # Impact tracking
    sales_before = models.IntegerField(default=0, help_text="Units sold in period before change")
    sales_after = models.IntegerField(default=0, help_text="Units sold in period after change")
    revenue_impact = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    class Meta:
        ordering = ['-changed_at']
        indexes = [
            models.Index(fields=['product', 'changed_at']),
            models.Index(fields=['change_type']),
        ]
        verbose_name_plural = 'Price change histories'
    
    def __str__(self):
        return f"{self.product.name}: {self.old_price} → {self.new_price} ({self.changed_at})"


class CompetitorPrice(models.Model):
    """
    Track competitor pricing for price matching and analysis
    """
    product = models.ForeignKey('products.Product', on_delete=models.CASCADE, related_name='competitor_prices')
    
    # Competitor info
    competitor_name = models.CharField(max_length=200)
    competitor_location = models.CharField(max_length=200, blank=True)
    
    # Price details
    price = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')
    
    # Product details at competitor
    competitor_product_name = models.CharField(max_length=200, blank=True)
    competitor_sku = models.CharField(max_length=100, blank=True)
    product_condition = models.CharField(max_length=50, default='new')
    
    # Source
    source = models.CharField(max_length=20, choices=[
        ('manual', 'Manual Entry'),
        ('api', 'API Integration'),
        ('scraping', 'Web Scraping'),
        ('customer', 'Customer Report'),
    ], default='manual')
    source_url = models.URLField(blank=True)
    
    # Validity
    observed_at = models.DateTimeField(default=timezone.now)
    verified = models.BooleanField(default=False)
    verified_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Analysis
    price_difference = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    price_difference_percent = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    is_cheaper = models.BooleanField(default=False)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    notes = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-observed_at']
        indexes = [
            models.Index(fields=['product', 'observed_at']),
            models.Index(fields=['competitor_name']),
        ]
    
    def __str__(self):
        return f"{self.competitor_name}: {self.product.name} - {self.price}"
    
    def calculate_difference(self, our_price):
        """Calculate price difference against our price"""
        self.price_difference = our_price - self.price
        if our_price > 0:
            self.price_difference_percent = (self.price_difference / our_price) * 100
        self.is_cheaper = self.price < our_price
        self.save()


class PriceElasticity(models.Model):
    """
    Track price elasticity of demand for products
    """
    product = models.OneToOneField('products.Product', on_delete=models.CASCADE, related_name='price_elasticity')
    
    # Elasticity metrics
    elasticity_coefficient = models.DecimalField(
        max_digits=5, 
        decimal_places=2,
        help_text="% change in quantity demanded / % change in price"
    )
    
    # Classification
    elasticity_type = models.CharField(max_length=20, choices=[
        ('elastic', 'Elastic (>1)'),
        ('unitary', 'Unitary (=1)'),
        ('inelastic', 'Inelastic (<1)'),
    ])
    
    # Optimal pricing
    optimal_price = models.DecimalField(max_digits=10, decimal_places=2)
    optimal_price_confidence = models.DecimalField(
        max_digits=5, 
        decimal_places=2,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Confidence level (0-100%)"
    )
    
    # Data points used
    data_points = models.JSONField(default=list, help_text="Historical price-quantity data")
    sample_size = models.IntegerField(default=0)
    
    # Analysis period
    analysis_start_date = models.DateTimeField()
    analysis_end_date = models.DateTimeField()
    
    # Metadata
    calculated_at = models.DateTimeField(auto_now=True)
    last_updated = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name_plural = 'Price elasticities'
    
    def __str__(self):
        return f"{self.product.name} - Elasticity: {self.elasticity_coefficient}"
    
    def is_elastic(self):
        """Check if demand is elastic"""
        return abs(self.elasticity_coefficient) > 1
    
    def recommend_price_change(self, current_price):
        """Recommend price change based on elasticity"""
        if self.optimal_price > current_price:
            return {
                'action': 'increase',
                'recommended_price': self.optimal_price,
                'expected_impact': 'Higher revenue with slightly lower volume'
            }
        elif self.optimal_price < current_price:
            return {
                'action': 'decrease',
                'recommended_price': self.optimal_price,
                'expected_impact': 'Higher volume and total revenue'
            }
        else:
            return {
                'action': 'maintain',
                'recommended_price': current_price,
                'expected_impact': 'Already at optimal price'
            }
