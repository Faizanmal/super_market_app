import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../utils/validators.dart';
import '../../utils/date_utils.dart' as app_date_utils;

/// Add product screen
/// Form to add new products with barcode scanning capability
class AddProductScreen extends StatefulWidget {
  final bool enableScanner;

  const AddProductScreen({
    super.key,
    this.enableScanner = false,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _supplierController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = AppConstants.productCategories[0];
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableScanner) {
      _showScanner = true;
    }
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

  void _handleBarcodeDetection(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first.rawValue ?? '';
      setState(() {
        _barcodeController.text = barcode;
        _showScanner = false;
      });

      // Check if product exists with this barcode
      final existingProduct = context.read<ProductProvider>().getProductByBarcode(barcode);
      if (existingProduct != null) {
        // Pre-fill form with existing product data
        _showExistingProductDialog(existingProduct);
      }
    }
  }

  void _showExistingProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Found'),
        content: Text(
          'A product "${product.name}" already exists with this barcode. Do you want to use its details?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              _prefillForm(product);
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _prefillForm(Product product) {
    setState(() {
      _nameController.text = product.name;
      _selectedCategory = product.category;
      _supplierController.text = product.supplier;
      _costPriceController.text = product.costPrice.toString();
      _sellingPriceController.text = product.sellingPrice.toString();
      _descriptionController.text = product.description ?? '';
    });
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final newProduct = Product(
      id: const Uuid().v4(),
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    final success = await context.read<ProductProvider>().addProduct(newProduct);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add product'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        actions: [
          IconButton(
            icon: Icon(_showScanner ? Icons.close : Icons.qr_code_scanner),
            onPressed: () {
              setState(() {
                _showScanner = !_showScanner;
              });
            },
            tooltip: _showScanner ? 'Close Scanner' : 'Scan Barcode',
          ),
        ],
      ),
      body: _showScanner ? _buildScanner() : _buildForm(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: _handleBarcodeDetection,
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              decoration: InputDecoration(
                labelText: 'Barcode (Optional)',
                hintText: 'Enter or scan barcode',
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    setState(() {
                      _showScanner = true;
                    });
                  },
                ),
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

            // Save Button
            ElevatedButton(
              onPressed: _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add Product'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
