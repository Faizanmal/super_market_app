import 'package:flutter/material.dart';
import '../../models/iot_models.dart';
import '../../services/iot_service.dart';
import '../../core/api_client.dart';

/// IoT Devices Monitoring Dashboard
class IoTDashboardScreen extends StatefulWidget {
  const IoTDashboardScreen({super.key});

  @override
  State<IoTDashboardScreen> createState() => _IoTDashboardScreenState();
}

class _IoTDashboardScreenState extends State<IoTDashboardScreen> {
  final IoTService _iotService = IoTService(ApiClient());
  
  List<IoTDevice> _devices = [];
  List<IoTAlert> _alerts = [];
  TemperatureCompliance? _tempCompliance;
  Map<String, dynamic> _deviceStats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final devices = await _iotService.getDevices();
      final alerts = await _iotService.getAlerts(status: 'open');
      final tempCompliance = await _iotService.getTemperatureCompliance();
      final stats = await _iotService.getDeviceStatistics(1); // Store ID
      
      setState(() {
        _devices = devices;
        _alerts = alerts;
        _tempCompliance = tempCompliance;
        _deviceStats = stats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading IoT data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDeviceStatsCard(),
                  const SizedBox(height: 16),
                  _buildTemperatureComplianceCard(),
                  const SizedBox(height: 16),
                  _buildAlertsCard(),
                  const SizedBox(height: 16),
                  _buildDevicesGrid(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registerNewDevice,
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
      ),
    );
  }

  Widget _buildDeviceStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  _deviceStats['total_devices']?.toString() ?? '0',
                  Icons.devices,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Active',
                  _deviceStats['active_devices']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Offline',
                  _deviceStats['offline_devices']?.toString() ?? '0',
                  Icons.error,
                  Colors.red,
                ),
                _buildStatItem(
                  'Maintenance',
                  _deviceStats['maintenance_required']?.toString() ?? '0',
                  Icons.build,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildTemperatureComplianceCard() {
    if (_tempCompliance == null) return const SizedBox();

    final compliance = _tempCompliance!;
    final isCompliant = compliance.complianceRate >= 95;

    return Card(
      color: isCompliant ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Temperature Compliance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(
                  isCompliant ? Icons.check_circle : Icons.warning,
                  color: isCompliant ? Colors.green : Colors.red,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: compliance.complianceRate / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                isCompliant ? Colors.green : Colors.red,
              ),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              '${compliance.complianceRate.toStringAsFixed(1)}% Compliant',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Records: ${compliance.totalRecords}'),
                Text('Violations: ${compliance.activeViolations}',
                    style: TextStyle(
                      color: compliance.activeViolations > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            if (compliance.violations.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Active Violations:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ...compliance.violations.take(3).map((v) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.thermostat, color: Colors.red),
                    title: Text(v.deviceName),
                    subtitle: Text('${v.temperature.toStringAsFixed(1)}°C (Range: ${v.minThreshold}-${v.maxThreshold}°C)'),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsCard() {
    if (_alerts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              const SizedBox(width: 16),
              const Text('No active alerts', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.red),
            title: Text('${_alerts.length} Active Alerts'),
            trailing: TextButton(
              onPressed: () => _showAllAlerts(),
              child: const Text('View All'),
            ),
          ),
          const Divider(height: 1),
          ..._alerts.take(3).map((alert) => _buildAlertItem(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(IoTAlert alert) {
    Color severityColor;
    switch (alert.severity) {
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'warning':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.blue;
    }

    return ListTile(
      leading: Icon(Icons.error, color: severityColor),
      title: Text(alert.title),
      subtitle: Text('${alert.deviceName} - ${alert.message}'),
      trailing: IconButton(
        icon: const Icon(Icons.check),
        onPressed: () => _acknowledgeAlert(alert),
      ),
      dense: true,
    );
  }

  Widget _buildDevicesGrid() {
    if (_devices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.devices_other, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No IoT devices registered'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _registerNewDevice,
                  icon: const Icon(Icons.add),
                  label: const Text('Register Device'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Devices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _devices.length,
          itemBuilder: (context, index) {
            final device = _devices[index];
            return _buildDeviceCard(device);
          },
        ),
      ],
    );
  }

  Widget _buildDeviceCard(IoTDevice device) {
    final statusColor = device.isOnline ? Colors.green : Colors.grey;
    final typeIcon = _getDeviceIcon(device.type);

    return Card(
      child: InkWell(
        onTap: () => _showDeviceDetails(device),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(typeIcon, size: 32, color: statusColor),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                device.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                device.typeDisplay,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              if (device.batteryLevel != null)
                Row(
                  children: [
                    Icon(
                      Icons.battery_std,
                      size: 16,
                      color: device.batteryLevel! < 20 ? Colors.red : Colors.green,
                    ),
                    Text('${device.batteryLevel}%', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              if (device.needsMaintenance)
                const Row(
                  children: [
                    Icon(Icons.build, size: 16, color: Colors.orange),
                    Text('Maintenance', style: TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'smart_shelf':
        return Icons.shelves;
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'door_sensor':
        return Icons.sensor_door;
      case 'camera':
        return Icons.videocam;
      case 'weight_sensor':
        return Icons.scale;
      default:
        return Icons.devices;
    }
  }

  void _showDeviceDetails(IoTDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailScreen(device: device),
      ),
    );
  }

  void _acknowledgeAlert(IoTAlert alert) async {
    try {
      await _iotService.acknowledgeAlert(alert.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert acknowledged')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAllAlerts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IoTAlertsScreen(alerts: _alerts),
      ),
    );
  }

  void _registerNewDevice() {
    // Show dialog to register new device
    showDialog(
      context: context,
      builder: (context) => const RegisterDeviceDialog(),
    );
  }
}

class DeviceDetailScreen extends StatelessWidget {
  final IoTDevice device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Device ID'),
              subtitle: Text(device.deviceId),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Type'),
              subtitle: Text(device.typeDisplay),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Status'),
              subtitle: Text(device.statusDisplay),
              trailing: Icon(
                device.isOnline ? Icons.check_circle : Icons.error,
                color: device.isOnline ? Colors.green : Colors.red,
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Location'),
              subtitle: Text(device.location),
            ),
          ),
        ],
      ),
    );
  }
}

class IoTAlertsScreen extends StatelessWidget {
  final List<IoTAlert> alerts;

  const IoTAlertsScreen({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Alerts'),
      ),
      body: ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return ListTile(
            title: Text(alert.title),
            subtitle: Text(alert.message),
            trailing: Text(alert.severity),
          );
        },
      ),
    );
  }
}

class RegisterDeviceDialog extends StatelessWidget {
  const RegisterDeviceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register IoT Device'),
      content: const Text('Device registration form'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Register'),
        ),
      ],
    );
  }
}

