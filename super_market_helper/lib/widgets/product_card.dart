import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'expiry_badge.dart';

/// Product card widget
/// Displays product information in a card format
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Category
                        Text(
                          product.category,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Expiry Badge
                  ExpiryBadge(expiryStatus: product.expiryStatus),
                ],
              ),
              const SizedBox(height: 16),

              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      icon: Icons.inventory_2_outlined,
                      label: 'Quantity',
                      value: product.quantity.toString(),
                      valueColor: _getStockColor(product.stockStatus),
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      icon: Icons.calendar_today_outlined,
                      label: 'Expiry',
                      value: app_date_utils.DateUtils.formatDisplayDate(
                        product.expiryDate,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      icon: Icons.attach_money_outlined,
                      label: 'Price',
                      value: '\$${product.sellingPrice.toStringAsFixed(2)}',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      icon: Icons.business_outlined,
                      label: 'Supplier',
                      value: product.supplier,
                    ),
                  ),
                ],
              ),

              // Barcode (if available)
              if (product.barcode != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.qr_code,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.barcode!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),
              ],

              // Actions
              if (showActions) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    const SizedBox(width: 8),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.dangerColor,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build detail item widget
  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: valueColor,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get stock status color
  Color _getStockColor(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return AppTheme.successColor;
      case StockStatus.lowStock:
        return AppTheme.warningColor;
      case StockStatus.outOfStock:
        return AppTheme.dangerColor;
    }
  }
}
