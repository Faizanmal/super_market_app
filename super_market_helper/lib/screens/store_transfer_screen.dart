import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/enterprise_models.dart';
import '../providers/inventory_provider.dart';

class StoreTransferScreen extends StatefulWidget {
  const StoreTransferScreen({super.key});

  @override
  State<StoreTransferScreen> createState() => _StoreTransferScreenState();
}

class _StoreTransferScreenState extends State<StoreTransferScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
    await provider.fetchTransfers();
    final stats = await provider.getTransferStats();
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
        title: const Text('Store Transfers'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Transit'),
            Tab(text: 'Received'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingTransfers && provider.transfers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.transferError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.transferError}'),
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
              if (_stats != null) _buildStatsCard(_stats!),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransfersList(provider.transfers, provider),
                    _buildTransfersList(
                      provider.transfers.where((t) => t.status == 'pending').toList(),
                      provider,
                    ),
                    _buildTransfersList(
                      provider.transfers.where((t) => t.status == 'in_transit').toList(),
                      provider,
                    ),
                    _buildTransfersList(
                      provider.transfers.where((t) => t.status == 'received').toList(),
                      provider,
                    ),
                    _buildTransfersList(
                      provider.transfers.where((t) => t.status == 'cancelled').toList(),
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
        onPressed: () => _showCreateTransferDialog(),
        icon: const Icon(Icons.swap_horiz),
        label: const Text('New Transfer'),
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
              'Transfer Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', stats['total_transfers'].toString(), Icons.swap_horiz, Colors.blue),
                _buildStatItem('Pending', stats['pending_count'].toString(), Icons.pending, Colors.orange),
                _buildStatItem('In Transit', stats['in_transit_count'].toString(), Icons.local_shipping, Colors.purple),
                _buildStatItem('Received', stats['received_count'].toString(), Icons.check_circle, Colors.green),
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

  Widget _buildTransfersList(List<StoreTransferModel> transfers, InventoryProvider provider) {
    if (transfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No transfers found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: transfers.length,
        itemBuilder: (context, index) {
          final transfer = transfers[index];
          return _buildTransferCard(transfer, provider);
        },
      ),
    );
  }

  Widget _buildTransferCard(StoreTransferModel transfer, InventoryProvider provider) {
    final statusColor = _getStatusColor(transfer.status);
    final statusIcon = _getStatusIcon(transfer.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          'Transfer #${transfer.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'From Store #${transfer.fromStoreId} → To Store #${transfer.toStoreId}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'Product #${transfer.productId} - ${transfer.quantity} units',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              DateFormat('MMM d, y').format(transfer.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: _buildStatusChip(transfer.status, statusColor),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Transfer ID', '#${transfer.id}'),
                _buildDetailRow('Product ID', '#${transfer.productId}'),
                _buildDetailRow('Quantity', '${transfer.quantity} units'),
                const Divider(),
                _buildDetailRow('From Store', 'Store #${transfer.fromStoreId}'),
                _buildDetailRow('To Store', 'Store #${transfer.toStoreId}'),
                const Divider(),
                _buildDetailRow('Status', transfer.status.toUpperCase()),
                _buildDetailRow('Created', DateFormat('MMM d, y - h:mm a').format(transfer.createdAt)),
                _buildDetailRow('Created By', 'User #${transfer.createdBy}'),
                
                if (transfer.shippedAt != null)
                  _buildDetailRow('Shipped', DateFormat('MMM d, y - h:mm a').format(transfer.shippedAt!)),
                
                if (transfer.receivedAt != null)
                  _buildDetailRow('Received', DateFormat('MMM d, y - h:mm a').format(transfer.receivedAt!)),
                
                if (transfer.estimatedArrival != null)
                  _buildDetailRow('Est. Arrival', DateFormat('MMM d, y').format(transfer.estimatedArrival!)),
                
                if (transfer.notes != null && transfer.notes!.isNotEmpty)
                  _buildDetailRow('Notes', transfer.notes!),
                
                // Status timeline
                const SizedBox(height: 16),
                _buildStatusTimeline(transfer),
                
                // Action buttons
                _buildActionButtons(transfer, provider),
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

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusTimeline(StoreTransferModel transfer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transfer Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildTimelineItem(
          'Created',
          DateFormat('MMM d, y - h:mm a').format(transfer.createdAt),
          Icons.add_circle,
          Colors.blue,
          isCompleted: true,
        ),
        _buildTimelineItem(
          'Shipped',
          transfer.shippedAt != null ? DateFormat('MMM d, y - h:mm a').format(transfer.shippedAt!) : 'Pending',
          Icons.local_shipping,
          Colors.orange,
          isCompleted: transfer.shippedAt != null,
        ),
        _buildTimelineItem(
          'Received',
          transfer.receivedAt != null ? DateFormat('MMM d, y - h:mm a').format(transfer.receivedAt!) : 'Pending',
          Icons.check_circle,
          Colors.green,
          isCompleted: transfer.receivedAt != null,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String time, IconData icon, Color color, {bool isCompleted = false, bool isLast = false}) {
    return Row(
      children: [
        Column(
          children: [
            Icon(icon, color: isCompleted ? color : Colors.grey, size: 24),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isCompleted ? Colors.black : Colors.grey)),
              Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(StoreTransferModel transfer, InventoryProvider provider) {
    if (transfer.status == 'received' || transfer.status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel button (available for pending and in_transit)
          if (transfer.status != 'received')
            OutlinedButton.icon(
              onPressed: () => _cancelTransfer(transfer.id, provider),
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(width: 12),
          
          // Ship button (only for pending)
          if (transfer.status == 'pending')
            ElevatedButton.icon(
              onPressed: () => _shipTransfer(transfer.id, provider),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Mark as Shipped'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          
          // Receive button (only for in_transit)
          if (transfer.status == 'in_transit')
            ElevatedButton.icon(
              onPressed: () => _receiveTransfer(transfer.id, provider),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Received'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_transit':
        return Colors.purple;
      case 'received':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'in_transit':
        return Icons.local_shipping;
      case 'received':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Future<void> _shipTransfer(int transferId, InventoryProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ship Transfer'),
        content: const Text('Mark this transfer as shipped?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ship'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.shipTransfer(transferId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Transfer shipped successfully' : 'Failed to ship transfer'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadData();
      }
    }
  }

  Future<void> _receiveTransfer(int transferId, InventoryProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receive Transfer'),
        content: const Text('Confirm that this transfer has been received? This will update the inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Receive'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.receiveTransfer(transferId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Transfer received successfully' : 'Failed to receive transfer'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadData();
      }
    }
  }

  Future<void> _cancelTransfer(int transferId, InventoryProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Transfer'),
        content: const Text('Are you sure you want to cancel this transfer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.cancelTransfer(transferId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Transfer cancelled' : 'Failed to cancel transfer'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
        if (success) _loadData();
      }
    }
  }

  void _showCreateTransferDialog() {
    // TODO: Implement create transfer form
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Transfer'),
        content: const Text('Create transfer form will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
