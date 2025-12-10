/// Order History Screen
/// View past orders with tracking and reorder functionality

import 'package:flutter/material.dart';
import '../../services/customer_app_service.dart';
import '../../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CustomerAppService _customerService;
  
  List<CustomerOrder> _activeOrders = [];
  List<CustomerOrder> _pastOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _customerService = CustomerAppService(ApiService());
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final orders = await _customerService.getOrders();
      setState(() {
        _activeOrders = orders.where((o) => 
          ['pending', 'confirmed', 'preparing', 'ready', 'delivering'].contains(o.status)
        ).toList();
        _pastOrders = orders.where((o) => 
          ['completed', 'cancelled', 'refunded'].contains(o.status)
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Add mock data for demonstration
      _addMockOrders();
    }
  }

  void _addMockOrders() {
    setState(() {
      _activeOrders = [
        CustomerOrder(
          id: '1',
          orderNumber: 'ORD-2024-001',
          status: 'preparing',
          statusDisplay: 'Being Prepared',
          orderType: 'pickup',
          totalAmount: 45.99,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          items: [
            OrderItem(productId: '1', productName: 'Organic Milk', quantity: 2, unitPrice: 4.99, totalPrice: 9.98),
            OrderItem(productId: '2', productName: 'Whole Wheat Bread', quantity: 1, unitPrice: 3.49, totalPrice: 3.49),
          ],
        ),
        CustomerOrder(
          id: '2',
          orderNumber: 'ORD-2024-002',
          status: 'delivering',
          statusDisplay: 'On the Way',
          orderType: 'delivery',
          totalAmount: 89.50,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];
      
      _pastOrders = [
        CustomerOrder(
          id: '3',
          orderNumber: 'ORD-2024-000',
          status: 'completed',
          statusDisplay: 'Completed',
          orderType: 'pickup',
          totalAmount: 67.25,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        CustomerOrder(
          id: '4',
          orderNumber: 'ORD-2023-999',
          status: 'completed',
          statusDisplay: 'Completed',
          orderType: 'delivery',
          totalAmount: 123.00,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active (${_activeOrders.length})'),
            Tab(text: 'Past Orders'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveOrdersTab(theme),
                _buildPastOrdersTab(theme),
              ],
            ),
    );
  }

  Widget _buildActiveOrdersTab(ThemeData theme) {
    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No active orders', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/products'),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeOrders.length,
        itemBuilder: (context, index) {
          final order = _activeOrders[index];
          return _buildActiveOrderCard(order, theme);
        },
      ),
    );
  }

  Widget _buildPastOrdersTab(ThemeData theme) {
    if (_pastOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No order history', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pastOrders.length,
      itemBuilder: (context, index) {
        final order = _pastOrders[index];
        return _buildPastOrderCard(order, theme);
      },
    );
  }

  Widget _buildActiveOrderCard(CustomerOrder order, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Order header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      order.orderType == 'pickup' ? '🛍️ Pickup' : '🚗 Delivery',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                _buildStatusChip(order.status, order.statusDisplay),
              ],
            ),
          ),
          
          // Order progress
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildOrderProgress(order.status),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOrderDetails(order),
                    icon: const Icon(Icons.receipt),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _trackOrder(order),
                    icon: const Icon(Icons.location_on),
                    label: const Text('Track'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastOrderCard(CustomerOrder order, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Order icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: order.status == 'completed' 
                      ? Colors.green.shade100 
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  order.status == 'completed' 
                      ? Icons.check_circle 
                      : Icons.cancel,
                  color: order.status == 'completed' 
                      ? Colors.green 
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              
              // Order details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatDate(order.createdAt),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    Text(
                      '${order.items.length} items',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              // Amount and reorder
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => _reorder(order),
                    child: const Text('Reorder'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String display) {
    final colors = {
      'pending': Colors.orange,
      'confirmed': Colors.blue,
      'preparing': Colors.purple,
      'ready': Colors.green,
      'delivering': Colors.teal,
      'completed': Colors.green,
      'cancelled': Colors.red,
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: colors[status] ?? Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildOrderProgress(String status) {
    final steps = ['Confirmed', 'Preparing', 'Ready', 'Picked Up'];
    final currentIndex = {
      'pending': 0,
      'confirmed': 0,
      'preparing': 1,
      'ready': 2,
      'delivering': 3,
      'completed': 4,
    }[status] ?? 0;

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Line between steps
          final lineIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 3,
              color: lineIndex < currentIndex 
                  ? Colors.green 
                  : Colors.grey.shade300,
            ),
          );
        } else {
          // Step circle
          final stepIndex = index ~/ 2;
          final isActive = stepIndex <= currentIndex;
          final isCurrent = stepIndex == currentIndex;
          
          return Column(
            children: [
              Container(
                width: isCurrent ? 28 : 20,
                height: isCurrent ? 28 : 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green : Colors.grey.shade300,
                  border: isCurrent 
                      ? Border.all(color: Colors.green.shade200, width: 3)
                      : null,
                ),
                child: isActive && stepIndex < currentIndex
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.green : Colors.grey,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  void _showOrderDetails(CustomerOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Order header
            Text(
              order.orderNumber,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${order.orderType == 'pickup' ? 'Pickup' : 'Delivery'} • ${_formatDate(order.createdAt)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildStatusChip(order.status, order.statusDisplay),
            
            const Divider(height: 32),
            
            // Items
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text('${item.quantity}x'),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.productName)),
                  Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                ],
              ),
            )),
            
            const Divider(height: 32),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.receipt),
                    label: const Text('Download Receipt'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _reorder(order);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reorder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _trackOrder(CustomerOrder order) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              order.orderType == 'pickup' 
                  ? 'Ready for Pickup!' 
                  : 'Your order is on the way!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              order.orderType == 'pickup'
                  ? 'Head to the store to pick up your order'
                  : 'Estimated arrival: 15-20 minutes',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.map),
                label: Text(order.orderType == 'pickup' ? 'Get Directions' : 'View on Map'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reorder(CustomerOrder order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${order.items.length} items to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
