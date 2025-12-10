"""
Advanced Analytics Models
Heat maps, basket analysis, customer segmentation (RFM)
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.db.models import Sum, Count, Avg, F
from datetime import datetime, timedelta
from decimal import Decimal
import uuid

User = get_user_model()


class CustomerHeatMapData(models.Model):
    """Customer movement heat map data"""
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE, related_name='heatmap_data')
    date = models.DateField()
    hour = models.IntegerField()
    zone = models.CharField(max_length=50)
    x_position = models.FloatField()
    y_position = models.FloatField()
    visitor_count = models.IntegerField(default=0)
    dwell_time_seconds = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'customer_heatmap_data'
        indexes = [
            models.Index(fields=['store', 'date', 'hour']),
        ]


class BasketAnalysis(models.Model):
    """Market basket analysis results"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE, null=True, blank=True)
    analysis_date = models.DateField()
    period_start = models.DateField()
    period_end = models.DateField()
    transaction_count = models.IntegerField()
    
    # Stored as JSON: [{item_a, item_b, support, confidence, lift}]
    frequent_itemsets = models.JSONField(default=list)
    association_rules = models.JSONField(default=list)
    
    # Top combinations
    top_pairs = models.JSONField(default=list)
    top_triplets = models.JSONField(default=list)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'basket_analysis'
        ordering = ['-analysis_date']


class RFMSegment(models.Model):
    """RFM (Recency, Frequency, Monetary) customer segments"""
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    
    # RFM score ranges (1-5 each)
    recency_min = models.IntegerField()
    recency_max = models.IntegerField()
    frequency_min = models.IntegerField()
    frequency_max = models.IntegerField()
    monetary_min = models.IntegerField()
    monetary_max = models.IntegerField()
    
    # Marketing recommendations
    marketing_strategy = models.TextField(blank=True)
    recommended_campaigns = models.JSONField(default=list)
    
    color = models.CharField(max_length=7, default='#3498db')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'rfm_segments'

    def __str__(self):
        return self.name


class CustomerRFMScore(models.Model):
    """Individual customer RFM scores"""
    customer = models.OneToOneField('customer_app_models.CustomerProfile', on_delete=models.CASCADE, related_name='rfm_score')
    
    # Raw values
    last_purchase_date = models.DateField(null=True, blank=True)
    total_purchases = models.IntegerField(default=0)
    total_spend = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    
    # Scores (1-5)
    recency_score = models.IntegerField(default=1)
    frequency_score = models.IntegerField(default=1)
    monetary_score = models.IntegerField(default=1)
    
    # Combined score
    rfm_score = models.CharField(max_length=3, default='111')
    
    segment = models.ForeignKey(RFMSegment, on_delete=models.SET_NULL, null=True, blank=True)
    
    calculated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'customer_rfm_scores'

    @property
    def rfm_total(self):
        return self.recency_score + self.frequency_score + self.monetary_score


class ABTestResult(models.Model):
    """A/B test results for analytics"""
    TYPE_CHOICES = [
        ('pricing', 'Pricing Test'),
        ('placement', 'Product Placement'),
        ('promotion', 'Promotion Test'),
        ('ui', 'UI/UX Test'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    test_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    hypothesis = models.TextField()
    
    variant_a_description = models.TextField()
    variant_b_description = models.TextField()
    
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    
    # Results
    variant_a_participants = models.IntegerField(default=0)
    variant_a_conversions = models.IntegerField(default=0)
    variant_a_revenue = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    
    variant_b_participants = models.IntegerField(default=0)
    variant_b_conversions = models.IntegerField(default=0)
    variant_b_revenue = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    
    winner = models.CharField(max_length=10, blank=True)
    statistical_significance = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    
    is_active = models.BooleanField(default=True)
    conclusion = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ab_test_results'
        ordering = ['-start_date']

    @property
    def variant_a_conversion_rate(self):
        if self.variant_a_participants > 0:
            return (self.variant_a_conversions / self.variant_a_participants) * 100
        return 0

    @property
    def variant_b_conversion_rate(self):
        if self.variant_b_participants > 0:
            return (self.variant_b_conversions / self.variant_b_participants) * 100
        return 0


class SalesMetric(models.Model):
    """Daily sales metrics for analytics"""
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE, related_name='sales_metrics')
    date = models.DateField()
    
    # Transaction metrics
    transaction_count = models.IntegerField(default=0)
    unique_customers = models.IntegerField(default=0)
    items_sold = models.IntegerField(default=0)
    
    # Revenue metrics
    gross_revenue = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    net_revenue = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    discount_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    refund_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    
    # Basket metrics
    average_basket_size = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    average_basket_value = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Category breakdown (JSON: {category_id: {units, revenue}})
    category_breakdown = models.JSONField(default=dict)
    
    # Hourly breakdown (JSON: {hour: {transactions, revenue}})
    hourly_breakdown = models.JSONField(default=dict)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'sales_metrics'
        unique_together = ['store', 'date']
        ordering = ['-date']


class ProductPerformance(models.Model):
    """Product performance analytics"""
    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='performance_metrics')
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE, null=True, blank=True)
    period = models.CharField(max_length=20)  # weekly, monthly
    period_start = models.DateField()
    period_end = models.DateField()
    
    # Sales metrics
    units_sold = models.IntegerField(default=0)
    revenue = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    profit = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    profit_margin = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    
    # Inventory metrics
    avg_stock_level = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    stockouts = models.IntegerField(default=0)
    wastage_units = models.IntegerField(default=0)
    
    # Customer metrics
    unique_buyers = models.IntegerField(default=0)
    repeat_purchase_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    
    # Comparison
    prev_period_units = models.IntegerField(null=True, blank=True)
    prev_period_revenue = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    growth_rate = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'product_performance'
        ordering = ['-revenue']


class InventoryTurnover(models.Model):
    """Inventory turnover analysis"""
    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='turnover_metrics')
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE, null=True, blank=True)
    period = models.CharField(max_length=20)
    period_start = models.DateField()
    period_end = models.DateField()
    
    # Turnover calculation
    cost_of_goods_sold = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    average_inventory = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    turnover_ratio = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    days_to_sell = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'inventory_turnover'
