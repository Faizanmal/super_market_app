"""
Serializers for new features: Batch Discounts, Sales Forecasting, Customer Features.
"""
from rest_framework import serializers
from decimal import Decimal

from .batch_discount_models import (
    DiscountRule, BatchDiscount, DiscountNotification, DiscountAnalytics
)
from .sales_forecasting_models import (
    SalesHistory, SalesForecast, SeasonalPattern, 
    RestockRecommendation, ForecastingConfig
)
from .customer_features_models import (
    ShoppingList, ShoppingListItem, DigitalReceipt, 
    ReceiptItem, WarrantyTracker, WarrantyClaim
)


# ============================================================================
# Batch Discount Serializers
# ============================================================================

class DiscountRuleSerializer(serializers.ModelSerializer):
    """Serializer for discount rules."""
    savings_preview = serializers.SerializerMethodField()
    
    class Meta:
        model = DiscountRule
        fields = [
            'id', 'name', 'description', 'days_before_expiry',
            'discount_type', 'discount_value', 'max_discount_percentage',
            'apply_to_all', 'categories', 'products', 'status', 'priority',
            'savings_preview', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'savings_preview', 'created_at', 'updated_at']
    
    def get_savings_preview(self, obj):
        """Calculate estimated savings if applied."""
        return {
            'type': obj.discount_type,
            'value': str(obj.discount_value),
            'max_percentage': str(obj.max_discount_percentage)
        }


