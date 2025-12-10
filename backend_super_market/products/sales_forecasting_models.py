"""
Sales Forecasting with AI Models
Predict future demand based on historical data, seasonality, and trends.
"""
from django.db import models
from django.conf import settings
from django.utils import timezone
from decimal import Decimal
import json


class SalesHistory(models.Model):
    """
    Historical sales data for forecasting.
    """
    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='sales_history')
    date = models.DateField()
    
    # Sales metrics
    quantity_sold = models.PositiveIntegerField(default=0)
    revenue = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    cost = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    profit = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    
    # Context data
    was_on_discount = models.BooleanField(default=False)
    discount_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0.00'))
    
    # Weather and events (optional context)
    day_of_week = models.PositiveSmallIntegerField()  # 0=Monday, 6=Sunday
    is_weekend = models.BooleanField(default=False)
    is_holiday = models.BooleanField(default=False)
    holiday_name = models.CharField(max_length=100, blank=True)
    
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['product', 'date', 'created_by']
        ordering = ['-date']
        indexes = [
            models.Index(fields=['product', 'date']),
            models.Index(fields=['created_by', 'date']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - {self.date}: {self.quantity_sold} sold"


class SalesForecast(models.Model):
    """
    AI-generated sales forecasts.
    """
    CONFIDENCE_CHOICES = [
        ('high', 'High'),
        ('medium', 'Medium'),
        ('low', 'Low'),
    ]
    
    MODEL_CHOICES = [
        ('moving_avg', 'Moving Average'),
        ('exp_smoothing', 'Exponential Smoothing'),
        ('arima', 'ARIMA'),
        ('prophet', 'Prophet'),
        ('lstm', 'LSTM Neural Network'),
        ('ensemble', 'Ensemble Model'),
    ]
    
    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='forecasts')
    forecast_date = models.DateField()
    
    # Predictions
    predicted_quantity = models.PositiveIntegerField()
    predicted_revenue = models.DecimalField(max_digits=15, decimal_places=2)
    
    # Confidence intervals
    lower_bound = models.PositiveIntegerField()
    upper_bound = models.PositiveIntegerField()
    confidence_level = models.CharField(max_length=20, choices=CONFIDENCE_CHOICES, default='medium')
    confidence_score = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0.00'))
    
    # Model info
    model_used = models.CharField(max_length=30, choices=MODEL_CHOICES, default='ensemble')
    model_accuracy = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0.00'))
    
    # Actual results (updated later for accuracy tracking)
    actual_quantity = models.PositiveIntegerField(null=True, blank=True)
    actual_revenue = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    forecast_error = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Metadata
    generated_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    
    class Meta:
        unique_together = ['product', 'forecast_date', 'created_by']
        ordering = ['forecast_date']
        indexes = [
            models.Index(fields=['product', 'forecast_date']),
            models.Index(fields=['created_by', 'forecast_date']),
        ]
    
    def __str__(self):
        return f"Forecast for {self.product.name} on {self.forecast_date}"


class SeasonalPattern(models.Model):
    """
    Detected seasonal patterns for products or categories.
    """
    PATTERN_TYPE_CHOICES = [
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
        ('yearly', 'Yearly'),
    ]
    
    product = models.ForeignKey('Product', on_delete=models.CASCADE, null=True, blank=True, related_name='seasonal_patterns')
    category = models.ForeignKey('Category', on_delete=models.CASCADE, null=True, blank=True, related_name='seasonal_patterns')
    
    pattern_type = models.CharField(max_length=20, choices=PATTERN_TYPE_CHOICES)
    
    # Pattern data (JSON) - e.g., {"monday": 1.2, "tuesday": 0.9, ...}
    pattern_data = models.JSONField(default=dict)
    
    # Peak and low periods
    peak_periods = models.JSONField(default=list)
    low_periods = models.JSONField(default=list)
    
    # Confidence
    confidence_score = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0.00'))
    sample_size = models.PositiveIntegerField(default=0)
    
    detected_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    
    class Meta:
        ordering = ['-confidence_score']
    
    def __str__(self):
        target = self.product.name if self.product else self.category.name
        return f"{self.pattern_type} pattern for {target}"


class RestockRecommendation(models.Model):
    """
    Smart restock recommendations based on forecasting.
    """
    URGENCY_CHOICES = [
        ('critical', 'Critical - Out of Stock Imminent'),
        ('high', 'High - Order Soon'),
        ('medium', 'Medium - Plan to Order'),
        ('low', 'Low - Monitor'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('ordered', 'Ordered'),
        ('dismissed', 'Dismissed'),
    ]
    
    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='restock_recommendations')
    
    # Recommendation details
    recommended_quantity = models.PositiveIntegerField()
    recommended_order_date = models.DateField()
    expected_stockout_date = models.DateField()
    
    # Urgency and status
    urgency = models.CharField(max_length=20, choices=URGENCY_CHOICES, default='medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Supplier info
    suggested_supplier = models.ForeignKey('Supplier', on_delete=models.SET_NULL, null=True, blank=True)
    estimated_cost = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    estimated_lead_time_days = models.PositiveIntegerField(default=7)
    
    # Reasoning
    reason = models.TextField(blank=True)
    confidence_score = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0.00'))
    
    # Metadata
    generated_at = models.DateTimeField(auto_now_add=True)
    actioned_at = models.DateTimeField(null=True, blank=True)
    actioned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, 
        null=True, blank=True, related_name='actioned_restock_recommendations'
    )
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    
    class Meta:
        ordering = ['urgency', 'expected_stockout_date']
        indexes = [
            models.Index(fields=['status', 'urgency']),
            models.Index(fields=['product', 'status']),
        ]
    
    def __str__(self):
        return f"Restock {self.product.name}: {self.recommended_quantity} units"


class ForecastingConfig(models.Model):
    """
    User configuration for forecasting settings.
    """
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    
    # Forecasting preferences
    default_forecast_days = models.PositiveIntegerField(default=30)
    preferred_model = models.CharField(max_length=30, choices=SalesForecast.MODEL_CHOICES, default='ensemble')
    
    # Auto-restock settings
    auto_generate_recommendations = models.BooleanField(default=True)
    safety_stock_days = models.PositiveIntegerField(default=7, help_text="Buffer stock in days")
    
    # Notification preferences
    notify_on_critical = models.BooleanField(default=True)
    notify_on_high = models.BooleanField(default=True)
    notify_on_medium = models.BooleanField(default=False)
    
    # Advanced settings
    include_seasonal_factors = models.BooleanField(default=True)
    include_trend_analysis = models.BooleanField(default=True)
    include_external_factors = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Forecasting config for {self.user.username}"
