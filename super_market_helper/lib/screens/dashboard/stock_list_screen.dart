import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/product_card.dart';
import '../products/edit_product_screen.dart';

/// Stock list screen
/// Displays all products with search and filter capabilities
class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  ProductSortOption _sortOption = ProductSortOption.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...AppConstants.productCategories.map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ProductSortOption>(
              initialValue: _sortOption,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                  value: ProductSortOption.nameAsc,
                  child: Text('Name (A-Z)'),
                ),
                DropdownMenuItem(
                  value: ProductSortOption.nameDesc,
                  child: Text('Name (Z-A)'),
                ),
                DropdownMenuItem(
                  value: ProductSortOption.expiryDateAsc,
                  child: Text('Expiry (Earliest)'),
                ),
                DropdownMenuItem(
                  value: ProductSortOption.expiryDateDesc,
                  child: Text('Expiry (Latest)'),
                ),
                DropdownMenuItem(
                  value: ProductSortOption.quantityAsc,
                  child: Text('Quantity (Low-High)'),
                ),
                DropdownMenuItem(
                  value: ProductSortOption.quantityDesc,
                  child: Text('Quantity (High-Low)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortOption = value;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _sortOption = ProductSortOption.nameAsc;
              });
              context.read<ProductProvider>().clearFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProductProvider>().filterByCategory(_selectedCategory);
              context.read<ProductProvider>().sortProducts(_sortOption);
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
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
              final success = await context.read<ProductProvider>().deleteProduct(productId);
              if (!mounted) return;
              
              navigator.pop();
              
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Product deleted successfully' : 'Failed to delete product',
                  ),
                  backgroundColor: success ? AppTheme.successColor : AppTheme.dangerColor,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ProductProvider>().searchProducts('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    context.read<ProductProvider>().searchProducts(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: _showFilterDialog,
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter & Sort',
              ),
            ],
          ),
        ),

        // Product List
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.searchQuery.isNotEmpty || provider.selectedCategory != null
                            ? 'No products found'
                            : 'No products yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.searchQuery.isNotEmpty || provider.selectedCategory != null
                            ? 'Try adjusting your filters'
                            : 'Add your first product to get started',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.refresh(),
                child: ListView.builder(
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
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
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
