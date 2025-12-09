import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/enterprise_models.dart';
import '../providers/inventory_provider.dart';

class InventoryAdjustmentScreen extends StatefulWidget {
  const InventoryAdjustmentScreen({super.key});

  @override
  State<InventoryAdjustmentScreen> createState() => _InventoryAdjustmentScreenState();
}

class _InventoryAdjustmentScreenState extends State<InventoryAdjustmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<InventoryProvider>();
    await provider.fetchAdjustments();
    final stats = await provider.getAdjustmentStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Adjustments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingAdjustments && provider.adjustments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.adjustmentError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.adjustmentError}'),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Statistics Card
              if (_stats != null) _buildStatsCard(_stats!),
              
              // Adjustments List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAdjustmentsList(provider.adjustments, provider),
                    _buildAdjustmentsList(
                      provider.adjustments.where((a) => a.status == 'pending').toList(),
                      provider,
                    ),
                    _buildAdjustmentsList(
                      provider.adjustments.where((a) => a.status == 'approved').toList(),
                      provider,
                    ),
                    _buildAdjustmentsList(
                      provider.adjustments.where((a) => a.status == 'rejected').toList(),
                      provider,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAdjustmentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Adjustment'),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adjustment Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', stats['total_adjustments'].toString(), Icons.inventory, Colors.blue),
                _buildStatItem('Pending', stats['pending_count'].toString(), Icons.pending, Colors.orange),
                _buildStatItem('Approved', stats['approved_count'].toString(), Icons.check_circle, Colors.green),
                _buildStatItem('Rejected', stats['rejected_count'].toString(), Icons.cancel, Colors.red),
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
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAdjustmentsList(List<InventoryAdjustmentModel> adjustments, InventoryProvider provider) {
    if (adjustments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No adjustments found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: adjustments.length,
        itemBuilder: (context, index) {
          final adjustment = adjustments[index];
          return _buildAdjustmentCard(adjustment, provider);
        },
      ),
    );
  }

  Widget _buildAdjustmentCard(InventoryAdjustmentModel adjustment, InventoryProvider provider) {
    final statusColor = _getStatusColor(adjustment.status);
    final isAddition = adjustment.adjustmentQuantity > 0;
    final adjustmentTypeColor = isAddition ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: adjustmentTypeColor.withValues(alpha: 0.2),
          child: Icon(
            isAddition ? Icons.add : Icons.remove,
            color: adjustmentTypeColor,
          ),
        ),
        title: Text(
          adjustment.productName ?? 'Product #${adjustment.productId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${isAddition ? '+' : '-'}${adjustment.adjustmentQuantity.abs()} units',
              style: TextStyle(color: adjustmentTypeColor, fontWeight: FontWeight.w600),
            ),
            Text(
              DateFormat('MMM d, y - h:mm a').format(adjustment.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: _buildStatusChip(adjustment.status, statusColor),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reason
                _buildDetailRow('Reason', adjustment.reason),
                const Divider(),
                
                // Created by
                _buildDetailRow('Created By', adjustment.createdByName ?? 'User #${adjustment.createdById}'),
                
                // Approved by (if applicable)
                if (adjustment.approvedById != null)
                  _buildDetailRow('Approved By', adjustment.approvedByName ?? 'User #${adjustment.approvedById}'),
                
                // Approved at (if applicable)
                if (adjustment.approvedAt != null)
                  _buildDetailRow(
                    'Approved At',
                    DateFormat('MMM d, y - h:mm a').format(adjustment.approvedAt!),
                  ),
                
                // Notes (if any)
                if (adjustment.notes != null && adjustment.notes!.isNotEmpty)
                  _buildDetailRow('Notes', adjustment.notes!),
                
                // Photo (if any)
                if (adjustment.photoEvidence != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Image.network(
                      adjustment.photoEvidence!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 64),
                        );
                      },
                    ),
                  ),
                
                // Action buttons for pending adjustments
                if (adjustment.status == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _rejectAdjustment(adjustment.id, provider),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _approveAdjustment(adjustment.id, provider),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Future<void> _approveAdjustment(int adjustmentId, InventoryProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Adjustment'),
        content: const Text('Are you sure you want to approve this adjustment? This will update the inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.approveAdjustment(adjustmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Adjustment approved successfully' : 'Failed to approve adjustment'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadData();
      }
    }
  }

  Future<void> _rejectAdjustment(int adjustmentId, InventoryProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Adjustment'),
        content: const Text('Are you sure you want to reject this adjustment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.rejectAdjustment(adjustmentId, 'Rejected by user');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Adjustment rejected' : 'Failed to reject adjustment'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
        if (success) _loadData();
      }
    }
  }

  void _showCreateAdjustmentDialog() {
    // TODO: Implement create adjustment dialog with form
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Adjustment'),
        content: const Text('Create adjustment form will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement form submission
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
