/// IoT Device and Sensor Models for Flutter
class IoTDevice {
  final int id;
  final String deviceId;
  final String name;
  final String type;
  final String status;
  final bool isOnline;
  final String location;
  final int? batteryLevel;
  final DateTime? lastSeen;
  final bool needsMaintenance;

  IoTDevice({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.type,
    required this.status,
    required this.isOnline,
    required this.location,
    this.batteryLevel,
    this.lastSeen,
    required this.needsMaintenance,
  });

  factory IoTDevice.fromJson(Map<String, dynamic> json) {
    return IoTDevice(
      id: json['id'],
      deviceId: json['device_id'],
      name: json['name'],
      type: json['type'],
      status: json['status'],
      isOnline: json['is_online'] ?? false,
      location: json['location'] ?? '',
      batteryLevel: json['battery_level'],
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      needsMaintenance: json['needs_maintenance'] ?? false,
    );
  }

  String get typeDisplay {
    final types = {
      'smart_shelf': 'Smart Shelf',
      'weight_sensor': 'Weight Sensor',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'door_sensor': 'Door Sensor',
      'camera': 'Camera',
      'beacon': 'Beacon',
      'rfid_reader': 'RFID Reader',
    };
    return types[type] ?? type;
  }

  String get statusDisplay {
    final statuses = {
      'active': 'Active',
      'inactive': 'Inactive',
      'maintenance': 'Maintenance',
      'error': 'Error',
      'offline': 'Offline',
    };
    return statuses[status] ?? status;
  }
}

class SensorReading {
  final String readingType;
  final double value;
  final String unit;
  final DateTime recordedAt;
  final bool isAnomaly;
  final bool alertTriggered;

  SensorReading({
    required this.readingType,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.isAnomaly,
    required this.alertTriggered,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      readingType: json['reading_type'],
      value: double.parse(json['value'].toString()),
      unit: json['unit'],
      recordedAt: DateTime.parse(json['recorded_at']),
      isAnomaly: json['is_anomaly'] ?? false,
      alertTriggered: json['alert_triggered'] ?? false,
    );
  }

  String get displayValue => '${value.toStringAsFixed(2)} $unit';
}

class TemperatureCompliance {
  final double complianceRate;
  final int totalRecords;
  final int compliant;
  final int nonCompliant;
  final int activeViolations;
  final List<TemperatureViolation> violations;

  TemperatureCompliance({
    required this.complianceRate,
    required this.totalRecords,
    required this.compliant,
    required this.nonCompliant,
    required this.activeViolations,
    required this.violations,
  });

  factory TemperatureCompliance.fromJson(Map<String, dynamic> json) {
    return TemperatureCompliance(
      complianceRate: double.parse(json['compliance_rate'].toString()),
      totalRecords: json['total_records'],
      compliant: json['compliant'],
      nonCompliant: json['non_compliant'],
      activeViolations: json['active_violations'],
      violations: (json['violations'] as List)
          .map((v) => TemperatureViolation.fromJson(v))
          .toList(),
    );
  }
}

class TemperatureViolation {
  final String deviceName;
  final String zoneType;
  final double temperature;
  final double minThreshold;
  final double maxThreshold;
  final DateTime recordedAt;
  final bool alertSent;

  TemperatureViolation({
    required this.deviceName,
    required this.zoneType,
    required this.temperature,
    required this.minThreshold,
    required this.maxThreshold,
    required this.recordedAt,
    required this.alertSent,
  });

  factory TemperatureViolation.fromJson(Map<String, dynamic> json) {
    return TemperatureViolation(
      deviceName: json['device_name'],
      zoneType: json['zone_type'],
      temperature: double.parse(json['temperature'].toString()),
      minThreshold: double.parse(json['min_threshold'].toString()),
      maxThreshold: double.parse(json['max_threshold'].toString()),
      recordedAt: DateTime.parse(json['recorded_at']),
      alertSent: json['alert_sent'] ?? false,
    );
  }
}

class TrafficAnalytics {
  final DateTime date;
  final int totalEntries;
  final int totalExits;
  final int peakHourEntries;
  final String? peakHourTime;
  final int? averageDwellTime;
  final int estimatedCustomers;

  TrafficAnalytics({
    required this.date,
    required this.totalEntries,
    required this.totalExits,
    required this.peakHourEntries,
    this.peakHourTime,
    this.averageDwellTime,
    required this.estimatedCustomers,
  });

  factory TrafficAnalytics.fromJson(Map<String, dynamic> json) {
    return TrafficAnalytics(
      date: DateTime.parse(json['date']),
      totalEntries: json['total_entries'],
      totalExits: json['total_exits'],
      peakHourEntries: json['peak_hour_entries'],
      peakHourTime: json['peak_hour_time'],
      averageDwellTime: json['average_dwell_time'],
      estimatedCustomers: json['estimated_customers'],
    );
  }

  String get averageDwellTimeFormatted {
    if (averageDwellTime == null) return 'N/A';
    final minutes = averageDwellTime! ~/ 60;
    final seconds = averageDwellTime! % 60;
    return '$minutes min $seconds sec';
  }
}

class IoTAlert {
  final int id;
  final String deviceName;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final String status;
  final DateTime triggeredAt;
  final String? acknowledgedBy;

  IoTAlert({
    required this.id,
    required this.deviceName,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    required this.status,
    required this.triggeredAt,
    this.acknowledgedBy,
  });

  factory IoTAlert.fromJson(Map<String, dynamic> json) {
    return IoTAlert(
      id: json['id'],
      deviceName: json['device_name'],
      alertType: json['alert_type'],
      severity: json['severity'],
      title: json['title'],
      message: json['message'],
      status: json['status'],
      triggeredAt: DateTime.parse(json['triggered_at']),
      acknowledgedBy: json['acknowledged_by'],
    );
  }
}