class BatchDiscountSerializer(serializers.ModelSerializer):
    """Serializer for applied batch discounts."""
    product_name = serializers.CharField(source='product.name', read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    savings_amount = serializers.DecimalField(
        max_digits=10, decimal_places=2, read_only=True
    )
    
    class Meta:
        model = BatchDiscount
        fields = [
            'id', 'product', 'product_name', 'rule',
            'original_price', 'discounted_price', 'discount_percentage',
            'start_date', 'end_date', 'status',
            'quantity_at_discount', 'quantity_sold_at_discount',
            'is_active', 'savings_amount', 'created_at'
        ]
        read_only_fields = ['id', 'is_active', 'savings_amount', 'created_at']


class DiscountAnalyticsSerializer(serializers.ModelSerializer):
    """Serializer for discount analytics."""
    savings_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = DiscountAnalytics
        fields = [
            'id', 'date', 'total_discounts_applied', 'total_products_discounted',
            'total_original_value', 'total_discounted_value', 'total_sold_value',
            'waste_prevented_value', 'waste_prevented_quantity', 'savings_rate'
        ]
    
    def get_savings_rate(self, obj):
        if obj.total_original_value > 0:
            saved = obj.total_original_value - obj.total_discounted_value
            return round((saved / obj.total_original_value) * 100, 2)
        return 0


# ============================================================================
# Sales Forecasting Serializers
# ============================================================================

class SalesHistorySerializer(serializers.ModelSerializer):
    """Serializer for sales history."""
    product_name = serializers.CharField(source='product.name', read_only=True)
    
    class Meta:
        model = SalesHistory
        fields = [
            'id', 'product', 'product_name', 'date',
            'quantity_sold', 'revenue', 'cost', 'profit',
            'was_on_discount', 'discount_percentage',
            'day_of_week', 'is_weekend', 'is_holiday', 'holiday_name'
        ]
        read_only_fields = ['id', 'day_of_week', 'is_weekend']


class SalesForecastSerializer(serializers.ModelSerializer):
    """Serializer for sales forecasts."""
    product_name = serializers.CharField(source='product.name', read_only=True)
    accuracy_rating = serializers.SerializerMethodField()
    
    class Meta:
        model = SalesForecast
        fields = [
            'id', 'product', 'product_name', 'forecast_date',
            'predicted_quantity', 'predicted_revenue',
            'lower_bound', 'upper_bound',
            'confidence_level', 'confidence_score',
            'model_used', 'model_accuracy',
            'actual_quantity', 'actual_revenue', 'forecast_error',
            'accuracy_rating', 'generated_at'
        ]
        read_only_fields = ['id', 'accuracy_rating', 'generated_at']
    
    def get_accuracy_rating(self, obj):
        if obj.model_accuracy >= 90:
            return 'excellent'
        elif obj.model_accuracy >= 75:
            return 'good'
        elif obj.model_accuracy >= 60:
            return 'fair'
        return 'needs_improvement'


class SeasonalPatternSerializer(serializers.ModelSerializer):
    """Serializer for seasonal patterns."""
    target_name = serializers.SerializerMethodField()
    
    class Meta:
        model = SeasonalPattern
        fields = [
            'id', 'product', 'category', 'target_name',
            'pattern_type', 'pattern_data',
            'peak_periods', 'low_periods',
            'confidence_score', 'sample_size',
            'detected_at', 'updated_at'
        ]
    
    def get_target_name(self, obj):
        if obj.product:
            return obj.product.name
        elif obj.category:
            return obj.category.name
        return 'Unknown'


class RestockRecommendationSerializer(serializers.ModelSerializer):
    """Serializer for restock recommendations."""
    product_name = serializers.CharField(source='product.name', read_only=True)
    supplier_name = serializers.CharField(source='suggested_supplier.name', read_only=True)
    days_until_stockout = serializers.SerializerMethodField()
    
    class Meta:
        model = RestockRecommendation
        fields = [
            'id', 'product', 'product_name',
            'recommended_quantity', 'recommended_order_date', 'expected_stockout_date',
            'urgency', 'status',
            'suggested_supplier', 'supplier_name',
            'estimated_cost', 'estimated_lead_time_days',
            'reason', 'confidence_score',
            'days_until_stockout',
            'generated_at', 'actioned_at'
        ]
        read_only_fields = ['id', 'days_until_stockout', 'generated_at']
    
    def get_days_until_stockout(self, obj):
        from django.utils import timezone
        return (obj.expected_stockout_date - timezone.now().date()).days


class ForecastingConfigSerializer(serializers.ModelSerializer):
    """Serializer for forecasting configuration."""
    
    class Meta:
        model = ForecastingConfig
        fields = [
            'id', 'default_forecast_days', 'preferred_model',
            'auto_generate_recommendations', 'safety_stock_days',
            'notify_on_critical', 'notify_on_high', 'notify_on_medium',
            'include_seasonal_factors', 'include_trend_analysis', 'include_external_factors',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


# ============================================================================
# Customer Features Serializers
# ============================================================================

class ShoppingListItemSerializer(serializers.ModelSerializer):
    """Serializer for shopping list items."""
    product_name = serializers.SerializerMethodField()
    item_name = serializers.SerializerMethodField()
    
    class Meta:
        model = ShoppingListItem
        fields = [
            'id', 'product', 'product_name', 'item_name',
            'custom_name', 'custom_note', 'quantity',
            'estimated_price', 'actual_price',
            'status', 'priority', 'is_essential',
            'aisle_location', 'shelf_location',
            'added_at', 'checked_off_at'
        ]
        read_only_fields = ['id', 'added_at']
    
    def get_product_name(self, obj):
        return obj.product.name if obj.product else None
    
    def get_item_name(self, obj):
        return obj.product.name if obj.product else obj.custom_name


class ShoppingListSerializer(serializers.ModelSerializer):
    """Serializer for shopping lists."""
    items = ShoppingListItemSerializer(many=True, read_only=True)
    items_count = serializers.SerializerMethodField()
    completed_count = serializers.SerializerMethodField()
    progress_percentage = serializers.SerializerMethodField()
    
    class Meta:
        model = ShoppingList
        fields = [
            'id', 'name', 'description',
            'is_shared', 'share_code', 'store',
            'status', 'planned_date', 'completed_date',
            'estimated_total', 'actual_total', 'budget_limit',
            'items', 'items_count', 'completed_count', 'progress_percentage',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'share_code', 'items_count', 'completed_count', 'progress_percentage', 'created_at', 'updated_at']
    
    def get_items_count(self, obj):
        return obj.items.count()
    
    def get_completed_count(self, obj):
        return obj.items.filter(status='purchased').count()
    
    def get_progress_percentage(self, obj):
        total = obj.items.count()
        if total == 0:
            return 0
        completed = obj.items.filter(status='purchased').count()
        return round((completed / total) * 100, 1)


class ReceiptItemSerializer(serializers.ModelSerializer):
    """Serializer for receipt items."""
    
    class Meta:
        model = ReceiptItem
        fields = [
            'id', 'product', 'product_name', 'product_sku', 'barcode',
            'quantity', 'unit_price', 'discount', 'total_price',
            'has_warranty', 'warranty_months', 'warranty_expiry'
        ]


class DigitalReceiptSerializer(serializers.ModelSerializer):
    """Serializer for digital receipts."""
    items = ReceiptItemSerializer(many=True, read_only=True)
    store_name = serializers.CharField(source='store.name', read_only=True)
    items_count = serializers.SerializerMethodField()
    
    class Meta:
        model = DigitalReceipt
        fields = [
            'id', 'receipt_number', 'store', 'store_name',
            'transaction_date',
            'subtotal', 'tax_amount', 'discount_amount', 'total_amount',
            'payment_method', 'payment_reference',
            'qr_code', 'pdf_url',
            'items', 'items_count',
            'created_at'
        ]
        read_only_fields = ['id', 'items_count', 'created_at']
    
    def get_items_count(self, obj):
        return obj.items.count()


class WarrantyClaimSerializer(serializers.ModelSerializer):
    """Serializer for warranty claims."""
    
    class Meta:
        model = WarrantyClaim
        fields = [
            'id', 'claim_date', 'issue_description',
            'status', 'resolution', 'resolution_date',
            'replacement_provided', 'repair_done', 'refund_amount',
            'images', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class WarrantyTrackerSerializer(serializers.ModelSerializer):
    """Serializer for warranty tracking."""
    days_remaining = serializers.IntegerField(read_only=True)
    claims = WarrantyClaimSerializer(many=True, read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = WarrantyTracker
        fields = [
            'id', 'product_name', 'serial_number',
            'purchase_date', 'warranty_start_date', 'warranty_end_date',
            'status', 'status_display', 'days_remaining',
            'reminder_days_before', 'reminder_sent',
            'warranty_terms', 'claim_instructions', 'manufacturer_contact',
            'warranty_document_url', 'proof_of_purchase_url',
            'times_claimed', 'last_claim_date',
            'claims', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'days_remaining', 'status_display', 'created_at', 'updated_at']


class WarrantyDashboardSerializer(serializers.Serializer):
    """Serializer for warranty dashboard overview."""
    total_warranties = serializers.IntegerField()
    active_warranties = serializers.IntegerField()
    expiring_soon = serializers.IntegerField()
    expired = serializers.IntegerField()
    upcoming_expirations = WarrantyTrackerSerializer(many=True)
