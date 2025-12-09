import 'package:flutter/material.dart';
import '../../models/supplier_models.dart';
import '../../services/supplier_service.dart';
import '../../core/api_client.dart';

/// Supplier Portal Screen
class SupplierPortalScreen extends StatefulWidget {
  const SupplierPortalScreen({super.key});

  @override
  State<SupplierPortalScreen> createState() => _SupplierPortalScreenState();
}

class _SupplierPortalScreenState extends State<SupplierPortalScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupplierService _supplierService = SupplierService(ApiClient());
  
  List<Supplier> _suppliers = [];
  List<AutomatedReorderRule> _reorderRules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final suppliers = await _supplierService.getSuppliers();
      final reorderRules = await _supplierService.getReorderRules();
      
      setState(() {
        _suppliers = suppliers;
        _reorderRules = reorderRules;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading supplier data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Suppliers', icon: Icon(Icons.store)),
            Tab(text: 'Performance', icon: Icon(Icons.analytics)),
            Tab(text: 'Auto Reorder', icon: Icon(Icons.autorenew)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSuppliersTab(),
                _buildPerformanceTab(),
                _buildAutoReorderTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSupplier,
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
    );
  }

  Widget _buildSuppliersTab() {
    if (_suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No suppliers yet'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addSupplier,
              icon: const Icon(Icons.add),
              label: const Text('Add Supplier'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suppliers.length,
      itemBuilder: (context, index) {
        final supplier = _suppliers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: supplier.isActive ? Colors.green : Colors.grey,
              child: Icon(
                supplier.isActive ? Icons.check : Icons.block,
                color: Colors.white,
              ),
            ),
            title: Text(supplier.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.email),
                Text(supplier.productCategories.join(", ")),
                Row(
                  children: [
                    if (supplier.isPreferred)
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                    if (supplier.hasPortalAccess)
                      const Icon(Icons.verified_user, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Lead Time: ${supplier.leadTimeDays} days',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _viewSupplierDetails(supplier),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildPerformanceTab() {
    // Filter suppliers with performance data
    final suppliersWithPerformance = _suppliers.where((s) => s.performanceScore != null).toList();
    
    if (suppliersWithPerformance.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No performance data available'),
          ],
        ),
      );
    }

    // Sort by performance score
    suppliersWithPerformance.sort((a, b) => (b.performanceScore ?? 0).compareTo(a.performanceScore ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suppliersWithPerformance.length,
      itemBuilder: (context, index) {
        final supplier = suppliersWithPerformance[index];
        final score = supplier.performanceScore ?? 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getPerformanceColor(score),
              child: Text(
                score.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(supplier.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(_getPerformanceColor(score)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (supplier.isPreferred)
                      const Chip(
                        label: Text('Preferred'),
                        avatar: Icon(Icons.star, size: 16),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPerformanceMetric('Overall Score', score),
                    const Divider(),
                    const Text(
                      'Key Metrics',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow('Lead Time', '${supplier.leadTimeDays} days'),
                    _buildMetricRow('Min Order', '\$${supplier.minOrderValue.toStringAsFixed(0)}'),
                    _buildMetricRow(
                      'Payment Terms',
                      '${supplier.paymentTermsDays} days',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _viewPerformanceDetails(supplier),
                          icon: const Icon(Icons.bar_chart),
                          label: const Text('Details'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _contactSupplier(supplier),
                          icon: const Icon(Icons.email),
                          label: const Text('Contact'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAutoReorderTab() {
    if (_reorderRules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.autorenew, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No automated reorder rules'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createReorderRule,
              icon: const Icon(Icons.add),
              label: const Text('Create Rule'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reorderRules.length,
      itemBuilder: (context, index) {
        final rule = _reorderRules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: rule.isActive ? Colors.blue : Colors.grey,
              child: Icon(
                rule.isActive ? Icons.autorenew : Icons.pause,
                color: Colors.white,
              ),
            ),
            title: Text(rule.productName ?? 'Product #${rule.productId}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.supplierName ?? 'Supplier #${rule.supplierId}'),
                const SizedBox(height: 4),
                Text(
                  'Trigger: ${rule.reorderPoint} units → Order: ${rule.reorderQuantity} units',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Switch(
              value: rule.isActive,
              onChanged: (value) => _toggleReorderRule(rule.id, value),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRuleInfo('Reorder Point', '${rule.reorderPoint} units'),
                    _buildRuleInfo('Order Quantity', '${rule.reorderQuantity} units'),
                    _buildRuleInfo('Lead Time Buffer', '${rule.leadTimeBufferDays} days'),
                    if (rule.maxStockLevel != null)
                      _buildRuleInfo('Max Stock Level', '${rule.maxStockLevel} units'),
                    const Divider(),
                    if (rule.lastTriggeredAt != null)
                      _buildRuleInfo(
                        'Last Triggered',
                        _formatDateTime(rule.lastTriggeredAt!),
                      ),
                    _buildRuleInfo(
                      'Next Check',
                      _formatDateTime(rule.nextCheckAt),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _editReorderRule(rule),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _testReorderRule(rule),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceMetric(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getPerformanceColor(value),
                ),
              ),
              const Text('/100'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRuleInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lime;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _addSupplier() {
    showDialog(
      context: context,
      builder: (context) => const AddSupplierDialog(),
    );
  }

  void _viewSupplierDetails(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierDetailsScreen(supplier: supplier),
      ),
    );
  }

  void _viewPerformanceDetails(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierPerformanceScreen(supplierId: supplier.id),
      ),
    );
  }

  void _contactSupplier(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => ContactSupplierDialog(supplier: supplier),
    );
  }

  void _createReorderRule() {
    showDialog(
      context: context,
      builder: (context) => const CreateReorderRuleDialog(),
    );
  }

  Future<void> _toggleReorderRule(int ruleId, bool isActive) async {
    try {
      if (isActive) {
        await _supplierService.activateReorderRule(ruleId);
      } else {
        await _supplierService.deactivateReorderRule(ruleId);
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reorder rule ${isActive ? "activated" : "deactivated"}')),
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

  void _editReorderRule(AutomatedReorderRule rule) {
    showDialog(
      context: context,
      builder: (context) => EditReorderRuleDialog(rule: rule),
    );
  }

  Future<void> _testReorderRule(AutomatedReorderRule rule) async {
    try {
      await _supplierService.testReorderRule(rule.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reorder rule tested successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class SupplierDetailsScreen extends StatelessWidget {
  final Supplier supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(supplier.name),
      ),
      body: const Center(child: Text('Supplier Details')),
    );
  }
}

class SupplierPerformanceScreen extends StatelessWidget {
  final int supplierId;

  const SupplierPerformanceScreen({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Details'),
      ),
      body: const Center(child: Text('Performance analytics')),
    );
  }
}

class AddSupplierDialog extends StatelessWidget {
  const AddSupplierDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Supplier'),
      content: const Text('Supplier form'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ContactSupplierDialog extends StatelessWidget {
  final Supplier supplier;

  const ContactSupplierDialog({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Contact ${supplier.name}'),
      content: const Text('Communication form'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Send'),
        ),
      ],
    );
  }
}

class CreateReorderRuleDialog extends StatelessWidget {
  const CreateReorderRuleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Reorder Rule'),
      content: const Text('Reorder rule form'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class EditReorderRuleDialog extends StatelessWidget {
  final AutomatedReorderRule rule;

  const EditReorderRuleDialog({super.key, required this.rule});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Reorder Rule'),
      content: const Text('Reorder rule form'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
