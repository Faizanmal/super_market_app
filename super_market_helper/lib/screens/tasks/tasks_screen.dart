// Tasks Screen
// View and manage assigned tasks

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expiry_provider.dart';
import '../../models/expiry_models.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTasks() async {
    final provider = Provider.of<ExpiryProvider>(context, listen: false);
    await provider.loadMyTasks();
  }
  
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpiryProvider>(context);
    
    final pendingTasks = provider.tasks.where((t) => t.status == 'pending').toList();
    final inProgressTasks = provider.tasks.where((t) => t.status == 'in_progress').toList();
    final completedTasks = provider.tasks.where((t) => t.status == 'completed').toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending (${pendingTasks.length})'),
            Tab(text: 'In Progress (${inProgressTasks.length})'),
            Tab(text: 'Completed (${completedTasks.length})'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(pendingTasks),
                _buildTaskList(inProgressTasks),
                _buildTaskList(completedTasks),
              ],
            ),
    );
  }
  
  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tasks',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(tasks[index]);
        },
      ),
    );
  }
  
  Widget _buildTaskCard(Task task) {
    final isOverdue = task.dueDate.isBefore(DateTime.now()) &&
        task.status != 'completed';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(task.priority),
          child: Icon(
            _getTaskIcon(task.taskType),
            color: Colors.white,
          ),
        ),
        title: Text(
          task.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  task.taskType.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    isOverdue ? Icons.warning : Icons.schedule,
                    size: 14,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${_formatDate(task.dueDate)}',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: isOverdue ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ],
            if (task.assignedBy != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned by: ${task.assignedBy}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              label: Text(
                task.priority.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _getPriorityColor(task.priority),
              padding: EdgeInsets.zero,
            ),
            if (isOverdue)
              const Icon(Icons.priority_high, color: Colors.red, size: 20),
          ],
        ),
        isThreeLine: true,
        onTap: () => _navigateToDetail(task),
      ),
    );
  }
  
  void _navigateToDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    ).then((_) => _loadTasks());
  }
  
  IconData _getTaskIcon(String taskType) {
    switch (taskType) {
      case 'shelf_placement':
        return Icons.inventory_2;
      case 'expiry_check':
        return Icons.schedule;
      case 'audit_followup':
        return Icons.fact_check;
      case 'restocking':
        return Icons.add_box;
      case 'removal':
        return Icons.remove_circle;
      default:
        return Icons.assignment;
    }
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}
