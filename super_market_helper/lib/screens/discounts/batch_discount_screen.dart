/// Batch Discount Engine Screen
/// Manage automatic discounts for products nearing expiry
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/batch_discount_service.dart';

class BatchDiscountScreen extends StatefulWidget {
  const BatchDiscountScreen({super.key});

  @override
  State<BatchDiscountScreen> createState() => _BatchDiscountScreenState();
}

class _BatchDiscountScreenState extends State<BatchDiscountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BatchDiscountService _discountService = BatchDiscountService();
  
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _rules = [];
  List<Map<String, dynamic>> _activeDiscounts = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String? _error;

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
      // Load mock data for demo
      await Future.delayed(const Duration(milliseconds: 500));
      
      _dashboard = {
        'active_discounts': 12,
        'active_rules': 5,
        'eligible_products': 28,
        'monthly_savings': '2,450.00',
        'monthly_sales_from_discounts': '8,320.00',
        'units_saved_from_waste': 156,
        'eligible_products_list': [
          {'id': 1, 'name': 'Organic Milk 1L', 'expiry_date': '2025-12-17', 'days_until_expiry': 3, 'current_price': '4.99', 'quantity': 24},
          {'id': 2, 'name': 'Greek Yogurt', 'expiry_date': '2025-12-18', 'days_until_expiry': 4, 'current_price': '3.49', 'quantity': 36},
          {'id': 3, 'name': 'Fresh Bread', 'expiry_date': '2025-12-16', 'days_until_expiry': 2, 'current_price': '2.99', 'quantity': 18},
          {'id': 4, 'name': 'Mixed Salad Pack', 'expiry_date': '2025-12-15', 'days_until_expiry': 1, 'current_price': '5.99', 'quantity': 12},
          {'id': 5, 'name': 'Chicken Breast', 'expiry_date': '2025-12-17', 'days_until_expiry': 3, 'current_price': '8.99', 'quantity': 20},
        ],
      };
      
      _rules = [
        {'id': 1, 'name': '3 Days Before Expiry', 'days_before_expiry': 3, 'discount_type': 'percentage', 'discount_value': 20, 'status': 'active', 'priority': 1},
        {'id': 2, 'name': 'Last Day Sale', 'days_before_expiry': 1, 'discount_type': 'percentage', 'discount_value': 50, 'status': 'active', 'priority': 2},
        {'id': 3, 'name': 'Weekly Special', 'days_before_expiry': 7, 'discount_type': 'percentage', 'discount_value': 10, 'status': 'paused', 'priority': 3},
        {'id': 4, 'name': 'Dairy Products', 'days_before_expiry': 5, 'discount_type': 'percentage', 'discount_value': 25, 'status': 'active', 'priority': 1},
        {'id': 5, 'name': 'Bakery Items', 'days_before_expiry': 2, 'discount_type': 'percentage', 'discount_value': 40, 'status': 'active', 'priority': 2},
      ];
      
      _activeDiscounts = [
        {'id': 1, 'product_name': 'Organic Milk 1L', 'original_price': '4.99', 'discounted_price': '3.99', 'discount_percentage': 20, 'end_date': '2025-12-17', 'quantity_at_discount': 24, 'quantity_sold_at_discount': 8},
        {'id': 2, 'product_name': 'Greek Yogurt', 'original_price': '3.49', 'discounted_price': '2.62', 'discount_percentage': 25, 'end_date': '2025-12-18', 'quantity_at_discount': 36, 'quantity_sold_at_discount': 14},
        {'id': 3, 'product_name': 'Fresh Bread', 'original_price': '2.99', 'discounted_price': '1.79', 'discount_percentage': 40, 'end_date': '2025-12-16', 'quantity_at_discount': 18, 'quantity_sold_at_discount': 10},
        {'id': 4, 'product_name': 'Mixed Salad Pack', 'original_price': '5.99', 'discounted_price': '2.99', 'discount_percentage': 50, 'end_date': '2025-12-15', 'quantity_at_discount': 12, 'quantity_sold_at_discount': 7},
      ];
      
      _analytics = {
        'summary': {
          'total_discounts_applied': 156,
          'total_products_discounted': 89,
          'total_original_value': '15,420.00',
          'total_discounted_value': '12,336.00',
          'total_revenue_from_discounts': '8,320.00',
          'waste_prevented_value': '2,450.00',
          'waste_prevented_units': 156,
        },
        'analytics': [
          {'date': '2025-12-08', 'total_discounts_applied': 12, 'waste_prevented_value': '180.00'},
          {'date': '2025-12-09', 'total_discounts_applied': 18, 'waste_prevented_value': '245.00'},
          {'date': '2025-12-10', 'total_discounts_applied': 15, 'waste_prevented_value': '210.00'},
          {'date': '2025-12-11', 'total_discounts_applied': 22, 'waste_prevented_value': '320.00'},
          {'date': '2025-12-12', 'total_discounts_applied': 19, 'waste_prevented_value': '285.00'},
          {'date': '2025-12-13', 'total_discounts_applied': 25, 'waste_prevented_value': '380.00'},
          {'date': '2025-12-14', 'total_discounts_applied': 28, 'waste_prevented_value': '420.00'},
        ],
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
              colorScheme.secondary.withValues(alpha: 0.05),
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
                        _buildRulesTab(theme, colorScheme),
                        _buildActiveDiscountsTab(theme, colorScheme),
                        _buildAnalyticsTab(theme, colorScheme),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAutoApplyDialog,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Auto Apply'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
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
          'Batch Discount Engine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.8),
                colorScheme.secondaryContainer.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.discount_rounded,
              size: 64,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
          Tab(icon: Icon(Icons.rule_rounded), text: 'Rules'),
          Tab(icon: Icon(Icons.local_offer_rounded), text: 'Active'),
          Tab(icon: Icon(Icons.analytics_rounded), text: 'Analytics'),
        ],
        indicatorColor: colorScheme.primary,
        labelColor: colorScheme.primary,
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
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', style: Theme.of(context).textTheme.bodyMedium),
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
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Cards
          _buildStatsRow(colorScheme),
          const SizedBox(height: 24),
          
          // Eligible Products Section
          _buildSectionHeader('Products Eligible for Discount', Icons.inventory_2_rounded),
          const SizedBox(height: 12),
          _buildEligibleProductsList(theme, colorScheme),
          const SizedBox(height: 24),
          
          // Quick Actions
          _buildSectionHeader('Quick Actions', Icons.flash_on_rounded),
          const SizedBox(height: 12),
          _buildQuickActionsGrid(colorScheme),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ColorScheme colorScheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Active Discounts',
          '${_dashboard?['active_discounts'] ?? 0}',
          Icons.local_offer_rounded,
          colorScheme.primary,
          colorScheme,
        ),
        _buildStatCard(
          'Active Rules',
          '${_dashboard?['active_rules'] ?? 0}',
          Icons.rule_rounded,
          colorScheme.secondary,
          colorScheme,
        ),
        _buildStatCard(
          'Monthly Savings',
          '\$${_dashboard?['monthly_savings'] ?? '0'}',
          Icons.savings_rounded,
          Colors.green,
          colorScheme,
        ),
        _buildStatCard(
          'Units Saved',
          '${_dashboard?['units_saved_from_waste'] ?? 0}',
          Icons.recycling_rounded,
          Colors.teal,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '↑ 12%',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
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
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
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

  Widget _buildEligibleProductsList(ThemeData theme, ColorScheme colorScheme) {
    final products = _dashboard?['eligible_products_list'] as List? ?? [];
    
    return Container(
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
      child: Column(
        children: List.generate(products.length, (index) {
          final product = products[index] as Map<String, dynamic>;
          final daysUntilExpiry = product['days_until_expiry'] as int;
          
          Color urgencyColor;
          if (daysUntilExpiry <= 1) {
            urgencyColor = Colors.red;
          } else if (daysUntilExpiry <= 3) {
            urgencyColor = Colors.orange;
          } else {
            urgencyColor = Colors.yellow.shade700;
          }
          
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$daysUntilExpiry',
                      style: TextStyle(
                        color: urgencyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  product['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Row(
                  children: [
                    Text('${product['quantity']} units'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: urgencyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Expires: ${product['expiry_date']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: urgencyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${product['current_price']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showApplyDiscountDialog(product),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Apply', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              if (index < products.length - 1)
                Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildQuickActionsGrid(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Create Rule',
            Icons.add_circle_outline_rounded,
            colorScheme.primary,
            () => _showCreateRuleDialog(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'View Reports',
            Icons.assessment_rounded,
            colorScheme.secondary,
            () => _tabController.animateTo(3),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesTab(ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rules.length + 1,
      itemBuilder: (context, index) {
        if (index == _rules.length) {
          return const SizedBox(height: 100);
        }
        
        final rule = _rules[index];
        final isActive = rule['status'] == 'active';
        
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
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [colorScheme.primary, colorScheme.primaryContainer]
                      : [Colors.grey, Colors.grey.shade300],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${rule['discount_value']}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              rule['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${rule['days_before_expiry']} days before expiry',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Paused',
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(isActive ? Icons.pause : Icons.play_arrow),
                      const SizedBox(width: 8),
                      Text(isActive ? 'Pause' : 'Activate'),
                    ],
                  ),
                  onTap: () => _toggleRule(rule['id']),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.play_circle_filled),
                      SizedBox(width: 8),
                      Text('Apply Now'),
                    ],
                  ),
                  onTap: () => _applyRuleNow(rule['id']),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                  onTap: () => _showEditRuleDialog(rule),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red[400]),
                      const SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red[400])),
                    ],
                  ),
                  onTap: () => _deleteRule(rule['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveDiscountsTab(ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeDiscounts.length + 1,
      itemBuilder: (context, index) {
        if (index == _activeDiscounts.length) {
          return const SizedBox(height: 100);
        }
        
        final discount = _activeDiscounts[index];
        final soldPercentage = (discount['quantity_sold_at_discount'] / discount['quantity_at_discount'] * 100).toInt();
        
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
                        discount['product_name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.red.shade300],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-${discount['discount_percentage']?.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPriceTag(
                      '\$${discount['original_price']}',
                      colorScheme.onSurfaceVariant,
                      strikethrough: true,
                    ),
                    const SizedBox(width: 12),
                    _buildPriceTag(
                      '\$${discount['discounted_price']}',
                      Colors.green,
                      strikethrough: false,
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Until ${discount['end_date']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sold: ${discount['quantity_sold_at_discount']}/${discount['quantity_at_discount']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '$soldPercentage%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: soldPercentage / 100,
                        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                        minHeight: 8,
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

  Widget _buildPriceTag(String price, Color color, {required bool strikethrough}) {
    return Text(
      price,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 16,
        decoration: strikethrough ? TextDecoration.lineThrough : null,
      ),
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme, ColorScheme colorScheme) {
    final summary = _analytics?['summary'] as Map<String, dynamic>? ?? {};
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        _buildAnalyticsSummaryCards(summary, colorScheme),
        const SizedBox(height: 24),
        
        // Chart
        _buildSectionHeader('Waste Prevention Over Time', Icons.show_chart_rounded),
        const SizedBox(height: 12),
        _buildWastePreventionChart(colorScheme),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAnalyticsSummaryCards(Map<String, dynamic> summary, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsItem(
                  'Total Discounts',
                  '${summary['total_discounts_applied'] ?? 0}',
                  Icons.local_offer_rounded,
                ),
              ),
              Expanded(
                child: _buildAnalyticsItem(
                  'Products Discounted',
                  '${summary['total_products_discounted'] ?? 0}',
                  Icons.inventory_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsItem(
                  'Revenue from Discounts',
                  '\$${summary['total_revenue_from_discounts'] ?? '0'}',
                  Icons.attach_money_rounded,
                ),
              ),
              Expanded(
                child: _buildAnalyticsItem(
                  'Waste Prevented',
                  '\$${summary['waste_prevented_value'] ?? '0'}',
                  Icons.eco_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Icon(icon, size: 28, color: colorScheme.onPrimaryContainer),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWastePreventionChart(ColorScheme colorScheme) {
    final analyticsData = _analytics?['analytics'] as List? ?? [];
    
    return Container(
      height: 200,
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
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 500,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${rod.toY.toInt()}',
                  TextStyle(color: colorScheme.onPrimary),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
          barGroups: List.generate(7, (index) {
            final values = [180, 245, 210, 320, 285, 380, 420];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index].toDouble(),
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primaryContainer],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  void _showAutoApplyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 8),
            Text('Auto Apply Discounts'),
          ],
        ),
        content: const Text(
          'This will automatically apply all active discount rules to eligible products. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _autoApplyDiscounts();
            },
            child: const Text('Apply All'),
          ),
        ],
      ),
    );
  }

  void _showCreateRuleDialog() {
    final nameController = TextEditingController();
    final daysController = TextEditingController();
    final discountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Discount Rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Rule Name',
                  hintText: 'e.g., 3 Days Before Expiry',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Days Before Expiry',
                  hintText: 'e.g., 3',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Discount Percentage',
                  hintText: 'e.g., 20',
                  suffixText: '%',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _createRule({
                'name': nameController.text,
                'days_before_expiry': int.tryParse(daysController.text) ?? 3,
                'discount_type': 'percentage',
                'discount_value': double.tryParse(discountController.text) ?? 20,
                'status': 'active',
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditRuleDialog(Map<String, dynamic> rule) {
    // Similar to create dialog but pre-filled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit rule dialog')),
    );
  }

  void _showApplyDiscountDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply Discount to ${product['name']}'),
        content: const Text('Choose a discount amount to apply to this product.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Discount applied to ${product['name']}')),
              );
            },
            child: const Text('Apply 20% Off'),
          ),
        ],
      ),
    );
  }

  Future<void> _autoApplyDiscounts() async {
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
            Text('Applying discounts...'),
          ],
        ),
      ),
    );
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Applied 8 discounts to eligible products'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _toggleRule(int id) {
    setState(() {
      final index = _rules.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        final current = _rules[index]['status'];
        _rules[index]['status'] = current == 'active' ? 'paused' : 'active';
      }
    });
  }

  void _applyRuleNow(int id) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rule applied to 5 products')),
    );
  }

  void _deleteRule(int id) {
    setState(() {
      _rules.removeWhere((r) => r['id'] == id);
    });
  }

  void _createRule(Map<String, dynamic> rule) {
    setState(() {
      rule['id'] = _rules.length + 1;
      rule['priority'] = 1;
      _rules.insert(0, rule);
    });
  }
}
