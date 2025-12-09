// Shelf Audits Screen
// Start and manage shelf audits

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/expiry_api_service.dart';
import '../../models/expiry_models.dart';
import 'audit_workflow_screen.dart';

class AuditsScreen extends StatefulWidget {
  const AuditsScreen({super.key});
  
  @override
  State<AuditsScreen> createState() => _AuditsScreenState();
}

class _AuditsScreenState extends State<AuditsScreen> {
  final _apiService = ExpiryApiService();
  List<ShelfAudit> _audits = [];
  bool _isLoading = false;
  String _selectedStatus = 'all';
  
  @override
  void initState() {
    super.initState();
    _loadAudits();
  }
  
  Future<void> _loadAudits() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _audits = await _apiService.getShelfAudits(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        store: authProvider.isHeadOffice ? null : int.tryParse(authProvider.currentUser!.store!.id) ?? 0,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _startNewAudit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.canAudit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to start audits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final auditData = {
        'store': authProvider.currentUser!.store!.id,
        'audit_type': 'routine',
      };
      
      final newAudit = await _apiService.createShelfAudit(auditData);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuditWorkflowScreen(audit: newAudit),
          ),
        ).then((_) => _loadAudits());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelf Audits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAudits,
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
                  _buildFilterChip('In Progress', 'in_progress'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', 'completed'),
                ],
              ),
            ),
          ),
          
          // Audits list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _audits.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAudits,
                        child: ListView.builder(
                          itemCount: _audits.length,
                          itemBuilder: (context, index) {
                            return _buildAuditCard(_audits[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewAudit,
        icon: const Icon(Icons.add),
        label: const Text('Start Audit'),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
        _loadAudits();
      },
    );
  }
  
  Widget _buildAuditCard(ShelfAudit audit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(audit.status),
          child: Icon(
            audit.status == 'completed' ? Icons.check : Icons.fact_check,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Audit #${audit.id}',
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
                  audit.auditType.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(audit.createdAt.toIso8601String()),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (audit.itemsAudited > 0) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${audit.itemsAudited} items audited',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Chip(
          label: Text(
            audit.status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _getStatusColor(audit.status),
        ),
        isThreeLine: true,
        onTap: () {
          if (audit.status == 'in_progress') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuditWorkflowScreen(audit: audit),
              ),
            ).then((_) => _loadAudits());
          }
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No audits found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a new audit to begin',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
