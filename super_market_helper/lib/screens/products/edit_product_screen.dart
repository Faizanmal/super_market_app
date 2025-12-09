import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../utils/validators.dart';
import '../../utils/date_utils.dart' as app_date_utils;

/// Edit product screen
/// Form to edit existing product details
class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _supplierController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _barcodeController;
  late TextEditingController _descriptionController;

  late String _selectedCategory;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _supplierController = TextEditingController(text: widget.product.supplier);
    _costPriceController = TextEditingController(text: widget.product.costPrice.toString());
    _sellingPriceController = TextEditingController(text: widget.product.sellingPrice.toString());
    _barcodeController = TextEditingController(text: widget.product.barcode ?? '');
    _descriptionController = TextEditingController(text: widget.product.description ?? '');
    _selectedCategory = widget.product.category;
    _expiryDate = widget.product.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _supplierController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedProduct = widget.product.copyWith(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      quantity: int.parse(_quantityController.text),
      expiryDate: _expiryDate,
      supplier: _supplierController.text.trim(),
      costPrice: double.parse(_costPriceController.text),
      sellingPrice: double.parse(_sellingPriceController.text),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      updatedAt: DateTime.now(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    final success = await context.read<ProductProvider>().updateProduct(updatedProduct);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update product'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${widget.product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final success = await context.read<ProductProvider>().deleteProduct(widget.product.id);
              if (!mounted) return;

              navigator.pop(); // Close dialog
              
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                navigator.pop(); // Close edit screen
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete product'),
                    backgroundColor: AppTheme.dangerColor,
                  ),
                );
              }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteProduct,
            tooltip: 'Delete Product',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Product Information',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Created: ${app_date_utils.DateUtils.formatDisplayDateTime(widget.product.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Last Updated: ${app_date_utils.DateUtils.formatDisplayDateTime(widget.product.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'Enter product name',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: Validators.validateProductName,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.productCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                validator: Validators.validateCategory,
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  hintText: 'Enter quantity',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: Validators.validateQuantity,
              ),
              const SizedBox(height: 16),

              // Expiry Date
              InkWell(
                onTap: _selectExpiryDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    app_date_utils.DateUtils.formatDisplayDate(_expiryDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Supplier
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier *',
                  hintText: 'Enter supplier name',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: Validators.validateSupplier,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Cost Price
              TextFormField(
                controller: _costPriceController,
                decoration: const InputDecoration(
                  labelText: 'Cost Price *',
                  hintText: 'Enter cost price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => Validators.validatePrice(value, 'Cost price'),
              ),
              const SizedBox(height: 16),

              // Selling Price
              TextFormField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(
                  labelText: 'Selling Price *',
                  hintText: 'Enter selling price',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => Validators.validatePrice(value, 'Selling price'),
              ),
              const SizedBox(height: 16),

              // Barcode
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode (Optional)',
                  hintText: 'Enter barcode',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (value) => Validators.validateBarcode(value, isRequired: false),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter product description',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // Update Button
              ElevatedButton(
                onPressed: _updateProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Update Product'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
