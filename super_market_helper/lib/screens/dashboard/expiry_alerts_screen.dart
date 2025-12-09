import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/product_card.dart';
import '../products/edit_product_screen.dart';

/// Expiry alerts screen
/// Displays products that are expired or expiring soon
class ExpiryAlertsScreen extends StatefulWidget {
  const ExpiryAlertsScreen({super.key});

  @override
  State<ExpiryAlertsScreen> createState() => _ExpiryAlertsScreenState();
}

class _ExpiryAlertsScreenState extends State<ExpiryAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Critical'),
              Tab(text: 'Warning'),
              Tab(text: 'Expired'),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductList(ExpiryStatus.danger),
              _buildProductList(ExpiryStatus.warning),
              _buildProductList(ExpiryStatus.expired),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(ExpiryStatus status) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = provider.getProductsByExpiryStatus(status);

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(status),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: ListView(
            padding: const EdgeInsets.only(top: 8),
            children: [
              // Alert Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(status).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getAlertTitle(status),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${products.length} ${products.length == 1 ? 'product' : 'products'} ${_getAlertMessage(status)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Product List
              ...products.map((product) {
                return ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProductScreen(product: product),
                      ),
                    );
                  },
                  onEdit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProductScreen(product: product),
                      ),
                    );
                  },
                  onDelete: () => _deleteProduct(product.id, product.name),
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  void _deleteProduct(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final success =
                  await context.read<ProductProvider>().deleteProduct(productId);
              if (!mounted) return;

              navigator.pop();

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Product deleted successfully'
                        : 'Failed to delete product',
                  ),
                  backgroundColor:
                      success ? AppTheme.successColor : AppTheme.dangerColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.danger:
        return Icons.error;
      case ExpiryStatus.warning:
        return Icons.warning_amber;
      case ExpiryStatus.expired:
        return Icons.cancel;
      default:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.danger:
      case ExpiryStatus.expired:
        return AppTheme.dangerColor;
      case ExpiryStatus.warning:
        return AppTheme.warningColor;
      default:
        return AppTheme.successColor;
    }
  }

  String _getEmptyMessage(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.danger:
        return 'No products in critical status';
      case ExpiryStatus.warning:
        return 'No products expiring soon';
      case ExpiryStatus.expired:
        return 'No expired products';
      default:
        return 'No products found';
    }
  }

  String _getAlertTitle(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.danger:
        return 'Critical Alert';
      case ExpiryStatus.warning:
        return 'Warning';
      case ExpiryStatus.expired:
        return 'Expired Products';
      default:
        return 'Alert';
    }
  }

  String _getAlertMessage(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.danger:
        return 'expiring within 3 days';
      case ExpiryStatus.warning:
        return 'expiring within 7 days';
      case ExpiryStatus.expired:
        return 'past expiry date';
      default:
        return 'found';
    }
  }
}
