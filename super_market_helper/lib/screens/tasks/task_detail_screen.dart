// Task Detail Screen
// View task details and complete tasks

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expiry_provider.dart';
import '../../models/expiry_models.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  
  const TaskDetailScreen({super.key, required this.task});
  
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _notesController = TextEditingController();
  bool _isProcessing = false;
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _startTask() async {
    setState(() => _isProcessing = true);
    
    final provider = Provider.of<ExpiryProvider>(context, listen: false);
    final success = await provider.startTask(widget.task.id);
    
    setState(() => _isProcessing = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task started'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
  
  Future<void> _completeTask() async {
    if (_notesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter completion notes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isProcessing = true);
    
    final provider = Provider.of<ExpiryProvider>(context, listen: false);
    final success = await provider.completeTask(
      widget.task.id,
      _notesController.text,
    );
    
    setState(() => _isProcessing = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Priority badge
            Center(
              child: Chip(
                label: Text(
                  widget.task.priority.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: _getPriorityColor(widget.task.priority),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Task info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Task Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow('Description', widget.task.description),
                    _buildInfoRow(
                      'Type',
                      widget.task.taskType.replaceAll('_', ' ').toUpperCase(),
                    ),
                    _buildInfoRow('Status', widget.task.status.toUpperCase()),
                    _buildInfoRow('Due Date', _formatDateTime(widget.task.dueDate)),
                    if (widget.task.assignedBy != null)
                      _buildInfoRow('Assigned By', widget.task.assignedByName ?? 'Unknown'),
                    _buildInfoRow('Created', _formatDateTime(widget.task.createdAt)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Related info
            if (widget.task.batch != null || widget.task.locationCode != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Related Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.task.batch != null)
                        _buildInfoRow('Batch', 'Batch #${widget.task.batch}'),
                      if (widget.task.locationCode != null)
                        _buildInfoRow('Location', widget.task.locationCode!),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Progress info
            if (widget.task.startedAt != null || widget.task.completedAt != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      if (widget.task.completedAt != null)
                        _buildInfoRow('Completed', _formatDateTime(widget.task.completedAt!)),
                      if (widget.task.completionNotes != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Completion Notes:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.task.completionNotes!),
                      ],
                    ],
                  ),
                ),
              ),
            
            if (widget.task.status != 'completed') ...[
              const SizedBox(height: 24),
              
              // Action form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.status == 'pending' ? 'Start Task' : 'Complete Task',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      if (widget.task.status == 'in_progress') ...[
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Completion Notes *',
                            border: OutlineInputBorder(),
                            hintText: 'Describe what was done...',
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : (widget.task.status == 'pending'
                                  ? _startTask
                                  : _completeTask),
                          icon: Icon(
                            widget.task.status == 'pending'
                                ? Icons.play_arrow
                                : Icons.check,
                          ),
                          label: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.task.status == 'pending'
                                      ? 'Start Task'
                                      : 'Complete Task',
                                ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
}
