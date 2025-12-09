"""
IoT Sensor Integration API Views
Endpoints for managing IoT devices and sensor data
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal

from .iot_models import (
    IoTDevice, SensorReading, TemperatureMonitoring,
    SmartShelfEvent, DoorTrafficAnalytics, IoTAlert
)


class IoTDeviceViewSet(viewsets.ViewSet):
    """
    ViewSet for IoT device management
    """
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def list_devices(self, request):
        """List all IoT devices"""
        store_id = request.query_params.get('store_id')
        device_type = request.query_params.get('device_type')
        status_filter = request.query_params.get('status')
        
        devices = IoTDevice.objects.all()
        
        if store_id:
            devices = devices.filter(store_id=store_id)
        if device_type:
            devices = devices.filter(device_type=device_type)
        if status_filter:
            devices = devices.filter(status=status_filter)
        
        device_data = []
        for device in devices:
            device_data.append({
                'id': device.id,
                'device_id': device.device_id,
                'name': device.name,
                'type': device.device_type,
                'status': device.status,
                'is_online': device.is_online(),
                'location': device.physical_location,
                'battery_level': device.battery_level,
                'last_seen': device.last_seen,
                'needs_maintenance': device.needs_maintenance(),
            })
        
        return Response({
            'success': True,
            'total_devices': len(device_data),
            'devices': device_data,
        })
    
    @action(detail=False, methods=['post'])
    def register_device(self, request):
        """Register a new IoT device"""
        try:
            device = IoTDevice.objects.create(
                device_id=request.data['device_id'],
                device_type=request.data['device_type'],
                name=request.data['name'],
                store_id=request.data['store_id'],
                physical_location=request.data.get('physical_location', ''),
                ip_address=request.data.get('ip_address'),
                manufacturer=request.data.get('manufacturer', ''),
                model=request.data.get('model', ''),
                created_by=request.user,
            )
            
            return Response({
                'success': True,
                'message': 'Device registered successfully',
                'device_id': device.id,
            })
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e),
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['post'])
    def record_reading(self, request):
        """Record sensor reading from IoT device"""
        try:
            device = IoTDevice.objects.get(device_id=request.data['device_id'])
            
            # Update device last seen
            device.last_heartbeat = timezone.now()
            device.last_seen = timezone.now()
            device.status = 'active'
            
            # Update battery if provided
            if 'battery_level' in request.data:
                device.battery_level = request.data['battery_level']
            
            device.save()
            
            # Create sensor reading
            reading = SensorReading.objects.create(
                device=device,
                reading_type=request.data['reading_type'],
                value=Decimal(str(request.data['value'])),
                unit=request.data['unit'],
                raw_data=request.data.get('raw_data', {}),
                product_id=request.data.get('product_id'),
                batch_id=request.data.get('batch_id'),
            )
            
            # Check if reading exceeds thresholds
            if reading.check_threshold():
                reading.alert_triggered = True
                reading.save()
                
                # Create alert
                IoTAlert.objects.create(
                    device=device,
                    sensor_reading=reading,
                    alert_type='threshold_breach',
                    severity='warning',
                    title=f'{device.name} threshold exceeded',
                    message=f'{reading.reading_type} value of {reading.value} {reading.unit} exceeds threshold',
                    alert_data={'reading_id': reading.id},
                )
            
            return Response({
                'success': True,
                'reading_id': reading.id,
                'alert_triggered': reading.alert_triggered,
            })
        except IoTDevice.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Device not found',
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e),
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def device_readings(self, request):
        """Get sensor readings for a device"""
        device_id = request.query_params.get('device_id')
        reading_type = request.query_params.get('reading_type')
        hours = int(request.query_params.get('hours', 24))
        
        readings = SensorReading.objects.filter(
            device__device_id=device_id,
            recorded_at__gte=timezone.now() - timedelta(hours=hours)
        )
        
        if reading_type:
            readings = readings.filter(reading_type=reading_type)
        
        readings = readings.order_by('-recorded_at')[:1000]
        
        reading_data = []
        for reading in readings:
            reading_data.append({
                'reading_type': reading.reading_type,
                'value': float(reading.value),
                'unit': reading.unit,
                'recorded_at': reading.recorded_at,
                'is_anomaly': reading.is_anomaly,
                'alert_triggered': reading.alert_triggered,
            })
        
        return Response({
            'success': True,
            'total_readings': len(reading_data),
            'readings': reading_data,
        })
    
    @action(detail=False, methods=['get'])
    def temperature_compliance(self, request):
        """Get temperature compliance status"""
        store_id = request.query_params.get('store_id')
        hours = int(request.query_params.get('hours', 24))
        
        temp_records = TemperatureMonitoring.objects.filter(
            recorded_at__gte=timezone.now() - timedelta(hours=hours)
        )
        
        if store_id:
            temp_records = temp_records.filter(device__store_id=store_id)
        
        total_records = temp_records.count()
        compliant_records = temp_records.filter(is_compliant=True).count()
        non_compliant = temp_records.filter(is_compliant=False, alert_acknowledged=False)
        
        compliance_rate = (compliant_records / total_records * 100) if total_records > 0 else 100
        
        non_compliant_data = []
        for record in non_compliant:
            non_compliant_data.append({
                'device_name': record.device.name,
                'zone_type': record.zone_type,
                'temperature': float(record.temperature),
                'min_threshold': float(record.min_threshold),
                'max_threshold': float(record.max_threshold),
                'recorded_at': record.recorded_at,
                'alert_sent': record.alert_sent,
            })
        
        return Response({
            'success': True,
            'compliance_rate': round(compliance_rate, 2),
            'total_records': total_records,
            'compliant': compliant_records,
            'non_compliant': total_records - compliant_records,
            'active_violations': len(non_compliant_data),
            'violations': non_compliant_data,
        })
    
    @action(detail=False, methods=['post'])
    def smart_shelf_event(self, request):
        """Record smart shelf event"""
        try:
            device = IoTDevice.objects.get(device_id=request.data['device_id'])
            
            event = SmartShelfEvent.objects.create(
                device=device,
                event_type=request.data['event_type'],
                product_id=request.data.get('product_id'),
                previous_weight=request.data.get('previous_weight'),
                current_weight=request.data['current_weight'],
                weight_change=request.data.get('weight_change'),
                estimated_quantity_change=request.data.get('quantity_change'),
                alert_required=request.data.get('alert_required', False),
                sensor_data=request.data.get('sensor_data', {}),
            )
            
            # Send alert if required
            if event.alert_required:
                IoTAlert.objects.create(
                    device=device,
                    alert_type='stock_low' if event.event_type == 'stock_low' else 'unauthorized_removal',
                    severity='warning',
                    title=f'Smart Shelf Alert: {event.get_event_type_display()}',
                    message=f'Event detected on {device.name}',
                    product=event.product,
                    location=device.location,
                )
                event.alert_sent = True
                event.save()
            
            return Response({
                'success': True,
                'event_id': event.id,
                'alert_created': event.alert_required,
            })
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e),
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def traffic_analytics(self, request):
        """Get door traffic analytics"""
        store_id = request.query_params.get('store_id')
        days = int(request.query_params.get('days', 7))
        
        analytics = DoorTrafficAnalytics.objects.filter(
            store_id=store_id,
            period_start__gte=timezone.now() - timedelta(days=days)
        ).order_by('-period_start')
        
        analytics_data = []
        for record in analytics:
            analytics_data.append({
                'date': record.period_start.date(),
                'total_entries': record.total_entries,
                'total_exits': record.total_exits,
                'peak_hour_entries': record.peak_hour_entries,
                'peak_hour_time': record.peak_hour_time,
                'average_dwell_time': record.average_dwell_time,
                'estimated_customers': record.estimated_customers,
            })
        
        # Calculate totals
        total_entries = sum(a['total_entries'] for a in analytics_data)
        avg_daily_entries = total_entries / len(analytics_data) if analytics_data else 0
        
        return Response({
            'success': True,
            'period_days': days,
            'total_entries': total_entries,
            'average_daily_entries': round(avg_daily_entries),
            'daily_analytics': analytics_data,
        })
    
    @action(detail=False, methods=['get'])
    def alerts(self, request):
        """Get IoT alerts"""
        store_id = request.query_params.get('store_id')
        status_filter = request.query_params.get('status', 'open')
        severity = request.query_params.get('severity')
        
        alerts = IoTAlert.objects.all()
        
        if store_id:
            alerts = alerts.filter(device__store_id=store_id)
        if status_filter:
            alerts = alerts.filter(status=status_filter)
        if severity:
            alerts = alerts.filter(severity=severity)
        
        alerts = alerts.order_by('-triggered_at')[:100]
        
        alert_data = []
        for alert in alerts:
            alert_data.append({
                'id': alert.id,
                'device_name': alert.device.name,
                'alert_type': alert.alert_type,
                'severity': alert.severity,
                'title': alert.title,
                'message': alert.message,
                'status': alert.status,
                'triggered_at': alert.triggered_at,
                'acknowledged_by': alert.acknowledged_by.username if alert.acknowledged_by else None,
            })
        
        return Response({
            'success': True,
            'total_alerts': len(alert_data),
            'alerts': alert_data,
        })
    
    @action(detail=False, methods=['post'])
    def acknowledge_alert(self, request):
        """Acknowledge an IoT alert"""
        alert_id = request.data.get('alert_id')
        
        try:
            alert = IoTAlert.objects.get(id=alert_id)
            alert.acknowledge(request.user)
            
            return Response({
                'success': True,
                'message': 'Alert acknowledged',
            })
        except IoTAlert.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Alert not found',
            }, status=status.HTTP_404_NOT_FOUND)
