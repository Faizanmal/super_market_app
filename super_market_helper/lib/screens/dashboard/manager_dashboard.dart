// Store Manager Dashboard
// Overview of store operations, alerts, and approvals

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expiry_provider.dart';
import '../../models/expiry_models.dart';
import '../../models/user_model.dart' as user_model;
import '../alerts/alerts_screen.dart';
import '../tasks/tasks_screen.dart';
import '../receiving/receiving_screen.dart';
import '../audits/audits_screen.dart';

class StoreManagerDashboard extends StatefulWidget {
  const StoreManagerDashboard({super.key});
  
  @override
  State<StoreManagerDashboard> createState() => _StoreManagerDashboardState();
}

class _StoreManagerDashboardState extends State<StoreManagerDashboard> {
  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }
  
  Future<void> _loadDashboard() async {
    final expiryProvider = Provider.of<ExpiryProvider>(context, listen: false);
    await Future.wait([
      expiryProvider.loadDashboard(),
      expiryProvider.loadCriticalAlerts(),
      expiryProvider.loadMyTasks(),
    ]);
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final expiryProvider = Provider.of<ExpiryProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: expiryProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    if (authProvider.currentUser != null)
                      _buildUserCard(authProvider.currentUser!),
                    const SizedBox(height: 16),
                    
                    // Critical metrics
                    if (expiryProvider.dashboard != null)
                      _buildMetricsGrid(expiryProvider.dashboard!),
                    
                    const SizedBox(height: 24),
                    
                    // Critical alerts
                    _buildSectionHeader(
                      'Critical Alerts',
                      expiryProvider.criticalAlerts.length,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AlertsScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCriticalAlerts(expiryProvider.criticalAlerts),
                    
                    const SizedBox(height: 24),
                    
                    // Pending tasks
                    _buildSectionHeader(
                      'My Tasks',
                      expiryProvider.myPendingTasks.length,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TasksScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPendingTasks(expiryProvider.myPendingTasks),
                    
                    const SizedBox(height: 24),
                    
                    // Quick actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildUserCard(user_model.User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.role.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    user.store != null ? 'Store Assigned' : 'No Store Assigned',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.store, color: Colors.blue[300], size: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricsGrid(DashboardSummary dashboard) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Critical Alerts',
          dashboard.totalCriticalAlerts.toString(),
          Icons.warning_amber,
          Colors.red,
        ),
        _buildMetricCard(
          'Expiring Soon',
          dashboard.totalExpiringSoon.toString(),
          Icons.schedule,
          Colors.orange,
        ),
        _buildMetricCard(
          'Active Batches',
          dashboard.totalBatches.toString(),
          Icons.inventory_2,
          Colors.blue,
        ),
        _buildMetricCard(
          'Pending Tasks',
          dashboard.totalPendingTasks.toString(),
          Icons.assignment,
          Colors.purple,
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, int count, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$title ($count)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All'),
        ),
      ],
    );
  }
  
  Widget _buildCriticalAlerts(List<ExpiryAlert> alerts) {
    if (alerts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('No critical alerts'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: alerts.take(3).map((alert) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            Icons.warning_amber,
            color: _getAlertColor(alert.severity),
          ),
          title: Text(alert.productName ?? 'Unknown Product'),
          subtitle: Text(alert.message),
          trailing: Text(
            alert.severity.toUpperCase(),
            style: TextStyle(
              color: _getAlertColor(alert.severity),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildPendingTasks(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('No pending tasks'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: tasks.take(3).map((task) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            Icons.assignment,
            color: _getTaskColor(task.priority),
          ),
          title: Text(task.title),
          subtitle: Text(task.description),
          trailing: Text(
            task.priority.toUpperCase(),
            style: TextStyle(
              color: _getTaskColor(task.priority),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildActionCard(
          'Receive Items',
          Icons.inventory,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReceivingScreen()),
          ),
        ),
        _buildActionCard(
          'Start Audit',
          Icons.fact_check,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AuditsScreen()),
          ),
        ),
        _buildActionCard(
          'View Alerts',
          Icons.notifications_active,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AlertsScreen()),
          ),
        ),
        _buildActionCard(
          'My Tasks',
          Icons.task_alt,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TasksScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAlertColor(String severity) {
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

  Color _getTaskColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}