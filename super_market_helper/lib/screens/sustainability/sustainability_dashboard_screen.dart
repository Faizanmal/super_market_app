import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/sustainability_models.dart';
import '../../services/sustainability_service.dart';
import '../../core/api_client.dart';

/// Sustainability Dashboard Screen
class SustainabilityDashboardScreen extends StatefulWidget {
  const SustainabilityDashboardScreen({super.key});

  @override
  State<SustainabilityDashboardScreen> createState() => _SustainabilityDashboardScreenState();
}

class _SustainabilityDashboardScreenState extends State<SustainabilityDashboardScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SustainabilityService _sustainabilityService = SustainabilityService(ApiClient());
  
  SustainabilityMetrics? _metrics;
  List<WasteRecord> _wasteRecords = [];
  List<SustainabilityInitiative> _initiatives = [];
  List<GreenSupplierRating> _supplierRatings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final metrics = await _sustainabilityService.getMetrics(storeId: 1);
      final wasteRecords = await _sustainabilityService.getWasteRecords(storeId: 1);
      final initiatives = await _sustainabilityService.getInitiatives(storeId: 1);
      final supplierRatings = await _sustainabilityService.getGreenSupplierRatings();
      
      setState(() {
        _metrics = metrics;
        _wasteRecords = wasteRecords;
        _initiatives = initiatives;
        _supplierRatings = supplierRatings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sustainability data: $e')),
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
        title: const Text('Sustainability Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.eco)),
            Tab(text: 'Waste Tracking', icon: Icon(Icons.delete_outline)),
            Tab(text: 'Initiatives', icon: Icon(Icons.campaign)),
            Tab(text: 'Green Suppliers', icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildWasteTrackingTab(),
                _buildInitiativesTab(),
                _buildGreenSuppliersTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWasteRecord,
        icon: const Icon(Icons.add),
        label: const Text('Log Waste'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_metrics == null) {
      return const Center(child: Text('No sustainability data available'));
    }

    final metrics = _metrics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sustainability Score Card
          Card(
            color: _getScoreColor(metrics.sustainabilityScore),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Sustainability Score',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    metrics.sustainabilityScore.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'out of 100',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Key Metrics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildMetricCard(
                'Waste Diversion',
                '${metrics.wasteDiversionRate.toStringAsFixed(1)}%',
                Icons.recycling,
                Colors.green,
              ),
              _buildMetricCard(
                'Renewable Energy',
                '${metrics.renewableEnergyPercentage.toStringAsFixed(1)}%',
                Icons.wb_sunny,
                Colors.orange,
              ),
              _buildMetricCard(
                'Local Products',
                '${metrics.localProductsPercentage.toStringAsFixed(1)}%',
                Icons.local_shipping,
                Colors.blue,
              ),
              _buildMetricCard(
                'Carbon Footprint',
                '${(metrics.totalCarbonFootprint / 1000).toStringAsFixed(1)}t',
                Icons.cloud,
                Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Waste Breakdown Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waste Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: metrics.foodWaste,
                            title: 'Food',
                            color: Colors.orange,
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: metrics.packagingWaste,
                            title: 'Packaging',
                            color: Colors.brown,
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: metrics.recycledWaste,
                            title: 'Recycled',
                            color: Colors.green,
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: metrics.compostedWaste,
                            title: 'Composted',
                            color: Colors.lightGreen,
                            radius: 60,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Savings Card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.savings, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Cost Savings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Waste Reduction'),
                          Text(
                            '\$${metrics.wasteReductionSavings.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Energy Savings'),
                          Text(
                            '\$${metrics.energySavings.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Total Savings: '),
                      Text(
                        '\$${metrics.totalSavings.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteTrackingTab() {
    if (_wasteRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No waste records yet'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addWasteRecord,
              icon: const Icon(Icons.add),
              label: const Text('Log Waste'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _wasteRecords.length,
      itemBuilder: (context, index) {
        final record = _wasteRecords[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getWasteTypeColor(record.wasteType),
              child: Icon(
                _getWasteTypeIcon(record.wasteType),
                color: Colors.white,
              ),
            ),
            title: Text(record.wasteTypeDisplay),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${record.quantity.toStringAsFixed(1)} kg - ${record.disposalMethodDisplay}'),
                Text('Value lost: \$${record.monetaryValue.toStringAsFixed(2)}'),
                if (record.preventable)
                  const Text('⚠️ Preventable', style: TextStyle(color: Colors.orange)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(record.recordedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${record.carbonImpact.toStringAsFixed(1)} kg CO₂',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildInitiativesTab() {
    if (_initiatives.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No sustainability initiatives'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createInitiative,
              icon: const Icon(Icons.add),
              label: const Text('Create Initiative'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _initiatives.length,
      itemBuilder: (context, index) {
        final initiative = _initiatives[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Icon(
              _getInitiativeIcon(initiative.category),
              color: _getInitiativeColor(initiative.status),
            ),
            title: Text(initiative.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(initiative.categoryDisplay),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: initiative.progressPercentage / 100,
                  backgroundColor: Colors.grey.shade300,
                ),
                Text('${initiative.progressPercentage.toStringAsFixed(0)}% complete'),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(initiative.description),
                    const SizedBox(height: 12),
                    if (initiative.actualWasteReduction != null)
                      _buildProgressRow(
                        'Waste Reduced',
                        '${initiative.actualWasteReduction!.toStringAsFixed(0)} kg',
                        initiative.targetWasteReduction != null
                            ? '/ ${initiative.targetWasteReduction!.toStringAsFixed(0)} kg'
                            : '',
                      ),
                    if (initiative.actualCarbonReduction != null)
                      _buildProgressRow(
                        'Carbon Reduced',
                        '${initiative.actualCarbonReduction!.toStringAsFixed(0)} kg',
                        initiative.targetCarbonReduction != null
                            ? '/ ${initiative.targetCarbonReduction!.toStringAsFixed(0)} kg'
                            : '',
                      ),
                    if (initiative.roiPercentage != null)
                      _buildProgressRow(
                        'ROI',
                        '${initiative.roiPercentage!.toStringAsFixed(1)}%',
                        '',
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

  Widget _buildGreenSuppliersTab() {
    if (_supplierRatings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No supplier ratings available'),
          ],
        ),
      );
    }

    // Sort by rating
    _supplierRatings.sort((a, b) => b.overallRating.compareTo(a.overallRating));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _supplierRatings.length,
      itemBuilder: (context, index) {
        final rating = _supplierRatings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getRatingColor(rating.ratingCategory),
              child: Text(
                rating.ratingCategory,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(rating.supplierName),
            subtitle: Row(
              children: [
                ...List.generate(5, (i) {
                  return Icon(
                    i < (rating.overallRating / 20).round()
                        ? Icons.star
                        : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
                const SizedBox(width: 8),
                Text('${rating.overallRating.toStringAsFixed(1)}/100'),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRatingBar('Carbon Footprint', rating.carbonFootprintScore),
                    _buildRatingBar('Renewable Energy', rating.renewableEnergyScore),
                    _buildRatingBar('Waste Management', rating.wasteManagementScore),
                    _buildRatingBar('Sustainable Packaging', rating.sustainablePackagingScore),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (rating.iso14001Certified)
                          const Chip(
                            label: Text('ISO 14001'),
                            avatar: Icon(Icons.verified, size: 16),
                          ),
                        if (rating.carbonNeutralCertified)
                          const Chip(
                            label: Text('Carbon Neutral'),
                            avatar: Icon(Icons.eco, size: 16),
                          ),
                        if (rating.organicCertified)
                          const Chip(
                            label: Text('Organic'),
                            avatar: Icon(Icons.verified_outlined, size: 16),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, String target) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('$value $target'),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(_getScoreColor(score)),
            ),
          ),
          const SizedBox(width: 8),
          Text(score.toStringAsFixed(0), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lime;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getRatingColor(String category) {
    switch (category) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Color _getWasteTypeColor(String type) {
    switch (type) {
      case 'food':
        return Colors.orange;
      case 'packaging':
        return Colors.brown;
      case 'plastic':
        return Colors.blue;
      case 'paper':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getWasteTypeIcon(String type) {
    switch (type) {
      case 'food':
        return Icons.restaurant;
      case 'packaging':
        return Icons.inventory_2;
      case 'plastic':
        return Icons.water_drop;
      case 'paper':
        return Icons.description;
      default:
        return Icons.delete;
    }
  }

  IconData _getInitiativeIcon(String category) {
    switch (category) {
      case 'waste_reduction':
        return Icons.delete_outline;
      case 'energy_efficiency':
        return Icons.bolt;
      case 'water_conservation':
        return Icons.water;
      case 'sustainable_sourcing':
        return Icons.agriculture;
      default:
        return Icons.campaign;
    }
  }

  Color _getInitiativeColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'planned':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _addWasteRecord() {
    // Show dialog to add waste record
    showDialog(
      context: context,
      builder: (context) => const AddWasteRecordDialog(),
    );
  }

  void _createInitiative() {
    // Show dialog to create initiative
    showDialog(
      context: context,
      builder: (context) => const CreateInitiativeDialog(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class AddWasteRecordDialog extends StatelessWidget {
  const AddWasteRecordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Waste'),
      content: const Text('Waste record form'),
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

class CreateInitiativeDialog extends StatelessWidget {
  const CreateInitiativeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Initiative'),
      content: const Text('Initiative form'),
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
