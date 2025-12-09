// Expiry Alerts Screen
// View and manage expiry alerts with filtering and resolution

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expiry_provider.dart';
import '../../models/expiry_models.dart';
import 'alert_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedSeverity = 'all';
  bool _showResolvedOnly = false;
  
  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }
  
  Future<void> _loadAlerts() async {
    final provider = Provider.of<ExpiryProvider>(context, listen: false);
    await provider.loadAlerts(
      severity: _selectedSeverity == 'all' ? null : _selectedSeverity,
      isResolved: _showResolvedOnly ? true : null,
    );
  }
  
  void _onFilterChanged() {
    _loadAlerts();
  }
  
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpiryProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiry Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Critical', 'critical'),
                  const SizedBox(width: 8),
                  _buildFilterChip('High', 'high'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Medium', 'medium'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Low', 'low'),
                ],
              ),
            ),
          ),
          
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${provider.alerts.length} alerts',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${provider.unresolvedAlerts.length} unresolved',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Alerts list
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.alerts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAlerts,
                        child: ListView.builder(
                          itemCount: provider.alerts.length,
                          itemBuilder: (context, index) {
                            return _buildAlertCard(provider.alerts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedSeverity == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSeverity = value;
        });
        _onFilterChanged();
      },
      backgroundColor: Colors.grey[200],
      selectedColor: _getSeverityColor(value),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
  
  Widget _buildAlertCard(ExpiryAlert alert) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(alert.severity),
          child: Icon(
            alert.isResolved ? Icons.check : Icons.warning,
            color: Colors.white,
          ),
        ),
        title: Text(
          alert.productName ?? 'Unknown Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${alert.daysUntilExpiry} days until expiry',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Batch: ${alert.batchNumber}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Action: ${alert.suggestedAction}',
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: Colors.red[600]),
                Text(
                  'Loss: \$${alert.estimatedLoss.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              label: Text(
                alert.severity.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _getSeverityColor(alert.severity),
              padding: EdgeInsets.zero,
            ),
            if (alert.isResolved)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
        isThreeLine: true,
        onTap: () => _navigateToDetail(alert),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No alerts found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All products are in good condition',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Alerts'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Show resolved only'),
                value: _showResolvedOnly,
                onChanged: (value) {
                  setDialogState(() {
                    _showResolvedOnly = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onFilterChanged();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
  
  void _navigateToDetail(ExpiryAlert alert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertDetailScreen(alert: alert),
      ),
    ).then((_) => _loadAlerts());
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
