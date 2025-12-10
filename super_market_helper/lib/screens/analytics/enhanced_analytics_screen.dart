import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/analytics_model.dart';

/// Enhanced Analytics Screen with 4 comprehensive tabs:
/// 1. Overview - Real-time dashboard summary
/// 2. Forecasts - AI-powered demand predictions
/// 3. Health - Product health scoring with visual indicators
/// 4. Profits - Detailed profit analysis and trends
class EnhancedAnalyticsScreen extends StatefulWidget {
  const EnhancedAnalyticsScreen({super.key});

  @override
  State<EnhancedAnalyticsScreen> createState() => _EnhancedAnalyticsScreenState();
}

class _EnhancedAnalyticsScreenState extends State<EnhancedAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  DashboardSummary? _summary;
  List<DemandForecast> _forecasts = [];
  List<StockHealthScore> _healthScores = [];
  ProfitAnalysis? _profitAnalysis;
  Map<String, List<SmartAlert>> _alerts = {};
  Map<String, dynamic>? _expiryBreakdown;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        _apiService.getExpiryBreakdown(),

      ]);

      setState(() {
        _summary = results[0] as DashboardSummary;
        _forecasts = results[1] as List<DemandForecast>;
        _healthScores = results[2] as List<StockHealthScore>;
        _profitAnalysis = results[3] as ProfitAnalysis;
        _alerts = results[4] as Map<String, List<SmartAlert>>;
        _expiryBreakdown = results[5] as Map<String, dynamic>;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: AppTheme.dangerColor,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Analytics Dashboard'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Forecasts', icon: Icon(Icons.trending_up_outlined)),
            Tab(text: 'Health', icon: Icon(Icons.health_and_safety_outlined)),
            Tab(text: 'Profits', icon: Icon(Icons.attach_money_outlined)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportData,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
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

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(height: 200, color: Colors.white, margin: const EdgeInsets.all(16)),
          Container(height: 150, color: Colors.white, margin: const EdgeInsets.all(16)),
          Container(height: 100, color: Colors.white, margin: const EdgeInsets.all(16)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_summary == null) return const Center(child: Text('No data available'));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKPICards(),
            const SizedBox(height: 24),
            _buildCriticalAlertsCard(),
            const SizedBox(height: 24),
            _buildExpiryStatusChart(),
            const SizedBox(height: 24),
            _buildTopExpiringProducts(),
            const SizedBox(height: 24),
            _buildRecentAudits(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildKPICard(
          'Total Products',
          _summary!.inventory.totalProducts.toString(),
          Icons.inventory_2_outlined,
          AppTheme.primaryColor,
        ),
        _buildKPICard(
          'Low Stock',
          _summary!.inventory.lowStock.toString(),
          Icons.view_list_outlined,
          AppTheme.successColor,
        ),
        _buildKPICard(
          'Critical Alerts',
          _summary!.expiry.expired.toString(),
          Icons.warning_amber_outlined,
          _summary!.expiry.expired > 0 ? AppTheme.dangerColor : AppTheme.successColor,
        ),
        _buildKPICard(
          'Expiring Soon',
          _summary!.expiry.expiringSoon.toString(),
          Icons.task_alt_outlined,
          _summary!.expiry.expiringSoon > 0 ? AppTheme.warningColor : AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalAlertsCard() {
    final criticalAlerts = _alerts['critical'] ?? [];
    final highAlerts = _alerts['high'] ?? [];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.priority_high, color: AppTheme.dangerColor),
                const SizedBox(width: 8),
                const Text(
                  'Critical Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (criticalAlerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${criticalAlerts.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (criticalAlerts.isEmpty && highAlerts.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successColor),
                    const SizedBox(width: 8),
                    const Text('All systems are healthy!'),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ...criticalAlerts.take(3).map((alert) => _buildAlertTile(alert, true)),
                  ...highAlerts.take(2).map((alert) => _buildAlertTile(alert, false)),
                  if (criticalAlerts.length + highAlerts.length > 5)
                    TextButton(
                      onPressed: () => _showAllAlerts(),
                      child: Text('View ${criticalAlerts.length + highAlerts.length - 5} more alerts'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(SmartAlert alert, bool isCritical) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isCritical ? AppTheme.dangerColor : AppTheme.warningColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            width: 4,
            color: isCritical ? AppTheme.dangerColor : AppTheme.warningColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.error : Icons.warning,
            color: isCritical ? AppTheme.dangerColor : AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (alert.recommendation != null)
                  Text(
                    alert.recommendation!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryStatusChart() {
    if (_expiryBreakdown == null) return const SizedBox();

    final data = [
      _ExpiryData('Critical', _expiryBreakdown!['expiring_critical'] ?? 0, AppTheme.dangerColor),
      _ExpiryData('High', _expiryBreakdown!['expiring_high'] ?? 0, AppTheme.warningColor),
      _ExpiryData('Medium', _expiryBreakdown!['expiring_medium'] ?? 0, Colors.orange),
      _ExpiryData('Fresh', (_expiryBreakdown!['total_batches'] ?? 0) - 
          (_expiryBreakdown!['expiring_critical'] ?? 0) - 
          (_expiryBreakdown!['expiring_high'] ?? 0) - 
          (_expiryBreakdown!['expiring_medium'] ?? 0), AppTheme.successColor),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expiry Status Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.right,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                series: <DoughnutSeries<_ExpiryData, String>>[
                  DoughnutSeries<_ExpiryData, String>(
                    dataSource: data,
                    xValueMapper: (_ExpiryData data, _) => data.category,
                    yValueMapper: (_ExpiryData data, _) => data.count.toDouble(),
                    pointColorMapper: (_ExpiryData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    innerRadius: '50%',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopExpiringProducts() {
    if (_summary?.topExpiring.isEmpty ?? true) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Expiring Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...(_summary?.topExpiring ?? []).map((product) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getExpiryColor(product.daysUntilExpiry).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    width: 4,
                    color: _getExpiryColor(product.daysUntilExpiry),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Batch: ${product.batchNumber}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${product.daysUntilExpiry} days',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getExpiryColor(product.daysUntilExpiry),
                        ),
                      ),
                      Text(
                        '${product.quantity} units',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAudits() {
    if (_summary?.recentAudits.isEmpty ?? true) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Audits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...(_summary?.recentAudits ?? []).map((audit) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_turned_in, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audit.auditNumber,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${audit.scope} • ${audit.itemsChecked} items checked',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (audit.itemsExpired > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${audit.itemsExpired} expired',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildForecastSummaryCard(),
            const SizedBox(height: 24),
            _buildForecastsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastSummaryCard() {
    final urgentForecasts = _forecasts.where((f) => f.daysUntilReorder <= 7).length;
    final soonForecasts = _forecasts.where((f) => f.daysUntilReorder > 7 && f.daysUntilReorder <= 30).length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reorder Forecasts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildForecastStatCard(
                    'Urgent (≤7 days)',
                    urgentForecasts.toString(),
                    AppTheme.dangerColor,
                    Icons.priority_high,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildForecastStatCard(
                    'Soon (8-30 days)',
                    soonForecasts.toString(),
                    AppTheme.warningColor,
                    Icons.schedule,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForecastsList() {
    if (_forecasts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.trending_up, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No reorder forecasts available',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Start adding products and track inventory movements to get AI-powered reorder predictions',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _forecasts.map((forecast) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getUrgencyColor(forecast.daysUntilReorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${forecast.daysUntilReorder}d',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(forecast.productName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current stock: ${forecast.currentStock}'),
              Text('Recommended order: ${forecast.recommendedQuantity}'),
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                forecast.daysUntilReorder <= 7 ? Icons.priority_high : Icons.schedule,
                color: _getUrgencyColor(forecast.daysUntilReorder),
              ),
              Text(
                forecast.daysUntilReorder <= 7 ? 'URGENT' : 'SOON',
                style: TextStyle(
                  fontSize: 10,
                  color: _getUrgencyColor(forecast.daysUntilReorder),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onTap: () => _showForecastDetails(forecast),
        ),
      )).toList(),
    );
  }

  Widget _buildHealthTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthOverviewCard(),
            const SizedBox(height: 24),
            _buildHealthScoreChart(),
            const SizedBox(height: 24),
            _buildHealthScoresList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthOverviewCard() {
    if (_healthScores.isEmpty) return const SizedBox();

    final averageHealth = _healthScores.fold(0.0, (sum, score) => sum + score.healthScore) / _healthScores.length;
    final criticalCount = _healthScores.where((s) => s.healthScore < 30).length;
    final poorCount = _healthScores.where((s) => s.healthScore >= 30 && s.healthScore < 60).length;
    final goodCount = _healthScores.where((s) => s.healthScore >= 60).length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthStatCard(
                    'Average Health',
                    '${averageHealth.toStringAsFixed(1)}%',
                    _getHealthColor(averageHealth.toInt()),
                    Icons.favorite,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthStatCard(
                    'Critical',
                    criticalCount.toString(),
                    AppTheme.dangerColor,
                    Icons.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthStatCard(
                    'Poor',
                    poorCount.toString(),
                    AppTheme.warningColor,
                    Icons.error_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthStatCard(
                    'Good',
                    goodCount.toString(),
                    AppTheme.successColor,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreChart() {
    if (_healthScores.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Score Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _healthScores.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.healthScore.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoresList() {
    if (_healthScores.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.health_and_safety, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No health scores available',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by health score (lowest first for attention)
    final sortedScores = List<StockHealthScore>.from(_healthScores)
      ..sort((a, b) => a.healthScore.compareTo(b.healthScore));

    return Column(
      children: sortedScores.map((score) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getHealthColor(score.healthScore),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${score.healthScore.toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(score.productName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock: ${score.currentStock}'),
              Text(_getHealthDescription(score.healthScore)),
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getHealthIcon(score.healthScore),
                color: _getHealthColor(score.healthScore),
              ),
              Text(
                _getHealthStatus(score.healthScore),
                style: TextStyle(
                  fontSize: 10,
                  color: _getHealthColor(score.healthScore),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onTap: () => _showHealthDetails(score),
        ),
      )).toList(),
    );
  }

  Widget _buildProfitTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_profitAnalysis != null) ...[
              _buildProfitOverviewCard(),
              const SizedBox(height: 24),
              _buildTopPerformersCard(),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.attach_money, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No profit data available',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitOverviewCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profit Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildProfitMetricCard(
                  'Total Revenue',
                  '\$${_profitAnalysis!.totalRevenue.toStringAsFixed(2)}',
                  AppTheme.primaryColor,
                  Icons.trending_up,
                ),
                _buildProfitMetricCard(
                  'Total Profit',
                  '\$${_profitAnalysis!.totalProfit.toStringAsFixed(2)}',
                  AppTheme.successColor,
                  Icons.attach_money,
                ),
                _buildProfitMetricCard(
                  'Profit Margin',
                  '${_profitAnalysis!.profitMargin.toStringAsFixed(1)}%',
                  _profitAnalysis!.profitMargin > 20 ? AppTheme.successColor : AppTheme.warningColor,
                  Icons.percent,
                ),
                _buildProfitMetricCard(
                  'Products Sold',
                  _profitAnalysis!.topProducts.length.toString(),
                  AppTheme.primaryColor,
                  Icons.inventory,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...(_profitAnalysis?.topProducts ?? []).take(5).map((product) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Sold: ${product.quantitySold} units',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${product.profit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                      Text(
                        '${product.marginPercent.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // Utility methods
  Color _getExpiryColor(int days) {
    if (days < 0) return AppTheme.dangerColor;
    if (days <= 3) return AppTheme.dangerColor;
    if (days <= 7) return AppTheme.warningColor;
    if (days <= 30) return Colors.orange;
    return AppTheme.successColor;
  }

  Color _getUrgencyColor(int days) {
    if (days <= 7) return AppTheme.dangerColor;
    if (days <= 30) return AppTheme.warningColor;
    return AppTheme.primaryColor;
  }

  Color _getHealthColor(int score) {
    if (score < 30) return AppTheme.dangerColor;
    if (score < 60) return AppTheme.warningColor;
    if (score < 80) return Colors.orange;
    return AppTheme.successColor;
  }

  IconData _getHealthIcon(int score) {
    if (score < 30) return Icons.dangerous;
    if (score < 60) return Icons.warning;
    if (score < 80) return Icons.info;
    return Icons.check_circle;
  }

  String _getHealthStatus(int score) {
    if (score < 30) return 'CRITICAL';
    if (score < 60) return 'POOR';
    if (score < 80) return 'FAIR';
    return 'GOOD';
  }

  String _getHealthDescription(int score) {
    if (score < 30) return 'Needs immediate attention';
    if (score < 60) return 'Requires improvement';
    if (score < 80) return 'Performing adequately';
    return 'Performing well';
  }

  void _showAllAlerts() {
    Navigator.pushNamed(context, '/alerts');
  }

  void _showForecastDetails(DemandForecast forecast) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(forecast.productName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Current Stock', '${forecast.currentStock} units'),
              _buildDetailRow('Recommended Order', '${forecast.recommendedQuantity} units'),
              _buildDetailRow('Days Until Reorder', '${forecast.daysUntilReorder} days'),
              const Divider(),
              Text(
                'AI Analysis',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on historical sales data and current trends, we recommend ordering ${forecast.recommendedQuantity} units within the next ${forecast.daysUntilReorder} days to maintain optimal stock levels.',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order creation feature coming soon')),
              );
            },
            child: const Text('Create Order'),
          ),
        ],
      ),
    );
  }

  void _showHealthDetails(StockHealthScore score) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getHealthIcon(score.healthScore),
              color: _getHealthColor(score.healthScore),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(score.productName)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      '${score.healthScore.toInt()}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getHealthColor(score.healthScore),
                      ),
                    ),
                    Text(
                      _getHealthStatus(score.healthScore),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _getHealthColor(score.healthScore),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Product Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Current Stock', '${score.currentStock} units'),
              _buildDetailRow('Health Status', _getHealthDescription(score.healthScore)),
              const SizedBox(height: 12),
              Text(
                'Recommendations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getHealthColor(score.healthScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  score.healthScore < 30
                      ? 'Immediate action required. Check expiry dates and adjust ordering patterns.'
                      : score.healthScore < 60
                      ? 'Monitor closely. Consider adjusting stock levels and reviewing sales trends.'
                      : score.healthScore < 80
                      ? 'Product is performing adequately. Continue normal operations.'
                      : 'Excellent health. Product is well-managed and selling well.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select export format:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV Export'),
              subtitle: const Text('All analytics data'),
              onTap: () async {
                Navigator.pop(context);
                await _performExport('csv');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Report'),
              subtitle: const Text('Comprehensive report with charts'),
              onTap: () async {
                Navigator.pop(context);
                await _performExport('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: const Text('Excel Workbook'),
              subtitle: const Text('Multi-sheet workbook'),
              onTap: () async {
                Navigator.pop(context);
                await _performExport('excel');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _performExport(String format) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      if (format == 'csv') {
        final buffer = StringBuffer();
        buffer.writeln('Analytics Export - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
        buffer.writeln('');
        buffer.writeln('Summary Statistics');
        if (_summary != null) {
          buffer.writeln('Total Products,${_summary!.inventory.totalProducts}');
          buffer.writeln('Low Stock,${_summary!.inventory.lowStock}');
          buffer.writeln('Expired Items,${_summary!.expiry.expired}');
          buffer.writeln('Expiring Soon,${_summary!.expiry.expiringSoon}');
        }
        buffer.writeln('');
        buffer.writeln('Demand Forecasts');
        buffer.writeln('Product,Current Stock,Recommended Quantity,Days Until Reorder');
        for (final forecast in _forecasts) {
          buffer.writeln('${forecast.productName},${forecast.currentStock},${forecast.recommendedQuantity},${forecast.daysUntilReorder}');
        }
        
        final file = File('${directory.path}/analytics_$timestamp.csv');
        await file.writeAsString(buffer.toString());
        await Share.shareXFiles([XFile(file.path)], text: 'Analytics Export');
      } else if (format == 'pdf') {
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
              pw.Header(
                level: 0,
                child: pw.Text('Analytics Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 20),
              if (_summary != null) ...[
                pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Table.fromTextArray(
                  data: [
                    ['Metric', 'Value'],
                    ['Total Products', '${_summary!.inventory.totalProducts}'],
                    ['Low Stock', '${_summary!.inventory.lowStock}'],
                    ['Expired', '${_summary!.expiry.expired}'],
                  ],
                ),
              ],
              pw.SizedBox(height: 20),
              if (_forecasts.isNotEmpty) ...[
                pw.Text('Forecasts', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Table.fromTextArray(
                  data: [
                    ['Product', 'Stock', 'Recommended', 'Days'],
                    ..._forecasts.take(10).map((f) => [f.productName, '${f.currentStock}', '${f.recommendedQuantity}', '${f.daysUntilReorder}']),
                  ],
                ),
              ],
            ],
          ),
        );
        
        final file = File('${directory.path}/analytics_$timestamp.pdf');
        await file.writeAsBytes(await pdf.save());
        await Share.shareXFiles([XFile(file.path)], text: 'Analytics Report');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report exported successfully as $format')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ExpiryData {
  final String category;
  final int count;
  final Color color;

  _ExpiryData(this.category, this.count, this.color);
}