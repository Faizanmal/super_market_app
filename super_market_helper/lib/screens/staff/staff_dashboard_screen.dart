/// Staff Dashboard Screen
/// Shows shifts, time tracking, training, and performance

import 'package:flutter/material.dart';
import '../../services/staff_management_service.dart';
import '../../services/api_service.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final StaffManagementService _staffService;
  late final TabController _tabController;
  
  StaffProfile? _profile;
  List<Shift> _shifts = [];
  List<TrainingModule> _trainings = [];
  List<PerformanceReview> _reviews = [];
  List<PayrollRecord> _payroll = [];
  Map<String, dynamic> _clockStatus = {'clocked_in': false};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _staffService = StaffManagementService(ApiService());
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _staffService.getMyProfile(),
      _staffService.getMyShifts(),
      _staffService.getMyTraining(),
      _staffService.getMyReviews(),
      _staffService.getMyPayroll(),
      _staffService.getClockStatus(),
    ]);
    
    setState(() {
      _profile = results[0] as StaffProfile?;
      _shifts = results[1] as List<Shift>;
      _trainings = results[2] as List<TrainingModule>;
      _reviews = results[3] as List<PerformanceReview>;
      _payroll = results[4] as List<PayrollRecord>;
      _clockStatus = results[5] as Map<String, dynamic>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Portal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
            Tab(icon: Icon(Icons.access_time), text: 'Clock'),
            Tab(icon: Icon(Icons.school), text: 'Training'),
            Tab(icon: Icon(Icons.assessment), text: 'Reviews'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleTab(theme),
                _buildClockTab(theme),
                _buildTrainingTab(theme),
                _buildReviewsTab(theme),
              ],
            ),
    );
  }

  Widget _buildScheduleTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile card
        if (_profile != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _profile!.employeeId.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile!.employeeId, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_profile!.position),
                      Text(_profile!.department, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // Upcoming shifts
        Text('Upcoming Shifts', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        
        if (_shifts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No upcoming shifts scheduled')),
            ),
          )
        else
          ..._shifts.take(5).map((shift) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getShiftColor(shift.shiftType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    shift.date.substring(5),
                    style: TextStyle(
                      color: _getShiftColor(shift.shiftType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(shift.shiftType.toUpperCase()),
              subtitle: Text(shift.displayTime),
              trailing: _buildStatusChip(shift.status),
            ),
          )),
        
        const SizedBox(height: 24),
        
        // Request time off
        OutlinedButton.icon(
          onPressed: _showTimeOffDialog,
          icon: const Icon(Icons.event_busy),
          label: const Text('Request Time Off'),
        ),
      ],
    );
  }

  Widget _buildClockTab(ThemeData theme) {
    final isClockedIn = _clockStatus['clocked_in'] ?? false;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Clock status
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isClockedIn ? Colors.green.shade100 : Colors.grey.shade200,
              border: Border.all(
                color: isClockedIn ? Colors.green : Colors.grey,
                width: 4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isClockedIn ? Icons.check_circle : Icons.access_time,
                  size: 64,
                  color: isClockedIn ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  isClockedIn ? 'Clocked In' : 'Clocked Out',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isClockedIn ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Clock button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _handleClock(!isClockedIn),
              icon: Icon(isClockedIn ? Icons.logout : Icons.login),
              label: Text(isClockedIn ? 'Clock Out' : 'Clock In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isClockedIn ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Last action
          if (_clockStatus['timestamp'] != null)
            Text(
              'Last ${_clockStatus['last_action']}: ${_clockStatus['timestamp']}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          
          const SizedBox(height: 40),
          
          // Break buttons
          if (isClockedIn)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.free_breakfast),
                  label: const Text('Start Break'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTrainingTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progress overview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Training Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTrainingStat('Completed', _trainings.where((t) => t.status == 'completed').length),
                    _buildTrainingStat('In Progress', _trainings.where((t) => t.status == 'in_progress').length),
                    _buildTrainingStat('Pending', _trainings.where((t) => t.status == 'not_started').length),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Training list
        Text('My Training', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        
        if (_trainings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No training assigned')),
            ),
          )
        else
          ..._trainings.map((training) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getTrainingStatusColor(training.status).withOpacity(0.2),
                child: Icon(
                  _getTrainingStatusIcon(training.status),
                  color: _getTrainingStatusColor(training.status),
                ),
              ),
              title: Text(training.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${training.durationMinutes} minutes'),
                  if (training.progress != null && training.progress! > 0)
                    LinearProgressIndicator(value: training.progress! / 100),
                ],
              ),
              trailing: training.status != 'completed'
                  ? TextButton(
                      onPressed: () => _startTraining(training),
                      child: Text(training.status == 'in_progress' ? 'Continue' : 'Start'),
                    )
                  : Icon(Icons.check_circle, color: Colors.green.shade400),
            ),
          )),
      ],
    );
  }

  Widget _buildReviewsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Payroll section
        Text('Recent Payroll', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        
        if (_payroll.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(32), child: Text('No payroll records')))
        else
          Card(
            child: Column(
              children: _payroll.take(3).map((record) => ListTile(
                title: Text(record.period),
                subtitle: Text('${record.regularHours}h regular + ${record.overtimeHours}h OT'),
                trailing: Text(
                  '\$${record.netPay.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )).toList(),
            ),
          ),
        
        const SizedBox(height: 24),
        
        // Performance reviews
        Text('Performance Reviews', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        
        if (_reviews.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(32), child: Text('No reviews yet')))
        else
          ..._reviews.map((review) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getScoreColor(review.overallScore).withOpacity(0.2),
                child: Text(
                  review.overallScore?.toStringAsFixed(1) ?? '-',
                  style: TextStyle(
                    color: _getScoreColor(review.overallScore),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(review.type),
              subtitle: Text(review.period),
              trailing: _buildStatusChip(review.status),
            ),
          )),
      ],
    );
  }

  Widget _buildTrainingStat(String label, int value) {
    return Column(
      children: [
        Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = {
      'scheduled': Colors.blue,
      'confirmed': Colors.green,
      'in_progress': Colors.orange,
      'completed': Colors.green,
      'cancelled': Colors.red,
      'draft': Colors.grey,
      'submitted': Colors.blue,
    };
    
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(color: colors[status] ?? Colors.grey, fontSize: 10),
      ),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: (colors[status] ?? Colors.grey).withOpacity(0.1),
    );
  }

  Color _getShiftColor(String type) {
    switch (type) {
      case 'morning': return Colors.orange;
      case 'afternoon': return Colors.blue;
      case 'evening': return Colors.purple;
      case 'night': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  Color _getTrainingStatusColor(String? status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.orange;
      case 'not_started': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _getTrainingStatusIcon(String? status) {
    switch (status) {
      case 'completed': return Icons.check_circle;
      case 'in_progress': return Icons.play_circle;
      case 'not_started': return Icons.circle_outlined;
      default: return Icons.circle_outlined;
    }
  }

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 4) return Colors.green;
    if (score >= 3) return Colors.orange;
    return Colors.red;
  }

  Future<void> _handleClock(bool clockIn) async {
    try {
      if (clockIn) {
        await _staffService.clockIn();
      } else {
        await _staffService.clockOut();
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(clockIn ? 'Clocked in!' : 'Clocked out!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startTraining(TrainingModule training) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting: ${training.name}')),
    );
  }

  void _showTimeOffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Time Off'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Start Date')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: 'End Date')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: 'Reason'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request submitted!')),
            );
          }, child: const Text('Submit')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
