/// Self-Checkout Scanner Screen
/// Scan products and checkout independently

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';

class SelfCheckoutScreen extends StatefulWidget {
  const SelfCheckoutScreen({super.key});

  @override
  State<SelfCheckoutScreen> createState() => _SelfCheckoutScreenState();
}

class _SelfCheckoutScreenState extends State<SelfCheckoutScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final List<ScannedItem> _scannedItems = [];
  bool _isScanning = true;
  bool _showScanner = true;
  double _totalAmount = 0;
  String? _lastScannedBarcode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Checkout'),
        actions: [
          IconButton(
            icon: Icon(_showScanner ? Icons.list : Icons.qr_code_scanner),
            onPressed: () => setState(() => _showScanner = !_showScanner),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner area
          if (_showScanner)
            Container(
              height: 250,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onBarcodeDetected,
                  ),
                  // Scan frame overlay
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // Scanning indicator
                  if (_isScanning)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Scanning...', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // Cart summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart),
                    const SizedBox(width: 8),
                    Text(
                      '${_scannedItems.length} items',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Total: \$${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Scanned items list
          Expanded(
            child: _scannedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Scan items to add to cart',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _scannedItems.length,
                    itemBuilder: (context, index) {
                      final item = _scannedItems[index];
                      return _buildItemCard(item, index);
                    },
                  ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Manual entry
                  OutlinedButton.icon(
                    onPressed: _showManualEntry,
                    icon: const Icon(Icons.edit),
                    label: const Text('Enter Barcode Manually'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Checkout button
                  ElevatedButton.icon(
                    onPressed: _scannedItems.isNotEmpty ? _proceedToPayment : null,
                    icon: const Icon(Icons.payment),
                    label: Text('Pay \$${_totalAmount.toStringAsFixed(2)}'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ScannedItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(item.barcode, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _updateQuantity(index, -1),
                ),
                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _updateQuantity(index, 1),
                ),
              ],
            ),
            
            // Remove button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeItem(index),
            ),
          ],
        ),
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode == _lastScannedBarcode) return;
    
    _lastScannedBarcode = barcode;
    
    // Simulate product lookup
    // In real app, would call API to get product details
    final product = _mockLookupProduct(barcode);
    
    if (product != null) {
      setState(() {
        // Check if already in cart
        final existingIndex = _scannedItems.indexWhere((item) => item.barcode == barcode);
        if (existingIndex >= 0) {
          _scannedItems[existingIndex].quantity++;
        } else {
          _scannedItems.add(product);
        }
        _calculateTotal();
      });
      
      // Haptic feedback and sound
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added: ${product.name}'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found: $barcode'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    // Debounce to prevent rapid re-scans
    setState(() => _isScanning = false);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _lastScannedBarcode = null;
        });
      }
    });
  }

  ScannedItem? _mockLookupProduct(String barcode) {
    // Mock product database
    final products = {
      '1234567890': ScannedItem(barcode: barcode, name: 'Organic Milk', price: 4.99),
      '2345678901': ScannedItem(barcode: barcode, name: 'Whole Wheat Bread', price: 3.49),
      '3456789012': ScannedItem(barcode: barcode, name: 'Fresh Apples (1kg)', price: 5.99),
      '4567890123': ScannedItem(barcode: barcode, name: 'Chicken Breast', price: 8.99),
      '5678901234': ScannedItem(barcode: barcode, name: 'Orange Juice 1L', price: 3.99),
    };
    
    // Return mock product or generate one based on barcode
    return products[barcode] ?? ScannedItem(
      barcode: barcode,
      name: 'Product $barcode',
      price: double.parse((barcode.hashCode.abs() % 1000 / 100).toStringAsFixed(2)),
    );
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQuantity = _scannedItems[index].quantity + delta;
      if (newQuantity <= 0) {
        _scannedItems.removeAt(index);
      } else {
        _scannedItems[index].quantity = newQuantity;
      }
      _calculateTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _scannedItems.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalAmount = _scannedItems.fold(0, (sum, item) => sum + item.total);
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter barcode number',
            prefixIcon: Icon(Icons.qr_code),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final product = _mockLookupProduct(controller.text);
              if (product != null) {
                setState(() {
                  _scannedItems.add(product);
                  _calculateTotal();
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Self Checkout Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Point camera at product barcode'),
            SizedBox(height: 8),
            Text('2. Wait for beep confirmation'),
            SizedBox(height: 8),
            Text('3. Adjust quantities if needed'),
            SizedBox(height: 8),
            Text('4. Tap Pay to complete checkout'),
            SizedBox(height: 16),
            Text('Need help? Call a staff member.', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _proceedToPayment() {
    Navigator.pushNamed(
      context,
      '/checkout',
      arguments: {
        'orderId': 'SC${DateTime.now().millisecondsSinceEpoch}',
        'totalAmount': _totalAmount,
        'items': _scannedItems.map((item) => {
          'name': item.name,
          'quantity': item.quantity,
          'price': item.price,
        }).toList(),
      },
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}

class ScannedItem {
  final String barcode;
  final String name;
  final double price;
  int quantity;

  ScannedItem({
    required this.barcode,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;
}
