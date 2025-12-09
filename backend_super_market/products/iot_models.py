"""
IoT Sensor Integration Models
Support for smart shelves, temperature sensors, and environmental monitoring
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from decimal import Decimal

User = get_user_model()


class IoTDevice(models.Model):
    """
    Represent IoT devices in the store
    """
    DEVICE_TYPE_CHOICES = [
        ('smart_shelf', 'Smart Shelf'),
        ('weight_sensor', 'Weight Sensor'),
        ('temperature', 'Temperature Sensor'),
        ('humidity', 'Humidity Sensor'),
        ('door_sensor', 'Door Sensor'),
        ('camera', 'Smart Camera'),
        ('beacon', 'Bluetooth Beacon'),
        ('rfid_reader', 'RFID Reader'),
        ('motion', 'Motion Sensor'),
        ('light', 'Light Sensor'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('maintenance', 'Maintenance'),
        ('error', 'Error'),
        ('offline', 'Offline'),
    ]
    
    # Basic info
    device_id = models.CharField(max_length=100, unique=True)
    device_type = models.CharField(max_length=20, choices=DEVICE_TYPE_CHOICES)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    
    # Location
    store = models.ForeignKey('products.Store', on_delete=models.CASCADE, related_name='iot_devices')
    location = models.ForeignKey('products.ShelfLocation', on_delete=models.SET_NULL, null=True, blank=True, related_name='iot_devices')
    physical_location = models.CharField(max_length=200, help_text="Physical description (e.g., 'Aisle 3, Top Shelf')")
    
    # Network info
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    mac_address = models.CharField(max_length=17, blank=True)
    mqtt_topic = models.CharField(max_length=200, blank=True)
    api_endpoint = models.URLField(blank=True)
    
    # Device specifications
    manufacturer = models.CharField(max_length=100, blank=True)
    model = models.CharField(max_length=100, blank=True)
    firmware_version = models.CharField(max_length=50, blank=True)
    hardware_version = models.CharField(max_length=50, blank=True)
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    last_seen = models.DateTimeField(null=True, blank=True)
    last_heartbeat = models.DateTimeField(null=True, blank=True)
    
    # Configuration
    configuration = models.JSONField(default=dict, help_text="Device-specific configuration")
    calibration_data = models.JSONField(default=dict, help_text="Calibration parameters")
    
    # Alert thresholds
    alert_enabled = models.BooleanField(default=True)
    alert_thresholds = models.JSONField(default=dict, help_text="Custom alert thresholds")
    
    # Battery (for wireless devices)
    battery_level = models.IntegerField(null=True, blank=True, validators=[MinValueValidator(0), MaxValueValidator(100)])
    battery_status = models.CharField(max_length=20, default='ok')
    
    # Maintenance
    installation_date = models.DateField(null=True, blank=True)
    last_maintenance = models.DateField(null=True, blank=True)
    next_maintenance = models.DateField(null=True, blank=True)
    maintenance_notes = models.TextField(blank=True)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_devices')
    
    class Meta:
        ordering = ['store', 'device_type', 'name']
        indexes = [
            models.Index(fields=['device_id']),
            models.Index(fields=['store', 'device_type']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.device_id})"
    
    def is_online(self):
        """Check if device is currently online"""
        if not self.last_heartbeat:
            return False
        # Consider device offline if no heartbeat in last 5 minutes
        return (timezone.now() - self.last_heartbeat).total_seconds() < 300
    
    def needs_maintenance(self):
        """Check if device needs maintenance"""
        if not self.next_maintenance:
            return False
        return timezone.now().date() >= self.next_maintenance
    
    def battery_low(self):
        """Check if battery is low"""
        if self.battery_level is None:
            return False
        return self.battery_level < 20


class SensorReading(models.Model):
    """
    Store sensor readings from IoT devices
    """
    READING_TYPE_CHOICES = [
        ('weight', 'Weight'),
        ('temperature', 'Temperature'),
        ('humidity', 'Humidity'),
        ('motion', 'Motion'),
        ('door_status', 'Door Status'),
        ('light_level', 'Light Level'),
        ('stock_count', 'Stock Count'),
        ('rfid_scan', 'RFID Scan'),
    ]
    
    # Reference
    device = models.ForeignKey(IoTDevice, on_delete=models.CASCADE, related_name='readings')
    reading_type = models.CharField(max_length=20, choices=READING_TYPE_CHOICES)
    
    # Reading data
    value = models.DecimalField(max_digits=10, decimal_places=4)
    unit = models.CharField(max_length=20, help_text="e.g., 'kg', 'C', '%', 'lux'")
    raw_data = models.JSONField(default=dict, help_text="Raw sensor data")
    
    # Context
    product = models.ForeignKey('products.Product', on_delete=models.SET_NULL, null=True, blank=True, related_name='sensor_readings')
    # batch = models.ForeignKey('products.Batch', on_delete=models.SET_NULL, null=True, blank=True, related_name='sensor_readings')  # Batch model doesn't exist
    
    # Status
    is_anomaly = models.BooleanField(default=False)
    anomaly_score = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    alert_triggered = models.BooleanField(default=False)
    
    # Timestamp
    recorded_at = models.DateTimeField(default=timezone.now, db_index=True)
    received_at = models.DateTimeField(auto_now_add=True)
    
    # Quality
    data_quality = models.CharField(max_length=20, choices=[
        ('excellent', 'Excellent'),
        ('good', 'Good'),
        ('fair', 'Fair'),
        ('poor', 'Poor'),
    ], default='good')
    
    class Meta:
        ordering = ['-recorded_at']
        indexes = [
            models.Index(fields=['device', 'reading_type', 'recorded_at']),
            models.Index(fields=['recorded_at']),
            models.Index(fields=['is_anomaly', 'alert_triggered']),
        ]
    
    def __str__(self):
        return f"{self.device.name} - {self.value} {self.unit} at {self.recorded_at}"
    
    def check_threshold(self):
        """Check if reading exceeds alert thresholds"""
        thresholds = self.device.alert_thresholds.get(self.reading_type, {})
        
        if not thresholds or not self.device.alert_enabled:
            return False
        
        min_threshold = thresholds.get('min')
        max_threshold = thresholds.get('max')
        
        if min_threshold is not None and self.value < Decimal(min_threshold):
            return True
        if max_threshold is not None and self.value > Decimal(max_threshold):
            return True
        
        return False


class TemperatureMonitoring(models.Model):
    """
    Specialized model for temperature monitoring with compliance tracking
    """
    ZONE_TYPE_CHOICES = [
        ('freezer', 'Freezer (-18°C or below)'),
        ('refrigerator', 'Refrigerator (0-4°C)'),
        ('chilled', 'Chilled Display (0-8°C)'),
        ('ambient', 'Ambient (15-25°C)'),
        ('hot_display', 'Hot Display (>60°C)'),
    ]
    
    # Reference
    device = models.ForeignKey(IoTDevice, on_delete=models.CASCADE, related_name='temperature_logs')
    zone_type = models.CharField(max_length=20, choices=ZONE_TYPE_CHOICES)
    
    # Temperature data
    temperature = models.DecimalField(max_digits=5, decimal_places=2, help_text="Temperature in Celsius")
    humidity = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, help_text="Relative humidity %")
    
    # Compliance
    is_compliant = models.BooleanField(default=True)
    min_threshold = models.DecimalField(max_digits=5, decimal_places=2)
    max_threshold = models.DecimalField(max_digits=5, decimal_places=2)
    
    # Alert
    alert_sent = models.BooleanField(default=False)
    alert_acknowledged = models.BooleanField(default=False)
    acknowledged_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    acknowledged_at = models.DateTimeField(null=True, blank=True)
    
    # Action taken
    corrective_action = models.TextField(blank=True)
    products_affected = models.ManyToManyField('products.Product', blank=True, related_name='temperature_incidents')
    
    # Timestamp
    recorded_at = models.DateTimeField(default=timezone.now, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-recorded_at']
        indexes = [
            models.Index(fields=['device', 'recorded_at']),
            models.Index(fields=['is_compliant', 'alert_sent']),
        ]
        verbose_name_plural = 'Temperature monitoring records'
    
    def __str__(self):
        return f"{self.device.name} - {self.temperature}°C ({self.zone_type})"
    
    def check_compliance(self):
        """Check if temperature is within acceptable range"""
        self.is_compliant = self.min_threshold <= self.temperature <= self.max_threshold
        self.save()
        return self.is_compliant


class SmartShelfEvent(models.Model):
    """
    Track events from smart shelf sensors (weight changes, stock movements)
    """
    EVENT_TYPE_CHOICES = [
        ('stock_added', 'Stock Added'),
        ('stock_removed', 'Stock Removed'),
        ('stock_low', 'Stock Low'),
        ('stock_empty', 'Stock Empty'),
        ('stock_full', 'Stock Full'),
        ('misplaced', 'Misplaced Item Detected'),
        ('unauthorized_removal', 'Unauthorized Removal'),
    ]
    
    # Reference
    device = models.ForeignKey(IoTDevice, on_delete=models.CASCADE, related_name='shelf_events')
    event_type = models.CharField(max_length=30, choices=EVENT_TYPE_CHOICES)
    
    # Product info
    product = models.ForeignKey('products.Product', on_delete=models.SET_NULL, null=True, blank=True, related_name='shelf_events')
    expected_product = models.ForeignKey('products.Product', on_delete=models.SET_NULL, null=True, blank=True, related_name='expected_shelf_events')
    
    # Stock change
    previous_weight = models.DecimalField(max_digits=10, decimal_places=3, null=True, blank=True)
    current_weight = models.DecimalField(max_digits=10, decimal_places=3, null=True, blank=True)
    weight_change = models.DecimalField(max_digits=10, decimal_places=3, null=True, blank=True)
    
    estimated_quantity_change = models.IntegerField(null=True, blank=True)
    estimated_current_quantity = models.IntegerField(null=True, blank=True)
    
    # Alert
    alert_required = models.BooleanField(default=False)
    alert_sent = models.BooleanField(default=False)
    notification_sent_to = models.ManyToManyField(User, blank=True, related_name='shelf_event_notifications')
    
    # Investigation
    investigated = models.BooleanField(default=False)
    investigation_notes = models.TextField(blank=True)
    investigated_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='investigated_shelf_events')
    investigated_at = models.DateTimeField(null=True, blank=True)
    
    # Additional data
    sensor_data = models.JSONField(default=dict)
    
    # Timestamp
    occurred_at = models.DateTimeField(default=timezone.now, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-occurred_at']
        indexes = [
            models.Index(fields=['device', 'event_type', 'occurred_at']),
            models.Index(fields=['alert_required', 'alert_sent']),
            models.Index(fields=['product', 'occurred_at']),
        ]
    
    def __str__(self):
        return f"{self.device.name} - {self.get_event_type_display()} at {self.occurred_at}"


class DoorTrafficAnalytics(models.Model):
    """
    Track customer traffic patterns from door sensors
    """
    # Reference
    device = models.ForeignKey(IoTDevice, on_delete=models.CASCADE, related_name='traffic_analytics')
    store = models.ForeignKey('products.Store', on_delete=models.CASCADE, related_name='traffic_analytics')
    
    # Time period
    period_start = models.DateTimeField()
    period_end = models.DateTimeField()
    period_type = models.CharField(max_length=20, choices=[
        ('hourly', 'Hourly'),
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
    ])
    
    # Traffic data
    total_entries = models.IntegerField(default=0)
    total_exits = models.IntegerField(default=0)
    peak_hour_entries = models.IntegerField(default=0)
    peak_hour_time = models.TimeField(null=True, blank=True)
    
    average_dwell_time = models.IntegerField(null=True, blank=True, help_text="Average time in store (seconds)")
    
    # Patterns
    traffic_pattern = models.JSONField(default=dict, help_text="Hourly breakdown of traffic")
    busy_periods = models.JSONField(default=list, help_text="List of busy time ranges")
    
    # Conversion
    estimated_customers = models.IntegerField(default=0)
    estimated_conversion_rate = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-period_start']
        indexes = [
            models.Index(fields=['store', 'period_start']),
            models.Index(fields=['period_type', 'period_start']),
        ]
        unique_together = [['device', 'period_start', 'period_type']]
    
    def __str__(self):
        return f"{self.store.name} - {self.period_start.date()} ({self.total_entries} entries)"


class IoTAlert(models.Model):
    """
    Alerts generated by IoT devices
    """
    SEVERITY_CHOICES = [
        ('info', 'Information'),
        ('warning', 'Warning'),
        ('critical', 'Critical'),
        ('emergency', 'Emergency'),
    ]
    
    ALERT_TYPE_CHOICES = [
        ('temperature', 'Temperature Alert'),
        ('humidity', 'Humidity Alert'),
        ('stock_low', 'Low Stock'),
        ('stock_empty', 'Empty Stock'),
        ('device_offline', 'Device Offline'),
        ('battery_low', 'Low Battery'),
        ('sensor_error', 'Sensor Error'),
        ('threshold_breach', 'Threshold Breach'),
        ('unauthorized_access', 'Unauthorized Access'),
    ]
    
    # Reference
    device = models.ForeignKey(IoTDevice, on_delete=models.CASCADE, related_name='alerts')
    sensor_reading = models.ForeignKey(SensorReading, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Alert details
    alert_type = models.CharField(max_length=30, choices=ALERT_TYPE_CHOICES)
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES)
    
    title = models.CharField(max_length=200)
    message = models.TextField()
    
    # Context
    product = models.ForeignKey('products.Product', on_delete=models.SET_NULL, null=True, blank=True)
    location = models.ForeignKey('products.ShelfLocation', on_delete=models.SET_NULL, null=True, blank=True)
    
    # Alert data
    alert_data = models.JSONField(default=dict, help_text="Additional alert information")
    
    # Status
    status = models.CharField(max_length=20, choices=[
        ('open', 'Open'),
        ('acknowledged', 'Acknowledged'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('dismissed', 'Dismissed'),
    ], default='open')
    
    # Response
    acknowledged_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='acknowledged_iot_alerts')
    acknowledged_at = models.DateTimeField(null=True, blank=True)
    
    resolved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='resolved_iot_alerts')
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolution_notes = models.TextField(blank=True)
    
    # Notification
    notification_sent = models.BooleanField(default=False)
    notified_users = models.ManyToManyField(User, blank=True, related_name='iot_alert_notifications')
    
    # Timestamp
    triggered_at = models.DateTimeField(default=timezone.now, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-triggered_at']
        indexes = [
            models.Index(fields=['device', 'status', 'triggered_at']),
            models.Index(fields=['severity', 'status']),
            models.Index(fields=['alert_type', 'status']),
        ]
    
    def __str__(self):
        return f"{self.title} ({self.get_severity_display()}) - {self.device.name}"
    
    def acknowledge(self, user):
        """Acknowledge the alert"""
        self.status = 'acknowledged'
        self.acknowledged_by = user
        self.acknowledged_at = timezone.now()
        self.save()
    
    def resolve(self, user, notes=''):
        """Mark alert as resolved"""
        self.status = 'resolved'
        self.resolved_by = user
        self.resolved_at = timezone.now()
        self.resolution_notes = notes
        self.save()
