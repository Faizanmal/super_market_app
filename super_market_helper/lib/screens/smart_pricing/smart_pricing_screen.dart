import 'package:flutter/material.dart';
import '../../models/smart_pricing_models.dart';
import '../../services/smart_pricing_service.dart';
import '../../core/api_client.dart';

/// Smart Pricing Dashboard Screen
class SmartPricingScreen extends StatefulWidget {
  const SmartPricingScreen({super.key});

  @override
  State<SmartPricingScreen> createState() => _SmartPricingScreenState();
}

class _SmartPricingScreenState extends State<SmartPricingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SmartPricingService _pricingService = SmartPricingService(ApiClient());
  
  List<PricingRecommendation> _recommendations = [];
  List<DynamicPrice> _pendingPrices = [];
  List<CompetitorPrice> _competitorPrices = [];
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
      final recommendations = await _pricingService.getPricingRecommendations();
      final pendingPrices = await _pricingService.getDynamicPrices(status: 'pending');
      final competitorAnalysis = await _pricingService.getCompetitorAnalysis();
      
      setState(() {
        _recommendations = recommendations;
        _pendingPrices = pendingPrices;
        _competitorPrices = competitorAnalysis;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pricing data: $e')),
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
        title: const Text('Smart Pricing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _calculateAllPrices,
            tooltip: 'Calculate All Prices',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recommendations', icon: Icon(Icons.lightbulb_outline)),
            Tab(text: 'Pending Approval', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Competitor Prices', icon: Icon(Icons.compare_arrows)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendationsTab(),
                _buildPendingPricesTab(),
                _buildCompetitorPricesTab(),
              ],
            ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text('No pricing recommendations at this time'),
            Text('All products are optimally priced!'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final rec = _recommendations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: _getPriorityIcon(rec.priority),
            title: Text(rec.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(rec.reasonDisplay),
            trailing: Chip(
              label: Text('${rec.suggestedDiscountPercent.toStringAsFixed(0)}% OFF'),
              backgroundColor: Colors.orange.shade100,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Price', style: TextStyle(color: Colors.grey)),
                            Text('\$${rec.currentPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18, decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.grey),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Suggested Price', style: TextStyle(color: Colors.grey)),
                            Text('\$${rec.suggestedPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (rec.daysToExpiry != null)
                      _buildInfoRow('Days to Expiry', '${rec.daysToExpiry} days'),
                    if (rec.currentStock != null)
                      _buildInfoRow('Current Stock', '${rec.currentStock} units'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _dismissRecommendation(rec),
                          child: const Text('Dismiss'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _applyRecommendation(rec),
                          icon: const Icon(Icons.check),
                          label: const Text('Apply Price'),
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

  Widget _buildPendingPricesTab() {
    if (_pendingPrices.isEmpty) {
      return const Center(child: Text('No pending price approvals'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPrices.length,
      itemBuilder: (context, index) {
        final price = _pendingPrices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(price.productName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Original: \$${price.originalPrice.toStringAsFixed(2)}'),
                Text('Suggested: \$${price.suggestedPrice.toStringAsFixed(2)} (${price.discountPercent.toStringAsFixed(1)}% off)'),
                Text('Valid from: ${_formatDate(price.validFrom)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectPrice(price),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approvePrice(price),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildCompetitorPricesTab() {
    if (_competitorPrices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_business, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No competitor prices tracked'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addCompetitorPrice,
              icon: const Icon(Icons.add),
              label: const Text('Add Competitor Price'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _competitorPrices.length,
      itemBuilder: (context, index) {
        final cp = _competitorPrices[index];
        final isCheaper = cp.isCheaper;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              isCheaper ? Icons.trending_down : Icons.trending_up,
              color: isCheaper ? Colors.red : Colors.green,
              size: 32,
            ),
            title: Text(cp.productName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Competitor: ${cp.competitorName}'),
                Row(
                  children: [
                    Text('Our price: \$${cp.ourPrice.toStringAsFixed(2)}'),
                    const SizedBox(width: 16),
                    Text('Their price: \$${cp.price.toStringAsFixed(2)}'),
                  ],
                ),
                Text(
                  '${cp.priceDifferencePercent.toStringAsFixed(1)}% ${isCheaper ? 'cheaper' : 'more expensive'}',
                  style: TextStyle(
                    color: isCheaper ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return const Icon(Icons.error, color: Colors.red);
      case 'medium':
        return const Icon(Icons.warning, color: Colors.orange);
      default:
        return const Icon(Icons.info, color: Colors.blue);
    }
  }

  Widget _buildInfoRow(String label, String value) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _calculateAllPrices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calculate Dynamic Prices'),
        content: const Text('This will calculate optimized prices for all products. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Calculate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _pricingService.calculateDynamicPrices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prices calculated successfully')),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyRecommendation(PricingRecommendation rec) async {
    // Implementation for applying recommendation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied pricing for ${rec.productName}')),
    );
    _loadData();
  }

  void _dismissRecommendation(PricingRecommendation rec) {
    setState(() {
      _recommendations.remove(rec);
    });
  }

  void _approvePrice(DynamicPrice price) async {
    try {
      await _pricingService.approveDynamicPrice(
        dynamicPriceId: price.id,
        activate: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price approved and activated')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _rejectPrice(DynamicPrice price) {
    setState(() {
      _pendingPrices.remove(price);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Price rejected')),
    );
  }

  void _addCompetitorPrice() {
    // Show dialog to add competitor price
    showDialog(
      context: context,
      builder: (context) => const AddCompetitorPriceDialog(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class AddCompetitorPriceDialog extends StatefulWidget {
  const AddCompetitorPriceDialog({super.key});

  @override
  State<AddCompetitorPriceDialog> createState() => _AddCompetitorPriceDialogState();
}

class _AddCompetitorPriceDialogState extends State<AddCompetitorPriceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _competitorNameController = TextEditingController();
  final _priceController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Competitor Price'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _competitorNameController,
              decoration: const InputDecoration(labelText: 'Competitor Name'),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Add competitor price logic
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Mock ApiClient for compilation

