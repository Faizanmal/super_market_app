"""
Serializers for Smart Pricing, IoT, Supplier, and Sustainability features
"""
from rest_framework import serializers
from .smart_pricing_models import (
    PricingRule, DynamicPrice, PriceChangeHistory,
    CompetitorPrice, PriceElasticity
)
from .iot_models import (
    IoTDevice, SensorReading, TemperatureMonitoring,
    SmartShelfEvent, DoorTrafficAnalytics, IoTAlert
)
from .models import Supplier as EnhancedSupplier, SupplierPerformance, SupplierContract
from .supplier_models import (
    AutomatedReorder, SupplierCommunication, SupplierReview
)
from .sustainability_models import (
    SustainabilityMetrics, ProductCarbonFootprint, WasteRecord,
    SustainabilityInitiative, GreenSupplierRating
)


# ==================== Smart Pricing Serializers ====================

class PricingRuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = PricingRule
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class DynamicPriceSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    original_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    discount_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    
    class Meta:
        model = DynamicPrice
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at', 'approved_at', 'approved_by')


class PriceChangeHistorySerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    changed_by_username = serializers.CharField(source='changed_by.username', read_only=True)
    
    class Meta:
        model = PriceChangeHistory
        fields = '__all__'
        read_only_fields = ('created_at',)


class CompetitorPriceSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    price_difference = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = CompetitorPrice
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class PriceElasticitySerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    
    class Meta:
        model = PriceElasticity
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


# ==================== IoT Serializers ====================

class IoTDeviceSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source='store.name', read_only=True)
    battery_status = serializers.CharField(read_only=True)
    
    class Meta:
        model = IoTDevice
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at', 'last_seen')


class SensorReadingSerializer(serializers.ModelSerializer):
    device_name = serializers.CharField(source='device.device_name', read_only=True)
    
    class Meta:
        model = SensorReading
        fields = '__all__'
        read_only_fields = ('recorded_at',)


class TemperatureMonitoringSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    batch_number = serializers.CharField(source='batch.batch_number', read_only=True)
    is_compliant = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = TemperatureMonitoring
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class SmartShelfEventSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    
    class Meta:
        model = SmartShelfEvent
        fields = '__all__'
        read_only_fields = ('created_at',)


class DoorTrafficAnalyticsSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source='store.name', read_only=True)
    
    class Meta:
        model = DoorTrafficAnalytics
        fields = '__all__'
        read_only_fields = ('created_at',)


class IoTAlertSerializer(serializers.ModelSerializer):
    device_name = serializers.CharField(source='device.device_name', read_only=True)
    acknowledged_by_username = serializers.CharField(source='acknowledged_by.username', read_only=True)
    
    class Meta:
        model = IoTAlert
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at', 'acknowledged_at')


# ==================== Supplier Serializers ====================

class EnhancedSupplierSerializer(serializers.ModelSerializer):
    performance_score = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    
    class Meta:
        model = EnhancedSupplier
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at', 'last_order_date')


class SupplierPerformanceSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    on_time_delivery_rate = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    
    class Meta:
        model = SupplierPerformance
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class SupplierContractSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    days_until_expiry = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = SupplierContract
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class AutomatedReorderSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    should_reorder = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = AutomatedReorder
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at', 'last_triggered_at', 'next_check_at')


class SupplierCommunicationSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = SupplierCommunication
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class SupplierReviewSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    reviewed_by_username = serializers.CharField(source='reviewed_by.username', read_only=True)
    
    class Meta:
        model = SupplierReview
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


# ==================== Sustainability Serializers ====================

class SustainabilityMetricsSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source='store.name', read_only=True)
    sustainability_score = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    waste_diversion_rate = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    total_savings = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = SustainabilityMetrics
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class ProductCarbonFootprintSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    total_footprint = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = ProductCarbonFootprint
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class WasteRecordSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source='store.name', read_only=True)
    product_name = serializers.CharField(source='product.name', read_only=True)
    recorded_by_username = serializers.CharField(source='recorded_by.username', read_only=True)
    carbon_impact = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = WasteRecord
        fields = '__all__'
        read_only_fields = ('created_at', 'recorded_at')


class SustainabilityInitiativeSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source='store.name', read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    progress_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    roi_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    
    class Meta:
        model = SustainabilityInitiative
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class GreenSupplierRatingSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    overall_rating = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    rating_category = serializers.CharField(read_only=True)
    
    class Meta:
        model = GreenSupplierRating
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')
