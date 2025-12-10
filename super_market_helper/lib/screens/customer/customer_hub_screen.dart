/// Customer Hub Screen
/// Unified customer experience: Shopping Lists, Digital Receipts, and Warranties
library;

import 'package:flutter/material.dart';
import '../../services/customer_features_service.dart';

class CustomerHubScreen extends StatefulWidget {
  const CustomerHubScreen({super.key});

  @override
  State<CustomerHubScreen> createState() => _CustomerHubScreenState();
}

class _CustomerHubScreenState extends State<CustomerHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CustomerFeaturesService _customerService = CustomerFeaturesService();
  
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _shoppingLists = [];
  List<Map<String, dynamic>> _receipts = [];
  Map<String, dynamic>? _warrantyDashboard;
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
        'shopping_lists': {
          'active_lists': 3,
          'pending_items': 18,
        },
        'receipts': {
          'total_spent': '485.67',
          'total_saved': '52.30',
          'receipt_count': 12,
        },
        'warranties': {
          'active': 8,
          'expiring_soon': 2,
          'total': 12,
        },
      };
      
      _shoppingLists = [
        {
          'id': '1',
          'name': 'Weekly Groceries',
          'status': 'active',
          'items_count': 12,
          'completed_count': 5,
          'estimated_total': '85.50',
          'planned_date': '2025-12-15',
          'is_shared': true,
          'progress_percentage': 41.7,
        },
        {
          'id': '2',
          'name': 'Party Supplies',
          'status': 'active',
          'items_count': 8,
          'completed_count': 0,
          'estimated_total': '120.00',
          'planned_date': '2025-12-20',
          'is_shared': false,
          'progress_percentage': 0,
        },
        {
          'id': '3',
          'name': 'Baby Essentials',
          'status': 'active',
          'items_count': 6,
          'completed_count': 6,
          'estimated_total': '45.80',
          'planned_date': '2025-12-14',
          'is_shared': true,
          'progress_percentage': 100,
        },
      ];
      
      _receipts = [
        {
          'id': '1',
          'receipt_number': 'REC-20251214-A1B2C3',
          'transaction_date': '2025-12-14T10:30:00',
          'store_name': 'SuperMart Downtown',
          'total_amount': '67.45',
          'discount_amount': '8.50',
          'items_count': 8,
          'payment_method': 'card',
        },
        {
          'id': '2',
          'receipt_number': 'REC-20251213-D4E5F6',
          'transaction_date': '2025-12-13T18:15:00',
          'store_name': 'SuperMart Mall',
          'total_amount': '125.80',
          'discount_amount': '15.20',
          'items_count': 15,
          'payment_method': 'mobile',
        },
        {
          'id': '3',
          'receipt_number': 'REC-20251211-G7H8I9',
          'transaction_date': '2025-12-11T09:45:00',
          'store_name': 'SuperMart Express',
          'total_amount': '32.15',
          'discount_amount': '0.00',
          'items_count': 4,
          'payment_method': 'cash',
        },
      ];
      
      _warrantyDashboard = {
        'total_warranties': 12,
        'active_warranties': 8,
        'expiring_soon': 2,
        'expired': 2,
        'upcoming_expirations': [
          {
            'id': '1',
            'product_name': 'Samsung 55" Smart TV',
            'warranty_end_date': '2025-12-30',
            'days_remaining': 16,
            'status': 'expiring_soon',
          },
          {
            'id': '2',
            'product_name': 'Apple AirPods Pro',
            'warranty_end_date': '2026-01-15',
            'days_remaining': 32,
            'status': 'expiring_soon',
          },
        ],
        'all_warranties': [
          {
            'id': '1',
            'product_name': 'Samsung 55" Smart TV',
            'warranty_end_date': '2025-12-30',
            'days_remaining': 16,
            'status': 'expiring_soon',
            'purchase_date': '2024-12-30',
          },
          {
            'id': '2',
            'product_name': 'Apple AirPods Pro',
            'warranty_end_date': '2026-01-15',
            'days_remaining': 32,
            'status': 'expiring_soon',
            'purchase_date': '2025-01-15',
          },
          {
            'id': '3',
            'product_name': 'LG Washing Machine',
            'warranty_end_date': '2027-06-15',
            'days_remaining': 548,
            'status': 'active',
            'purchase_date': '2024-06-15',
          },
          {
            'id': '4',
            'product_name': 'Sony PlayStation 5',
            'warranty_end_date': '2026-08-20',
            'days_remaining': 249,
            'status': 'active',
            'purchase_date': '2025-08-20',
          },
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
              colorScheme.secondary.withValues(alpha: 0.05),
              colorScheme.primary.withValues(alpha: 0.05),
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
                        _buildShoppingListsTab(theme, colorScheme),
                        _buildReceiptsTab(theme, colorScheme),
                        _buildWarrantiesTab(theme, colorScheme),
                      ],
                    ),
        ),
      ),
      floatingActionButton: _buildFAB(colorScheme),
    );
  }

  Widget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    final shopping = _dashboard?['shopping_lists'] as Map<String, dynamic>? ?? {};
    final receipts = _dashboard?['receipts'] as Map<String, dynamic>? ?? {};
    final warranties = _dashboard?['warranties'] as Map<String, dynamic>? ?? {};
    
    return SliverAppBar(
      expandedHeight: 200,
      floating: true,
      pinned: true,
      backgroundColor: colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Customer Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.secondaryContainer.withValues(alpha: 0.9),
                colorScheme.tertiaryContainer.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickStat(
                    '${shopping['pending_items'] ?? 0}',
                    'Items to Buy',
                    Icons.shopping_cart_rounded,
                    colorScheme,
                  ),
                  _buildQuickStat(
                    '\$${receipts['total_saved'] ?? '0'}',
                    'Saved',
                    Icons.savings_rounded,
                    colorScheme,
                  ),
                  _buildQuickStat(
                    '${warranties['expiring_soon'] ?? 0}',
                    'Expiring',
                    Icons.warning_amber_rounded,
                    colorScheme,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: Badge(
              label: Text('${shopping['active_lists'] ?? 0}'),
              child: const Icon(Icons.list_alt_rounded),
            ),
            text: 'Lists',
          ),
          Tab(
            icon: Badge(
              label: Text('${receipts['receipt_count'] ?? 0}'),
              child: const Icon(Icons.receipt_long_rounded),
            ),
            text: 'Receipts',
          ),
          Tab(
            icon: Badge(
              label: Text('${warranties['active'] ?? 0}'),
              child: const Icon(Icons.verified_user_rounded),
            ),
            text: 'Warranties',
          ),
        ],
        indicatorColor: colorScheme.secondary,
        labelColor: colorScheme.secondary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.onSecondaryContainer),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(ColorScheme colorScheme) {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        onPressed: _showCreateListDialog,
        icon: const Icon(Icons.add),
        label: const Text('New List'),
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
      );
    }
    return const SizedBox.shrink();
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

  // ============================================================================
  // Shopping Lists Tab
  // ============================================================================

  Widget _buildShoppingListsTab(ThemeData theme, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _shoppingLists.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildShoppingListsHeader(colorScheme);
          }
          if (index == _shoppingLists.length + 1) {
            return const SizedBox(height: 100);
          }
          
          final list = _shoppingLists[index - 1];
          return _buildShoppingListCard(list, colorScheme);
        },
      ),
    );
  }

  Widget _buildShoppingListsHeader(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.share_rounded, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share lists with family',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                Text(
                  'Collaborate on shopping in real-time',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showJoinListDialog,
            child: const Text('Join List'),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingListCard(Map<String, dynamic> list, ColorScheme colorScheme) {
    final progress = (list['progress_percentage'] as num).toDouble();
    final isComplete = progress >= 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openShoppingList(list),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isComplete 
                          ? Colors.green.withValues(alpha: 0.1)
                          : colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isComplete ? Icons.check_circle_rounded : Icons.list_alt_rounded,
                      color: isComplete ? Colors.green : colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              list['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (list['is_shared'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people, size: 12, color: colorScheme.onTertiaryContainer),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Shared',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.onTertiaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${list['completed_count']}/${list['items_count']} items • \$${list['estimated_total']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        list['planned_date'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(
                    isComplete ? Colors.green : colorScheme.secondary,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Receipts Tab
  // ============================================================================

  Widget _buildReceiptsTab(ThemeData theme, ColorScheme colorScheme) {
    final receiptsData = _dashboard?['receipts'] as Map<String, dynamic>? ?? {};
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Spending Summary
          _buildSpendingSummary(receiptsData, colorScheme),
          const SizedBox(height: 20),
          
          // Receipts List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Receipts',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Receipts List
          ..._receipts.map((receipt) => _buildReceiptCard(receipt, colorScheme)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSpendingSummary(Map<String, dynamic> data, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Month',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${data['total_spent'] ?? '0'}',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Saved \$${data['total_saved'] ?? '0'}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildReceiptStat('${data['receipt_count'] ?? 0}', 'Receipts', Icons.receipt_rounded, colorScheme),
              _buildReceiptStat('\$${((double.tryParse(data['total_spent']?.replaceAll(',', '') ?? '0') ?? 0) / (data['receipt_count'] ?? 1)).toStringAsFixed(2)}', 'Average', Icons.calculate_rounded, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptStat(String value, String label, IconData icon, ColorScheme colorScheme) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> receipt, ColorScheme colorScheme) {
    IconData paymentIcon;
    switch (receipt['payment_method']) {
      case 'card':
        paymentIcon = Icons.credit_card_rounded;
        break;
      case 'mobile':
        paymentIcon = Icons.phone_android_rounded;
        break;
      default:
        paymentIcon = Icons.payments_rounded;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openReceipt(receipt),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt['store_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${receipt['items_count']} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(paymentIcon, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          receipt['payment_method'] ?? '',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${receipt['total_amount']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if ((double.tryParse(receipt['discount_amount']?.toString() ?? '0') ?? 0) > 0)
                    Text(
                      '-\$${receipt['discount_amount']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Warranties Tab
  // ============================================================================

  Widget _buildWarrantiesTab(ThemeData theme, ColorScheme colorScheme) {
    final warranties = _warrantyDashboard?['all_warranties'] as List? ?? [];
    final upcoming = _warrantyDashboard?['upcoming_expirations'] as List? ?? [];
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warranty Summary
          _buildWarrantySummary(colorScheme),
          const SizedBox(height: 20),
          
          // Expiring Soon
          if (upcoming.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Expiring Soon',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...upcoming.map((w) => _buildWarrantyCard(w as Map<String, dynamic>, colorScheme, isUrgent: true)),
            const SizedBox(height: 20),
          ],
          
          // All Warranties
          Text(
            'All Warranties',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...warranties.where((w) => (w as Map)['status'] != 'expiring_soon').map(
            (w) => _buildWarrantyCard(w as Map<String, dynamic>, colorScheme),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWarrantySummary(ColorScheme colorScheme) {
    final data = _warrantyDashboard ?? {};
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildWarrantyStat('${data['active_warranties'] ?? 0}', 'Active', Colors.green, colorScheme),
          Container(width: 1, height: 40, color: colorScheme.outline.withValues(alpha: 0.2)),
          _buildWarrantyStat('${data['expiring_soon'] ?? 0}', 'Expiring', Colors.orange, colorScheme),
          Container(width: 1, height: 40, color: colorScheme.outline.withValues(alpha: 0.2)),
          _buildWarrantyStat('${data['expired'] ?? 0}', 'Expired', Colors.grey, colorScheme),
        ],
      ),
    );
  }

  Widget _buildWarrantyStat(String value, String label, Color color, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWarrantyCard(Map<String, dynamic> warranty, ColorScheme colorScheme, {bool isUrgent = false}) {
    final daysRemaining = warranty['days_remaining'] as int? ?? 0;
    
    Color statusColor;
    if (daysRemaining <= 30) {
      statusColor = Colors.orange;
    } else if (daysRemaining <= 90) {
      statusColor = Colors.yellow.shade700;
    } else {
      statusColor = Colors.green;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isUrgent ? Border.all(color: Colors.orange.withValues(alpha: 0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openWarranty(warranty),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.verified_user_rounded, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warranty['product_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expires: ${warranty['warranty_end_date']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$daysRemaining days',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isUrgent) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => _setReminder(warranty['id']),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Set Reminder', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Actions
  // ============================================================================

  void _showCreateListDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Shopping List'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'List Name',
            hintText: 'e.g., Weekly Groceries',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _createShoppingList(nameController.text);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinListDialog() {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Shared List'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Share Code',
            hintText: 'Enter 8-character code',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _joinShoppingList(codeController.text);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _createShoppingList(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created list: $name')),
    );
    _loadData();
  }

  void _joinShoppingList(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joined list with code: $code')),
    );
    _loadData();
  }

  void _openShoppingList(Map<String, dynamic> list) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: ${list['name']}')),
    );
  }

  void _openReceipt(Map<String, dynamic> receipt) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening receipt: ${receipt['receipt_number']}')),
    );
  }

  void _openWarranty(Map<String, dynamic> warranty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildWarrantyDetailSheet(warranty),
    );
  }

  Widget _buildWarrantyDetailSheet(Map<String, dynamic> warranty) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              warranty['product_name'] ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Warranty Expires', warranty['warranty_end_date'] ?? '', Icons.calendar_today),
            _buildDetailRow('Days Remaining', '${warranty['days_remaining']} days', Icons.timer),
            _buildDetailRow('Purchase Date', warranty['purchase_date'] ?? '', Icons.shopping_bag),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setReminder(warranty['id']),
                    icon: const Icon(Icons.notifications),
                    label: const Text('Set Reminder'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _fileClaim(warranty['id']),
                    icon: const Icon(Icons.support_agent),
                    label: const Text('File Claim'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _setReminder(String id) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Reminder set for 30 days before expiry'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _fileClaim(String id) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening claim form...')),
    );
  }
}
