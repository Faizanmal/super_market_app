import '../models/iot_models.dart';
import '../core/api_client.dart';

/// Service for IoT Device and Sensor API operations
class IoTService {
  final ApiClient _apiClient;

  IoTService(this._apiClient);

  /// Get list of IoT devices
  Future<List<IoTDevice>> getDevices({
    int? storeId,
    String? deviceType,
    String? status,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/iot/list_devices/',
        queryParameters: {
          if (storeId != null) 'store_id': storeId.toString(),
          if (deviceType != null) 'device_type': deviceType,
          if (status != null) 'status': status,
        },
      );

      final devices = (response.data['devices'] as List)
          .map((json) => IoTDevice.fromJson(json))
          .toList();

      return devices;
    } catch (e) {
      throw Exception('Failed to get IoT devices: $e');
    }
  }

  /// Register a new IoT device
  Future<int> registerDevice({
    required String deviceId,
    required String deviceType,
    required String name,
    required int storeId,
    String physicalLocation = '',
    String? ipAddress,
    String manufacturer = '',
    String model = '',
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/iot/register_device/',
        data: {
          'device_id': deviceId,
          'device_type': deviceType,
          'name': name,
          'store_id': storeId,
          'physical_location': physicalLocation,
          'ip_address': ipAddress,
          'manufacturer': manufacturer,
          'model': model,
        },
      );

      return response.data['device_id'];
    } catch (e) {
      throw Exception('Failed to register device: $e');
    }
  }

  /// Record sensor reading
  Future<Map<String, dynamic>> recordReading({
    required String deviceId,
    required String readingType,
    required double value,
    required String unit,
    Map<String, dynamic> rawData = const {},
    int? productId,
    int? batchId,
    int? batteryLevel,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/iot/record_reading/',
        data: {
          'device_id': deviceId,
          'reading_type': readingType,
          'value': value,
          'unit': unit,
          'raw_data': rawData,
          if (productId != null) 'product_id': productId,
          if (batchId != null) 'batch_id': batchId,
          if (batteryLevel != null) 'battery_level': batteryLevel,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to record sensor reading: $e');
    }
  }

  /// Get sensor readings for a device
  Future<List<SensorReading>> getDeviceReadings({
    required String deviceId,
    String? readingType,
    int hours = 24,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/iot/device_readings/',
        queryParameters: {
          'device_id': deviceId,
          if (readingType != null) 'reading_type': readingType,
          'hours': hours.toString(),
        },
      );

      final readings = (response.data['readings'] as List)
          .map((json) => SensorReading.fromJson(json))
          .toList();

      return readings;
    } catch (e) {
      throw Exception('Failed to get device readings: $e');
    }
  }

  /// Get temperature compliance status
  Future<TemperatureCompliance> getTemperatureCompliance({
    int? storeId,
    int hours = 24,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/iot/temperature_compliance/',
        queryParameters: {
          if (storeId != null) 'store_id': storeId.toString(),
          'hours': hours.toString(),
        },
      );

      return TemperatureCompliance.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get temperature compliance: $e');
    }
  }

  /// Record smart shelf event
  Future<Map<String, dynamic>> recordShelfEvent({
    required String deviceId,
    required String eventType,
    int? productId,
    double? previousWeight,
    required double currentWeight,
    double? weightChange,
    int? quantityChange,
    bool alertRequired = false,
    Map<String, dynamic> sensorData = const {},
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/iot/smart_shelf_event/',
        data: {
          'device_id': deviceId,
          'event_type': eventType,
          if (productId != null) 'product_id': productId,
          if (previousWeight != null) 'previous_weight': previousWeight,
          'current_weight': currentWeight,
          if (weightChange != null) 'weight_change': weightChange,
          if (quantityChange != null) 'quantity_change': quantityChange,
          'alert_required': alertRequired,
          'sensor_data': sensorData,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to record shelf event: $e');
    }
  }

  /// Get traffic analytics
  Future<Map<String, dynamic>> getTrafficAnalytics({
    required int storeId,
    int days = 7,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/iot/traffic_analytics/',
        queryParameters: {
          'store_id': storeId.toString(),
          'days': days.toString(),
        },
      );

      final analytics = {
        'total_entries': response.data['total_entries'],
        'average_daily_entries': response.data['average_daily_entries'],
        'daily_analytics': (response.data['daily_analytics'] as List)
            .map((json) => TrafficAnalytics.fromJson(json))
            .toList(),
      };

      return analytics;
    } catch (e) {
      throw Exception('Failed to get traffic analytics: $e');
    }
  }

  /// Get IoT alerts
  Future<List<IoTAlert>> getAlerts({
    int? storeId,
    String status = 'open',
    String? severity,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/iot/alerts/',
        queryParameters: {
          if (storeId != null) 'store_id': storeId.toString(),
          'status': status,
          if (severity != null) 'severity': severity,
        },
      );

      final alerts = (response.data['alerts'] as List)
          .map((json) => IoTAlert.fromJson(json))
          .toList();

      return alerts;
    } catch (e) {
      throw Exception('Failed to get IoT alerts: $e');
    }
  }

  /// Acknowledge an alert
  Future<bool> acknowledgeAlert(int alertId) async {
    try {
      final response = await _apiClient.post(
        '/api/iot/acknowledge_alert/',
        data: {'alert_id': alertId},
      );

      return response.data['success'] ?? false;
    } catch (e) {
      throw Exception('Failed to acknowledge alert: $e');
    }
  }

  /// Get device statistics
  Future<Map<String, dynamic>> getDeviceStatistics(int storeId) async {
    try {
      final devices = await getDevices(storeId: storeId);
      
      final totalDevices = devices.length;
      final activeDevices = devices.where((d) => d.isOnline).length;
      final maintenanceRequired = devices.where((d) => d.needsMaintenance).length;
      final lowBattery = devices.where((d) => d.batteryLevel != null && d.batteryLevel! < 20).length;

      return {
        'total_devices': totalDevices,
        'active_devices': activeDevices,
        'offline_devices': totalDevices - activeDevices,
        'maintenance_required': maintenanceRequired,
        'low_battery': lowBattery,
      };
    } catch (e) {
      throw Exception('Failed to get device statistics: $e');
    }
  }
}
