import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/analytics_model.dart';

class SmartAnalyticsScreen extends StatefulWidget {
  const SmartAnalyticsScreen({super.key});

  @override
  State<SmartAnalyticsScreen> createState() => _SmartAnalyticsScreenState();
}

class _SmartAnalyticsScreenState extends State<SmartAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  DashboardSummary? _summary;
  List<DemandForecast>? _forecasts;
  List<StockHealthScore>? _healthScores;
  ProfitAnalysis? _profitAnalysis;
  Map<String, List<SmartAlert>>? _alerts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiService.getDashboardSummary(),
        _apiService.getDemandForecasts(),
        _apiService.getStockHealthScores(),
        _apiService.getProfitAnalysis(),
        _apiService.getSmartAlerts(),
      ]);

      setState(() {
        _summary = results[0] as DashboardSummary;
        _forecasts = results[1] as List<DemandForecast>;
        _healthScores = results[2] as List<StockHealthScore>;
        _profitAnalysis = results[3] as ProfitAnalysis;
        _alerts = results[4] as Map<String, List<SmartAlert>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Forecasts', icon: Icon(Icons.trending_up)),
            Tab(text: 'Health', icon: Icon(Icons.health_and_safety)),
            Tab(text: 'Profits', icon: Icon(Icons.attach_money)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildForecastsTab(),
                _buildHealthTab(),
                _buildProfitTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_summary == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(
            'Inventory Status',
            Icons.inventory,
            Colors.blue,
            [
              _buildStatRow('Total Products', _summary!.inventory.totalProducts),
              _buildStatRow('Low Stock', _summary!.inventory.lowStock,
                  color: Colors.orange),
              _buildStatRow('Out of Stock', _summary!.inventory.outOfStock,
                  color: Colors.red),
              _buildStatRow('Healthy Stock', _summary!.inventory.healthyStock,
                  color: Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Expiry Status',
            Icons.event,
            Colors.purple,
            [
              _buildStatRow('Expired', _summary!.expiry.expired,
                  color: Colors.red),
              _buildStatRow('Expiring Soon', _summary!.expiry.expiringSoon,
                  color: Colors.orange),
              _buildStatRow('Fresh', _summary!.expiry.fresh,
                  color: Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Valuation',
            Icons.account_balance_wallet,
            Colors.green,
            [
              _buildStatRow(
                'Total Cost',
                '\$${_summary!.valuation.totalCostValue.toStringAsFixed(2)}',
              ),
              _buildStatRow(
                'Total Selling',
                '\$${_summary!.valuation.totalSellingValue.toStringAsFixed(2)}',
              ),
              _buildStatRow(
                'Potential Profit',
                '\$${_summary!.valuation.potentialProfit.toStringAsFixed(2)}',
                color: Colors.green,
              ),
            ],
          ),
          if (_alerts != null) ...[
            const SizedBox(height: 16),
            _buildAlertsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildForecastsTab() {
    if (_forecasts == null || _forecasts!.isEmpty) {
      return const Center(
        child: Text('No forecasts available. Add more stock movements!'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _forecasts!.length,
      itemBuilder: (context, index) {
        final forecast = _forecasts![index];
        final isUrgent = forecast.daysUntilReorder <= 3;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isUrgent ? Colors.red.shade50 : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isUrgent ? Colors.red : Colors.orange,
              child: Text(
                '${forecast.daysUntilReorder}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              forecast.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current: ${forecast.currentStock} units'),
                Text(
                  'Reorder: ${forecast.recommendedQuantity} units',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
                Text(
                  'By: ${forecast.predictedReorderDate.toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Icon(
              isUrgent ? Icons.warning : Icons.schedule,
              color: isUrgent ? Colors.red : Colors.orange,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthTab() {
    if (_healthScores == null || _healthScores!.isEmpty) {
      return const Center(child: Text('No health data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _healthScores!.length,
      itemBuilder: (context, index) {
        final health = _healthScores![index];
        final color = _getHealthColor(health.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Text(
                '${health.healthScore}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              health.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Status: ${health.status.toUpperCase()}'),
            trailing: SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: health.healthScore / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfitTab() {
    if (_profitAnalysis == null) {
      return const Center(child: Text('No profit data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfitSummaryCard(),
        const SizedBox(height: 16),
        const Text(
          'Top Performing Products',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._profitAnalysis!.topProducts.map((product) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(product.productName),
                subtitle: Text('Sold: ${product.quantitySold} units'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${product.profit.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${product.revenue.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitSummaryCard() {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Profit Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Total Revenue',
              '\$${_profitAnalysis!.totalRevenue.toStringAsFixed(2)}',
            ),
            _buildStatRow(
              'Total Cost',
              '\$${_profitAnalysis!.totalCost.toStringAsFixed(2)}',
            ),
            _buildStatRow(
              'Net Profit',
              '\$${_profitAnalysis!.totalProfit.toStringAsFixed(2)}',
              color: Colors.green,
            ),
            _buildStatRow(
              'Profit Margin',
              '${_profitAnalysis!.profitMargin.toStringAsFixed(2)}%',
              color: Colors.blue,
            ),
            Text(
              'Last ${_profitAnalysis!.periodDays} days',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    final criticalCount = _alerts!['critical']!.length;
    final warningsCount = _alerts!['warnings']!.length;

    return Card(
      elevation: 4,
      child: ExpansionTile(
        leading: Icon(
          Icons.notifications_active,
          color: criticalCount > 0 ? Colors.red : Colors.orange,
        ),
        title: const Text(
          'Smart Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$criticalCount critical, $warningsCount warnings'),
        children: [
          if (criticalCount > 0) ...[
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Critical Alerts',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
            ..._alerts!['critical']!
                .map((alert) => _buildAlertTile(alert, Colors.red)),
          ],
          if (warningsCount > 0) ...[
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Warnings',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ),
            ..._alerts!['warnings']!
                .map((alert) => _buildAlertTile(alert, Colors.orange)),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertTile(SmartAlert alert, Color color) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.warning, color: color, size: 20),
      title: Text(alert.message, style: const TextStyle(fontSize: 14)),
      subtitle: alert.recommendedQuantity != null
          ? Text('Recommended: ${alert.recommendedQuantity} units')
          : null,
    );
  }

  Color _getHealthColor(String status) {
    switch (status) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'good':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
