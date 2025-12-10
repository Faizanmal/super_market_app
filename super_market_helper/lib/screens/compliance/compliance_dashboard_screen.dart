/// Compliance Dashboard Screen
/// HACCP tracking, temperature logs, food safety compliance

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ComplianceDashboardScreen extends StatefulWidget {
  const ComplianceDashboardScreen({super.key});

  @override
  State<ComplianceDashboardScreen> createState() => _ComplianceDashboardScreenState();
}

class _ComplianceDashboardScreenState extends State<ComplianceDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Mock data
  final List<TemperatureLog> _temperatureLogs = [
    TemperatureLog(equipment: 'Dairy Fridge #1', temp: 38.5, min: 32, max: 40, status: 'normal'),
    TemperatureLog(equipment: 'Meat Freezer #1', temp: -2.0, min: -10, max: 0, status: 'warning'),
    TemperatureLog(equipment: 'Bakery Display', temp: 68.0, min: 65, max: 75, status: 'normal'),
    TemperatureLog(equipment: 'Produce Cooler', temp: 42.0, min: 32, max: 40, status: 'critical'),
    TemperatureLog(equipment: 'Ice Cream Freezer', temp: -15.0, min: -20, max: -10, status: 'normal'),
  ];

  final List<ComplianceCheck> _recentChecks = [
    ComplianceCheck(type: 'HACCP Audit', date: DateTime.now().subtract(const Duration(days: 5)), result: 'pass', score: 95),
    ComplianceCheck(type: 'Health Inspection', date: DateTime.now().subtract(const Duration(days: 30)), result: 'pass', score: 92),
    ComplianceCheck(type: 'Safety Check', date: DateTime.now().subtract(const Duration(days: 60)), result: 'conditional', score: 85),
  ];

  final List<FoodRecall> _activeRecalls = [
    FoodRecall(
      product: 'Organic Spinach 12oz',
      brand: 'Freshville Farms',
      reason: 'Possible E. coli contamination',
      severity: 'Class I',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  final List<CorrectiveAction> _pendingActions = [
    CorrectiveAction(description: 'Replace door seal on Dairy Fridge #2', priority: 'high', dueDate: DateTime.now().add(const Duration(days: 2))),
    CorrectiveAction(description: 'Calibrate meat thermometers', priority: 'medium', dueDate: DateTime.now().add(const Duration(days: 5))),
    CorrectiveAction(description: 'Update allergen labels on deli items', priority: 'low', dueDate: DateTime.now().add(const Duration(days: 7))),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance & Safety'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exporting compliance report...')),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.thermostat), text: 'Temperature'),
            Tab(icon: Icon(Icons.checklist), text: 'HACCP'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Recalls'),
            Tab(icon: Icon(Icons.assignment), text: 'Actions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemperatureTab(theme),
          _buildHACCPTab(theme),
          _buildRecallsTab(theme),
          _buildActionsTab(theme),
        ],
      ),
    );
  }

  Widget _buildTemperatureTab(ThemeData theme) {
    final critical = _temperatureLogs.where((l) => l.status == 'critical').length;
    final warning = _temperatureLogs.where((l) => l.status == 'warning').length;
    final normal = _temperatureLogs.where((l) => l.status == 'normal').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status summary
        Row(
          children: [
            Expanded(child: _buildStatusCard('Normal', normal, Colors.green, Icons.check_circle)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatusCard('Warning', warning, Colors.orange, Icons.warning)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatusCard('Critical', critical, Colors.red, Icons.error)),
          ],
        ),
        const SizedBox(height: 24),

        // Temperature logs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Equipment Monitoring', style: theme.textTheme.titleMedium),
            TextButton.icon(
              onPressed: _logNewTemperature,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._temperatureLogs.map((log) => _buildTemperatureCard(log, theme)),
      ],
    );
  }

  Widget _buildHACCPTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Compliance score
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: 0.92,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                      ),
                    ),
                    const Column(
                      children: [
                        Text('92%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        Text('Compliance', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Overall HACCP Compliance Score', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Last audit: 5 days ago', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Recent inspections
        Text('Recent Inspections', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._recentChecks.map((check) => _buildInspectionCard(check, theme)),

        const SizedBox(height: 24),

        // Critical Control Points
        Text('Critical Control Points', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildCCPCard('CCP 1: Receiving', 'Temperature check on delivery', true),
        _buildCCPCard('CCP 2: Storage', 'Cold storage temperature', true),
        _buildCCPCard('CCP 3: Display', 'Hot/cold holding temps', false),
        _buildCCPCard('CCP 4: Cooking', 'Internal temperature', true),
      ],
    );
  }

  Widget _buildRecallsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active recalls alert
        if (_activeRecalls.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_activeRecalls.length} Active Recall${_activeRecalls.length > 1 ? 's' : ''}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                      ),
                      const Text('Immediate action required'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Active recalls
        Text('Active Recalls', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._activeRecalls.map((recall) => _buildRecallCard(recall, theme)),

        if (_activeRecalls.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  const Text('No Active Recalls', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('All products are safe', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Allergen tracking
        Text('Allergen Alerts', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildAllergenCard('Peanuts', 23, Colors.red),
        _buildAllergenCard('Tree Nuts', 18, Colors.orange),
        _buildAllergenCard('Dairy', 45, Colors.blue),
        _buildAllergenCard('Gluten', 67, Colors.amber),
        _buildAllergenCard('Shellfish', 12, Colors.pink),
      ],
    );
  }

  Widget _buildActionsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Action summary
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('${_pendingActions.where((a) => a.priority == 'high').length}', 
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                      const Text('High Priority'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('${_pendingActions.where((a) => a.priority == 'medium').length}',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                      const Text('Medium'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('${_pendingActions.where((a) => a.priority == 'low').length}',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                      const Text('Low'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Pending actions
        Text('Pending Corrective Actions', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._pendingActions.map((action) => _buildActionCard(action, theme)),

        const SizedBox(height: 24),

        // Quick actions
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add Corrective Action'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String label, int count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureCard(TemperatureLog log, ThemeData theme) {
    final statusColors = {'normal': Colors.green, 'warning': Colors.orange, 'critical': Colors.red};
    final color = statusColors[log.status] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.thermostat, color: color),
        ),
        title: Text(log.equipment),
        subtitle: Text('Range: ${log.min}°F - ${log.max}°F'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${log.temp}°F',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(log.status.toUpperCase(), style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
        onTap: () => _showTemperatureHistory(log),
      ),
    );
  }

  Widget _buildInspectionCard(ComplianceCheck check, ThemeData theme) {
    final resultColors = {'pass': Colors.green, 'fail': Colors.red, 'conditional': Colors.orange};
    final color = resultColors[check.result] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text('${check.score}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(check.type),
        subtitle: Text(_formatDate(check.date)),
        trailing: Chip(
          label: Text(check.result.toUpperCase(), style: TextStyle(color: color, fontSize: 10)),
          backgroundColor: color.withOpacity(0.1),
          side: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCCPCard(String title, String description, bool isCompliant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isCompliant ? Icons.check_circle : Icons.warning,
          color: isCompliant ? Colors.green : Colors.orange,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: TextButton(
          onPressed: () {},
          child: const Text('Log'),
        ),
      ),
    );
  }

  Widget _buildRecallCard(FoodRecall recall, ThemeData theme) {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(recall.severity, style: const TextStyle(color: Colors.white, fontSize: 10)),
                  backgroundColor: Colors.red,
                  side: BorderSide.none,
                ),
                const Spacer(),
                Text(_formatDate(recall.date), style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(recall.product, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(recall.brand, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(recall.reason),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Pull Products'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergenCard(String allergen, int productCount, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.warning_amber, color: color),
        ),
        title: Text(allergen),
        subtitle: Text('$productCount products contain this allergen'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }

  Widget _buildActionCard(CorrectiveAction action, ThemeData theme) {
    final priorityColors = {'high': Colors.red, 'medium': Colors.orange, 'low': Colors.green};
    final color = priorityColors[action.priority] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(action.description),
        subtitle: Text('Due: ${_formatDate(action.dueDate)}'),
        trailing: Checkbox(value: false, onChanged: (v) {}),
      ),
    );
  }

  void _logNewTemperature() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Temperature', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Equipment'),
              items: _temperatureLogs.map((l) => 
                DropdownMenuItem(value: l.equipment, child: Text(l.equipment))
              ).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: 'Temperature (°F)', suffixText: '°F'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Temperature logged!')),
                  );
                },
                child: const Text('Log Temperature'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemperatureHistory(TemperatureLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.equipment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('24-Hour Temperature History'),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: CustomPaint(
                painter: TempChartPainter(),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Current: ${log.temp}°F'),
            Text('Range: ${log.min}°F - ${log.max}°F'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Data models
class TemperatureLog {
  final String equipment;
  final double temp;
  final double min;
  final double max;
  final String status;

  TemperatureLog({required this.equipment, required this.temp, required this.min, required this.max, required this.status});
}

class ComplianceCheck {
  final String type;
  final DateTime date;
  final String result;
  final int score;

  ComplianceCheck({required this.type, required this.date, required this.result, required this.score});
}

class FoodRecall {
  final String product;
  final String brand;
  final String reason;
  final String severity;
  final DateTime date;

  FoodRecall({required this.product, required this.brand, required this.reason, required this.severity, required this.date});
}

class CorrectiveAction {
  final String description;
  final String priority;
  final DateTime dueDate;

  CorrectiveAction({required this.description, required this.priority, required this.dueDate});
}

class TempChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = [38, 37, 39, 38, 40, 42, 41, 39, 38, 37, 38, 39];
    
    for (var i = 0; i < points.length; i++) {
      final x = i * (size.width / (points.length - 1));
      final y = size.height - ((points[i] - 35) / 10 * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw threshold lines
    paint
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final maxY = size.height - ((40 - 35) / 10 * size.height);
    canvas.drawLine(Offset(0, maxY), Offset(size.width, maxY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
