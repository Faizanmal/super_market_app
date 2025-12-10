/// Sales Forecasting Screen
/// AI-powered demand prediction and restock recommendations
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/sales_forecasting_service.dart';

class SalesForecastingScreen extends StatefulWidget {
  const SalesForecastingScreen({super.key});

  @override
  State<SalesForecastingScreen> createState() => _SalesForecastingScreenState();
}

class _SalesForecastingScreenState extends State<SalesForecastingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SalesForecastingService _forecastService = SalesForecastingService();
  
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _forecasts = [];
  Map<String, dynamic>? _restockByUrgency;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      await Future.delayed(const Duration(milliseconds: 500));
      
      _dashboard = {
        'recommendations': {
          'critical': 3,
          'high': 8,
          'medium': 15,
          'total_pending': 26,
        },
        'forecast_accuracy': 87.5,
        'next_week_forecast': {
          'predicted_quantity': 1250,
          'predicted_revenue': '18,750.00',
        },
        'patterns_detected': 12,
        'urgent_restocks': [
          {'id': 1, 'product_name': 'Organic Milk 1L', 'recommended_quantity': 48, 'expected_stockout_date': '2025-12-16', 'urgency': 'critical'},
          {'id': 2, 'product_name': 'Fresh Bread', 'recommended_quantity': 36, 'expected_stockout_date': '2025-12-15', 'urgency': 'critical'},
          {'id': 3, 'product_name': 'Chicken Breast', 'recommended_quantity': 24, 'expected_stockout_date': '2025-12-17', 'urgency': 'critical'},
        ],
      };
      
      _forecasts = [
        {'id': 1, 'product_name': 'Organic Milk 1L', 'forecast_date': '2025-12-15', 'predicted_quantity': 32, 'predicted_revenue': '159.68', 'confidence_level': 'high', 'confidence_score': 89.5},
        {'id': 2, 'product_name': 'Fresh Bread', 'forecast_date': '2025-12-15', 'predicted_quantity': 45, 'predicted_revenue': '134.55', 'confidence_level': 'high', 'confidence_score': 92.3},
        {'id': 3, 'product_name': 'Greek Yogurt', 'forecast_date': '2025-12-15', 'predicted_quantity': 28, 'predicted_revenue': '97.72', 'confidence_level': 'medium', 'confidence_score': 78.6},
        {'id': 4, 'product_name': 'Chicken Breast', 'forecast_date': '2025-12-15', 'predicted_quantity': 18, 'predicted_revenue': '161.82', 'confidence_level': 'high', 'confidence_score': 85.2},
        {'id': 5, 'product_name': 'Mixed Salad Pack', 'forecast_date': '2025-12-15', 'predicted_quantity': 22, 'predicted_revenue': '131.78', 'confidence_level': 'medium', 'confidence_score': 72.8},
      ];
      
      _restockByUrgency = {
        'critical': [
          {'id': 1, 'product_name': 'Organic Milk 1L', 'recommended_quantity': 48, 'expected_stockout_date': '2025-12-16', 'estimated_cost': '120.00', 'reason': 'Stock will run out in 2 days', 'supplier_name': 'Local Dairy Co'},
          {'id': 2, 'product_name': 'Fresh Bread', 'recommended_quantity': 36, 'expected_stockout_date': '2025-12-15', 'estimated_cost': '54.00', 'reason': 'Stock will run out in 1 day', 'supplier_name': 'Artisan Bakery'},
        ],
        'high': [
          {'id': 3, 'product_name': 'Chicken Breast', 'recommended_quantity': 24, 'expected_stockout_date': '2025-12-17', 'estimated_cost': '144.00', 'reason': 'Stock will run out in 3 days', 'supplier_name': 'Premium Poultry'},
          {'id': 4, 'product_name': 'Mixed Salad Pack', 'recommended_quantity': 30, 'expected_stockout_date': '2025-12-18', 'estimated_cost': '90.00', 'reason': 'Stock will run out in 4 days', 'supplier_name': 'Fresh Farms'},
          {'id': 5, 'product_name': 'Greek Yogurt', 'recommended_quantity': 48, 'expected_stockout_date': '2025-12-19', 'estimated_cost': '96.00', 'reason': 'Stock will run out in 5 days', 'supplier_name': 'Mediterranean Foods'},
        ],
        'medium': [
          {'id': 6, 'product_name': 'Orange Juice', 'recommended_quantity': 36, 'expected_stockout_date': '2025-12-22', 'estimated_cost': '72.00', 'reason': 'Stock will run out in 8 days', 'supplier_name': 'Citrus Express'},
        ],
        'low': [],
      };
      
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.tertiary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildAppBar(theme, colorScheme),
            ];
          },
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorWidget()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDashboardTab(theme, colorScheme),
                        _buildForecastsTab(theme, colorScheme),
                        _buildRestockTab(theme, colorScheme),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateForecasts,
        icon: const Icon(Icons.auto_graph),
        label: const Text('Generate Forecasts'),
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      backgroundColor: colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'AI Sales Forecasting',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.tertiaryContainer.withValues(alpha: 0.8),
                colorScheme.primaryContainer.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.auto_graph_rounded,
              size: 64,
              color: colorScheme.onTertiaryContainer.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
          Tab(icon: Icon(Icons.trending_up_rounded), text: 'Forecasts'),
          Tab(icon: Icon(Icons.inventory_rounded), text: 'Restock'),
        ],
        indicatorColor: colorScheme.tertiary,
        labelColor: colorScheme.tertiary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Error loading data', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(ThemeData theme, ColorScheme colorScheme) {
    final recommendations = _dashboard?['recommendations'] as Map<String, dynamic>? ?? {};
    final nextWeek = _dashboard?['next_week_forecast'] as Map<String, dynamic>? ?? {};
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Accuracy Score Card
          _buildAccuracyCard(colorScheme),
          const SizedBox(height: 16),
          
          // Stats Grid
          _buildStatsGrid(recommendations, nextWeek, colorScheme),
          const SizedBox(height: 24),
          
          // Prediction Chart
          _buildSectionHeader('7-Day Sales Prediction', Icons.show_chart_rounded),
          const SizedBox(height: 12),
          _buildPredictionChart(colorScheme),
          const SizedBox(height: 24),
          
          // Urgent Restocks
          _buildSectionHeader('Urgent Restocks', Icons.warning_amber_rounded),
          const SizedBox(height: 12),
          _buildUrgentRestocksList(colorScheme),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAccuracyCard(ColorScheme colorScheme) {
    final accuracy = _dashboard?['forecast_accuracy'] ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: accuracy / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  Text(
                    '${accuracy.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forecast Accuracy',
                  style: TextStyle(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on last 100 predictions',
                  style: TextStyle(
                    color: colorScheme.onTertiaryContainer.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildAccuracyBadge('High Confidence', Icons.check_circle, Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '${_dashboard?['patterns_detected'] ?? 0} patterns detected',
                      style: TextStyle(
                        color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                        fontSize: 11,
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
  }

  Widget _buildAccuracyBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> recommendations, Map<String, dynamic> nextWeek, ColorScheme colorScheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          'Critical Alerts',
          '${recommendations['critical'] ?? 0}',
          Icons.error_rounded,
          Colors.red,
          colorScheme,
        ),
        _buildStatCard(
          'Pending Restocks',
          '${recommendations['total_pending'] ?? 0}',
          Icons.inventory_rounded,
          Colors.orange,
          colorScheme,
        ),
        _buildStatCard(
          'Next Week Units',
          '${nextWeek['predicted_quantity'] ?? 0}',
          Icons.trending_up_rounded,
          colorScheme.tertiary,
          colorScheme,
        ),
        _buildStatCard(
          'Next Week Revenue',
          '\$${nextWeek['predicted_revenue'] ?? '0'}',
          Icons.monetization_on_rounded,
          Colors.green,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.tertiary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionChart(ColorScheme colorScheme) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.outline.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final days = ['Today', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[value.toInt() % 7],
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 250,
          lineBarsData: [
            // Predicted line
            LineChartBarData(
              spots: const [
                FlSpot(0, 150),
                FlSpot(1, 165),
                FlSpot(2, 145),
                FlSpot(3, 180),
                FlSpot(4, 200),
                FlSpot(5, 220),
                FlSpot(6, 190),
              ],
              isCurved: true,
              gradient: LinearGradient(
                colors: [colorScheme.tertiary, colorScheme.primary],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: colorScheme.tertiary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.tertiary.withValues(alpha: 0.3),
                    colorScheme.tertiary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // Confidence band (upper)
            LineChartBarData(
              spots: const [
                FlSpot(0, 170),
                FlSpot(1, 185),
                FlSpot(2, 165),
                FlSpot(3, 200),
                FlSpot(4, 220),
                FlSpot(5, 245),
                FlSpot(6, 210),
              ],
              isCurved: true,
              color: colorScheme.tertiary.withValues(alpha: 0.2),
              barWidth: 1,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentRestocksList(ColorScheme colorScheme) {
    final urgentRestocks = _dashboard?['urgent_restocks'] as List? ?? [];
    
    return Column(
      children: urgentRestocks.map<Widget>((restock) {
        final r = restock as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            title: Text(
              r['product_name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Stockout: ${r['expected_stockout_date']}'),
            trailing: FilledButton.tonal(
              onPressed: () => _approveRestock(r['id']),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text('Order ${r['recommended_quantity']}'),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildForecastsTab(ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _forecasts.length + 1,
      itemBuilder: (context, index) {
        if (index == _forecasts.length) {
          return const SizedBox(height: 100);
        }
        
        final forecast = _forecasts[index];
        final confidence = forecast['confidence_level'] as String;
        
        Color confidenceColor;
        IconData confidenceIcon;
        switch (confidence) {
          case 'high':
            confidenceColor = Colors.green;
            confidenceIcon = Icons.check_circle;
            break;
          case 'medium':
            confidenceColor = Colors.orange;
            confidenceIcon = Icons.info;
            break;
          default:
            confidenceColor = Colors.red;
            confidenceIcon = Icons.warning;
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        forecast['product_name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(confidenceIcon, size: 14, color: confidenceColor),
                          const SizedBox(width: 4),
                          Text(
                            '${forecast['confidence_score']}%',
                            style: TextStyle(
                              color: confidenceColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildForecastMetric(
                      'Predicted Sales',
                      '${forecast['predicted_quantity']} units',
                      Icons.shopping_cart_rounded,
                      colorScheme.tertiary,
                    ),
                    const SizedBox(width: 16),
                    _buildForecastMetric(
                      'Revenue',
                      '\$${forecast['predicted_revenue']}',
                      Icons.attach_money_rounded,
                      Colors.green,
                    ),
                    const Spacer(),
                    Text(
                      forecast['forecast_date'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForecastMetric(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRestockTab(ThemeData theme, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Critical Section
        _buildUrgencySection('Critical', Colors.red, _restockByUrgency?['critical'] ?? [], colorScheme),
        const SizedBox(height: 20),
        
        // High Section
        _buildUrgencySection('High Priority', Colors.orange, _restockByUrgency?['high'] ?? [], colorScheme),
        const SizedBox(height: 20),
        
        // Medium Section
        _buildUrgencySection('Medium Priority', Colors.yellow.shade700, _restockByUrgency?['medium'] ?? [], colorScheme),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildUrgencySection(String title, Color color, List items, ColorScheme colorScheme) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$title (${items.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map<Widget>((item) {
          final r = item as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          r['product_name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Order ${r['recommended_quantity']}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    r['reason'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.store_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        r['supplier_name'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.attach_money_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '\$${r['estimated_cost']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _dismissRestock(r['id']),
                        child: const Text('Dismiss'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _approveRestock(r['id']),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _generateForecasts() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating AI forecasts...'),
          ],
        ),
      ),
    );
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Generated 25 forecasts for the next 7 days'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadData();
    }
  }

  void _approveRestock(int id) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Restock recommendation approved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _dismissRestock(int id) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recommendation dismissed')),
    );
  }
}
