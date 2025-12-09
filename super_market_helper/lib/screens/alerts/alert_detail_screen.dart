// Alert Detail Screen
// View alert details and take resolution actions

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expiry_provider.dart';
import '../../models/expiry_models.dart';

class AlertDetailScreen extends StatefulWidget {
  final ExpiryAlert alert;
  
  const AlertDetailScreen({super.key, required this.alert});
  
  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final _notesController = TextEditingController();
  String _selectedAction = 'discount';
  bool _isProcessing = false;
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _acknowledgeAlert() async {
    setState(() => _isProcessing = true);
    
    final provider = Provider.of<ExpiryProvider>(context, listen: false);
    final success = await provider.acknowledgeAlert(widget.alert.id);
    
    setState(() => _isProcessing = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert acknowledged'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
  
  Future<void> _resolveAlert() async {
    if (_notesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter resolution notes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isProcessing = true);
    
    final provider = Provider.of<ExpiryProvider>(context, listen: false);
    final success = await provider.resolveAlert(
      widget.alert.id,
      _selectedAction,
      _notesController.text,
    );
    
    setState(() => _isProcessing = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert resolved successfully'),
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
        title: const Text('Alert Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Severity badge
            Center(
              child: Chip(
                label: Text(
                  widget.alert.severity.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: _getSeverityColor(widget.alert.severity),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Product info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow('Product', widget.alert.productName ?? 'Unknown'),
                    _buildInfoRow('Batch Number', widget.alert.batchNumber ?? 'Unknown'),
                    _buildInfoRow(
                      'Days Until Expiry',
                      '${widget.alert.daysUntilExpiry} days',
                    ),
                    _buildInfoRow(
                      'Current Quantity',
                      (widget.alert.currentQuantity ?? 0).toString(),
                    ),
                    _buildInfoRow(
                      'Estimated Loss',
                      '\$${widget.alert.estimatedLoss.toStringAsFixed(2)}',
                      valueColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Suggested action
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Suggested Action',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.alert.suggestedAction.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Alert status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alert Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Created',
                      _formatDateTime(widget.alert.createdAt.toIso8601String()),
                    ),
                    _buildInfoRow(
                      'Acknowledged',
                      widget.alert.isAcknowledged ? 'Yes' : 'No',
                      valueColor: widget.alert.isAcknowledged ? Colors.green : Colors.orange,
                    ),
                    _buildInfoRow(
                      'Resolved',
                      widget.alert.isResolved ? 'Yes' : 'No',
                      valueColor: widget.alert.isResolved ? Colors.green : Colors.red,
                    ),
                    if (widget.alert.resolvedAt != null)
                      _buildInfoRow(
                        'Resolved At',
                        _formatDateTime(widget.alert.resolvedAt!.toIso8601String()),
                      ),
                    if (widget.alert.resolutionNotes != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Resolution Notes:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.alert.resolutionNotes!),
                    ],
                  ],
                ),
              ),
            ),
            
            if (!widget.alert.isResolved) ...[
              const SizedBox(height: 24),
              
              // Resolution form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resolve Alert',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const Text(
                        'Select Action:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAction,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'discount', child: Text('Apply Discount')),
                          DropdownMenuItem(value: 'clearance', child: Text('Clearance Sale')),
                          DropdownMenuItem(value: 'return', child: Text('Return to Supplier')),
                          DropdownMenuItem(value: 'dispose', child: Text('Dispose')),
                          DropdownMenuItem(value: 'transfer', child: Text('Transfer to Another Store')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAction = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Resolution Notes *',
                          border: OutlineInputBorder(),
                          hintText: 'Describe the action taken...',
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (!widget.alert.isAcknowledged)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isProcessing ? null : _acknowledgeAlert,
                                child: const Text('Acknowledge'),
                              ),
                            ),
                          if (!widget.alert.isAcknowledged)
                            const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _resolveAlert,
                              child: _isProcessing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Resolve'),
                            ),
                          ),
                        ],
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
  
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: valueColor != null ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
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
