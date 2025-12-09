import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/enterprise_models.dart';
import '../providers/audit_provider.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String? _selectedAction;
  String? _selectedContentType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAuditLogs();
    });
  }

  Future<void> _loadAuditLogs() async {
    final provider = context.read<AuditProvider>();
    await provider.fetchAuditLogs(
      action: _selectedAction,
      contentType: _selectedContentType,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          // Export button
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLogs,
          ),
        ],
      ),
      body: Consumer<AuditProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.auditLogs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  ElevatedButton.icon(
                    onPressed: _loadAuditLogs,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.auditLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No audit logs found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: Column(
              children: [
                // Summary cards
                _buildSummaryCards(provider),
                
                // Active filters
                if (_selectedAction != null || _selectedContentType != null || _startDate != null || _endDate != null)
                  _buildActiveFilters(),
                
                // Audit logs list
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.auditLogs.length,
                    itemBuilder: (context, index) {
                      final log = provider.auditLogs[index];
                      return _buildAuditLogCard(log);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(AuditProvider provider) {
    final actionSummary = provider.getActionSummary();
    final contentTypeSummary = provider.getContentTypeSummary();
    
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, color: Colors.blue, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${provider.auditLogs.length}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('Total Logs', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category, color: Colors.orange, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${contentTypeSummary.length}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('Models', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${actionSummary.length}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('Actions', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedAction != null)
            Chip(
              label: Text('Action: $_selectedAction'),
              onDeleted: () {
                setState(() => _selectedAction = null);
                _loadAuditLogs();
              },
            ),
          if (_selectedContentType != null)
            Chip(
              label: Text('Type: $_selectedContentType'),
              onDeleted: () {
                setState(() => _selectedContentType = null);
                _loadAuditLogs();
              },
            ),
          if (_startDate != null)
            Chip(
              label: Text('From: ${DateFormat('MMM d, y').format(_startDate!)}'),
              onDeleted: () {
                setState(() => _startDate = null);
                _loadAuditLogs();
              },
            ),
          if (_endDate != null)
            Chip(
              label: Text('To: ${DateFormat('MMM d, y').format(_endDate!)}'),
              onDeleted: () {
                setState(() => _endDate = null);
                _loadAuditLogs();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(AuditLogModel log) {
    final actionColor = _getActionColor(log.action);
    final actionIcon = _getActionIcon(log.action);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: actionColor.withValues(alpha: 0.2),
          child: Icon(actionIcon, color: actionColor, size: 20),
        ),
        title: Text(
          _formatAction(log.action),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'User #${log.userId} • ${_formatContentType(log.contentType ?? 'Unknown')}',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              _formatTimestamp(log.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: actionColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            log.action.toUpperCase(),
            style: TextStyle(
              color: actionColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('User ID', '#${log.userId}'),
                _buildDetailRow('Action', _formatAction(log.action)),
                _buildDetailRow('Content Type', _formatContentType(log.contentType ?? 'Unknown')),
                _buildDetailRow('Object ID', log.objectId ?? 'N/A'),
                _buildDetailRow('IP Address', log.ipAddress ?? 'Unknown'),
                _buildDetailRow('User Agent', log.userAgent ?? 'Unknown'),
                _buildDetailRow('Timestamp', DateFormat('MMM d, y - h:mm:ss a').format(log.timestamp)),
                
                if (log.changes.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Changes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildChangesView(log.changes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildChangesView(Map<String, dynamic> changes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: changes.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(
                    text: '${entry.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: entry.value.toString()),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'login':
        return Colors.purple;
      case 'logout':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      default:
        return Icons.info;
    }
  }

  String _formatAction(String action) {
    return action.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatContentType(String contentType) {
    return contentType.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Audit Logs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Action filter
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Action'),
                initialValue: _selectedAction,
                items: ['create', 'update', 'delete', 'login', 'logout']
                    .map((action) => DropdownMenuItem(
                          value: action,
                          child: Text(_formatAction(action)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedAction = value),
              ),
              const SizedBox(height: 16),
              
              // Content Type filter
              TextField(
                decoration: const InputDecoration(labelText: 'Content Type'),
                onChanged: (value) => _selectedContentType = value.isEmpty ? null : value,
              ),
              const SizedBox(height: 16),
              
              // Date range
              ListTile(
                title: Text(_startDate != null
                    ? 'From: ${DateFormat('MMM d, y').format(_startDate!)}'
                    : 'Start Date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
              ),
              ListTile(
                title: Text(_endDate != null
                    ? 'To: ${DateFormat('MMM d, y').format(_endDate!)}'
                    : 'End Date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _endDate = date);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedAction = null;
                _selectedContentType = null;
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
              _loadAuditLogs();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAuditLogs();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    final provider = context.read<AuditProvider>();
    final exportData = provider.exportToJson(
      startDate: _startDate,
      endDate: _endDate,
    );
    
    // TODO: Implement actual file export (CSV, JSON, PDF)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${exportData['total_logs']} logs...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Show export data in dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Export Data'),
                content: SingleChildScrollView(
                  child: Text(exportData.toString()),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
