import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/store_models.dart';
import '../services/api_service.dart';

class MultiStoreManagementScreen extends StatefulWidget {
  const MultiStoreManagementScreen({super.key});

  @override
  State<MultiStoreManagementScreen> createState() => _MultiStoreManagementScreenState();
}

class _MultiStoreManagementScreenState extends State<MultiStoreManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Data
  List<Store> stores = <Store>[];
  List<StoreInventory> inventories = <StoreInventory>[];
  List<InterStoreTransfer> transfers = <InterStoreTransfer>[];
  List<StorePerformanceMetrics> performance = <StorePerformanceMetrics>[];
  
  // UI State
  bool isLoading = true;
  String? selectedStoreId;
  String? selectedComparisonStores;
  
  // Controllers
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    
    try {
      await Future.wait([
        _loadStores(),
        _loadTransfers(),
        _loadPerformanceMetrics(),
      ]);
      
      if (stores.isNotEmpty) {
        selectedStoreId = stores.first.id;
        await _loadStoreInventories(selectedStoreId!);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadStores() async {
    try {
      final response = await ApiService().getStores();
      setState(() {
        stores = response;
      });
    } catch (e) {
      throw Exception('Failed to load stores: $e');
    }
  }

  Future<void> _loadStoreInventories(String storeId) async {
    try {
      final response = await ApiService().getStoreInventories(storeId: storeId);
      setState(() {
        inventories = response;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load inventories: $e');
    }
  }

  Future<void> _loadTransfers() async {
    try {
      final response = await ApiService().getInterStoreTransfers();
      setState(() {
        transfers = response;
      });
    } catch (e) {
      throw Exception('Failed to load transfers: $e');
    }
  }

  Future<void> _loadPerformanceMetrics() async {
    try {
      final response = await ApiService().getStorePerformanceMetrics();
      setState(() {
        performance = response;
      });
    } catch (e) {
      throw Exception('Failed to load performance metrics: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadInitialData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Store Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
            Tab(icon: Icon(Icons.transfer_within_a_station), text: 'Transfers'),
            Tab(icon: Icon(Icons.analytics), text: 'Performance'),
            Tab(icon: Icon(Icons.compare), text: 'Comparison'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildInventoryTab(),
                _buildTransfersTab(),
                _buildPerformanceTab(),
                _buildComparisonTab(),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreSelector(),
          const SizedBox(height: 16),
          _buildQuickStats(),
          const SizedBox(height: 16),
          _buildRecentActivity(),
          const SizedBox(height: 16),
          _buildAlerts(),
        ],
      ),
    );
  }

  Widget _buildStoreSelector() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Store',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedStoreId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: stores.map((store) {
                return DropdownMenuItem<String>(
                  value: store.id,
                  child: Row(
                    children: [
                      Icon(
                        _getStoreTypeIcon(store.storeType),
                        color: _getStoreStatusColor(store.status),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              store.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${store.code} • ${store.city}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedStoreId = value);
                  _loadStoreInventories(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final selectedStore = stores.firstWhere(
      (store) => store.id == selectedStoreId,
      orElse: () => stores.isNotEmpty ? stores.first : Store.empty(),
    );

    final storeInventories = inventories.where(
      (inv) => inv.storeId == selectedStoreId,
    ).toList();

    final totalProducts = storeInventories.length;
    final lowStockItems = storeInventories.where((inv) => inv.needsReorder).length;
    final outOfStockItems = storeInventories.where((inv) => inv.currentStock == 0).length;
    final totalValue = storeInventories.fold<double>(
      0,
      (sum, inv) => sum + (inv.currentStock * (inv.storeCostPrice ?? 0)),
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedStore.name} Quick Stats',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Products',
                    totalProducts.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Low Stock',
                    lowStockItems.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Out of Stock',
                    outOfStockItems.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Total Value',
                    '\$${totalValue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentTransfers = transfers.take(5).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transfer Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recentTransfers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No recent transfers'),
                ),
              )
            else
              ...recentTransfers.map((transfer) => _buildTransferTile(transfer)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferTile(InterStoreTransfer transfer) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getTransferStatusColor(transfer.status).withValues(alpha: 0.2),
        child: Icon(
          _getTransferStatusIcon(transfer.status),
          color: _getTransferStatusColor(transfer.status),
          size: 20,
        ),
      ),
      title: Text(
        '${transfer.fromStore?.name} → ${transfer.toStore?.name}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${transfer.product?.name} • ${transfer.requestedQuantity} units',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getTransferStatusColor(transfer.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              transfer.statusDisplay,
              style: TextStyle(
                fontSize: 10,
                color: _getTransferStatusColor(transfer.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(transfer.requestedDate),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts() {
    final alertInventories = inventories.where(
      (inv) => inv.needsReorder || inv.currentStock == 0,
    ).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Inventory Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (alertInventories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alertInventories.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (alertInventories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No inventory alerts'),
                ),
              )
            else
              ...alertInventories.take(3).map((inventory) => _buildAlertTile(inventory)),
            if (alertInventories.length > 3)
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: Text('View all ${alertInventories.length} alerts'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(StoreInventory inventory) {
    final isOutOfStock = inventory.currentStock == 0;
    
    return ListTile(
      leading: Icon(
        isOutOfStock ? Icons.error : Icons.warning,
        color: isOutOfStock ? Colors.red : Colors.orange,
      ),
      title: Text(
        inventory.product?.name ?? 'Unknown Product',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isOutOfStock
            ? 'Out of stock'
            : 'Low stock: ${inventory.currentStock} / ${inventory.reorderPoint}',
      ),
      trailing: ElevatedButton.icon(
        onPressed: () => _showCreateTransferDialog(inventory),
        icon: const Icon(Icons.transfer_within_a_station, size: 16),
        label: const Text('Transfer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(80, 32),
        ),
      ),
    );
  }

  Widget _buildInventoryTab() {
    final storeInventories = inventories.where(
      (inv) => inv.storeId == selectedStoreId,
    ).toList();

    return Column(
      children: [
        _buildInventoryHeader(),
        Expanded(
          child: storeInventories.isEmpty
              ? const Center(child: Text('No inventory data available'))
              : ListView.builder(
                  itemCount: storeInventories.length,
                  itemBuilder: (context, index) {
                    final inventory = storeInventories[index];
                    return _buildInventoryTile(inventory);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInventoryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              // Implement filter functionality
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Items')),
              const PopupMenuItem(value: 'low_stock', child: Text('Low Stock')),
              const PopupMenuItem(value: 'out_of_stock', child: Text('Out of Stock')),
              const PopupMenuItem(value: 'overstocked', child: Text('Overstocked')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTile(StoreInventory inventory) {
    final stockPercentage = inventory.stockPercentage;
    final stockColor = _getStockColor(stockPercentage);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stockColor.withValues(alpha: 0.2),
          child: Text(
            inventory.currentStock.toString(),
            style: TextStyle(
              color: stockColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          inventory.product?.name ?? 'Unknown Product',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${inventory.locationDisplay}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: stockPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(stockColor),
            ),
            const SizedBox(height: 2),
            Text(
              'Stock: ${inventory.currentStock} / ${inventory.maxStockLevel}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleInventoryAction(value, inventory),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Stock')),
            const PopupMenuItem(value: 'transfer', child: Text('Create Transfer')),
            const PopupMenuItem(value: 'details', child: Text('View Details')),
          ],
        ),
      ),
    );
  }

  Widget _buildTransfersTab() {
    return Column(
      children: [
        _buildTransferHeader(),
        Expanded(
          child: transfers.isEmpty
              ? const Center(child: Text('No transfers found'))
              : ListView.builder(
                  itemCount: transfers.length,
                  itemBuilder: (context, index) {
                    final transfer = transfers[index];
                    return _buildTransferCard(transfer);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTransferHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _showCreateTransferDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Transfer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              // Implement filter functionality
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Transfers')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'in_transit', child: Text('In Transit')),
              const PopupMenuItem(value: 'received', child: Text('Received')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(InterStoreTransfer transfer) {
    final statusColor = _getTransferStatusColor(transfer.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transfer.statusDisplay,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  transfer.transferNumber,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              transfer.product?.name ?? 'Unknown Product',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.store, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${transfer.fromStore?.name} → ${transfer.toStore?.name}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Quantity: ${transfer.requestedQuantity}'),
                if (transfer.approvedQuantity != null && 
                    transfer.approvedQuantity != transfer.requestedQuantity) ...[
                  Text(' (Approved: ${transfer.approvedQuantity})'),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Requested: ${_formatDate(transfer.requestedDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (transfer.isPendingApproval)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _handleTransferAction('approve', transfer),
                        child: const Text('Approve'),
                      ),
                      TextButton(
                        onPressed: () => _handleTransferAction('reject', transfer),
                        child: const Text('Reject'),
                      ),
                    ],
                  )
                else if (transfer.status == 'approved')
                  ElevatedButton.icon(
                    onPressed: () => _handleTransferAction('ship', transfer),
                    icon: const Icon(Icons.local_shipping, size: 16),
                    label: const Text('Ship'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                  )
                else if (transfer.status == 'in_transit')
                  ElevatedButton.icon(
                    onPressed: () => _handleTransferAction('receive', transfer),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Receive'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    if (performance.isEmpty) {
      return const Center(child: Text('No performance data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceChart(),
          const SizedBox(height: 16),
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final chartData = performance.take(30).toList().reversed.toList();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Trend (Last 30 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            final date = chartData[value.toInt()].date;
                            return Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.totalSales,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
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

  Widget _buildPerformanceMetrics() {
    final latestMetrics = performance.isNotEmpty ? performance.first : null;
    
    if (latestMetrics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No performance metrics available'),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildMetricCard(
                  'Total Sales',
                  '\$${latestMetrics.totalSales.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Transactions',
                  latestMetrics.totalTransactions.toString(),
                  Icons.receipt,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Avg Transaction',
                  '\$${latestMetrics.averageTransactionValue.toStringAsFixed(0)}',
                  Icons.shopping_cart,
                  Colors.purple,
                ),
                _buildMetricCard(
                  'Stock Health',
                  '${latestMetrics.stockHealthScore.toStringAsFixed(0)}%',
                  Icons.health_and_safety,
                  _getHealthScoreColor(latestMetrics.stockHealthScore),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreComparisonSelector(),
          const SizedBox(height: 16),
          _buildComparisonChart(),
          const SizedBox(height: 16),
          _buildComparisonTable(),
        ],
      ),
    );
  }

  Widget _buildStoreComparisonSelector() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Stores to Compare',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: stores.map((store) {
                final isSelected = selectedComparisonStores?.contains(store.id) ?? false;
                return FilterChip(
                  label: Text(store.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    // Implement store selection for comparison
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Implement comparison generation
              },
              icon: const Icon(Icons.compare),
              label: const Text('Generate Comparison'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    // Placeholder for comparison chart
    return const Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Store Performance Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: Text('Select stores to view comparison chart'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    // Placeholder for comparison table
    return const Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Center(
              child: Text('Select stores to view detailed comparison'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 1: // Inventory tab
        return FloatingActionButton(
          onPressed: () => _showBulkUpdateDialog(),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.edit, color: Colors.white),
        );
      case 2: // Transfers tab
        return FloatingActionButton(
          onPressed: () => _showCreateTransferDialog(),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
        );
      default:
        return null;
    }
  }

  // Helper methods
  IconData _getStoreTypeIcon(String storeType) {
    switch (storeType) {
      case 'main':
        return Icons.business;
      case 'branch':
        return Icons.store;
      case 'warehouse':
        return Icons.warehouse;
      case 'franchise':
        return Icons.storefront;
      default:
        return Icons.store;
    }
  }

  Color _getStoreStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'maintenance':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTransferStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'in_transit':
        return Colors.purple;
      case 'received':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransferStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'in_transit':
        return Icons.local_shipping;
      case 'received':
        return Icons.done_all;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStockColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.blue;
    if (percentage >= 25) return Colors.orange;
    return Colors.red;
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Dialog methods
  void _showCreateTransferDialog([StoreInventory? inventory]) {
    showDialog(
      context: context,
      builder: (context) => CreateTransferDialog(
        stores: stores,
        inventory: inventory,
        onTransferCreated: () {
          _loadTransfers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transfer request created successfully')),
          );
        },
      ),
    );
  }

  void _showBulkUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => BulkStockUpdateDialog(
        inventories: inventories.where((inv) => inv.storeId == selectedStoreId).toList(),
        onUpdatesCompleted: () {
          _loadStoreInventories(selectedStoreId!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock levels updated successfully')),
          );
        },
      ),
    );
  }

  // Action handlers
  void _handleInventoryAction(String action, StoreInventory inventory) {
    switch (action) {
      case 'edit':
        _showEditStockDialog(inventory);
        break;
      case 'transfer':
        _showCreateTransferDialog(inventory);
        break;
      case 'details':
        _showInventoryDetailsDialog(inventory);
        break;
    }
  }

  void _handleTransferAction(String action, InterStoreTransfer transfer) {
    switch (action) {
      case 'approve':
        _approveTransfer(transfer);
        break;
      case 'reject':
        _rejectTransfer(transfer);
        break;
      case 'ship':
        _shipTransfer(transfer);
        break;
      case 'receive':
        _receiveTransfer(transfer);
        break;
    }
  }

  void _showEditStockDialog(StoreInventory inventory) {
    // Implement edit stock dialog
  }

  void _showInventoryDetailsDialog(StoreInventory inventory) {
    // Implement inventory details dialog
  }

  Future<void> _approveTransfer(InterStoreTransfer transfer) async {
    // Implement transfer approval
  }

  Future<void> _rejectTransfer(InterStoreTransfer transfer) async {
    // Implement transfer rejection
  }

  Future<void> _shipTransfer(InterStoreTransfer transfer) async {
    // Implement transfer shipping
  }

  Future<void> _receiveTransfer(InterStoreTransfer transfer) async {
    // Implement transfer receiving
  }
}

// Placeholder dialog classes - implement these separately
class CreateTransferDialog extends StatelessWidget {
  final List<Store> stores;
  final StoreInventory? inventory;
  final VoidCallback onTransferCreated;

  const CreateTransferDialog({
    super.key,
    required this.stores,
    this.inventory,
    required this.onTransferCreated,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Transfer'),
      content: const Text('Transfer creation dialog - to be implemented'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onTransferCreated();
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class BulkStockUpdateDialog extends StatelessWidget {
  final List<StoreInventory> inventories;
  final VoidCallback onUpdatesCompleted;

  const BulkStockUpdateDialog({
    super.key,
    required this.inventories,
    required this.onUpdatesCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Stock Update'),
      content: const Text('Bulk update dialog - to be implemented'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onUpdatesCompleted();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}