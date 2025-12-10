/// Store Map Navigation Screen
/// Interactive store map with aisle navigation and product location finder

import 'package:flutter/material.dart';
import '../../services/customer_app_service.dart';
import '../../services/api_service.dart';

class StoreMapScreen extends StatefulWidget {
  final String storeId;
  final String? highlightProductId;

  const StoreMapScreen({
    super.key,
    required this.storeId,
    this.highlightProductId,
  });

  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  late final CustomerAppService _customerService;
  
  List<Map<String, dynamic>> _aisles = [];
  Map<String, dynamic>? _highlightedLocation;
  String? _selectedAisle;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _customerService = CustomerAppService(ApiService());
    _loadStoreMap();
  }

  Future<void> _loadStoreMap() async {
    setState(() => _isLoading = true);
    
    final aisles = await _customerService.getStoreAisles(widget.storeId);
    
    setState(() {
      _aisles = aisles;
      _isLoading = false;
    });

    // Highlight product if specified
    if (widget.highlightProductId != null) {
      _findProduct(widget.highlightProductId!);
    }
  }

  Future<void> _findProduct(String productId) async {
    try {
      final location = await _customerService.findProductLocation(productId, widget.storeId);
      setState(() {
        _highlightedLocation = location;
        _selectedAisle = location['aisle_number'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product location not found')),
        );
      }
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    // Would call API to search products
    // For now, simulate results
    setState(() {
      _searchResults = [
        {'id': '1', 'name': 'Organic Milk', 'aisle': '1', 'section': 'Dairy'},
        {'id': '2', 'name': 'Whole Wheat Bread', 'aisle': '3', 'section': 'Bakery'},
        {'id': '3', 'name': 'Fresh Apples', 'aisle': '5', 'section': 'Produce'},
      ].where((p) => p['name']!.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              // Show current location in store (would use beacons/WiFi positioning)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Locating you in store...')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for a product...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        onChanged: _searchProducts,
                      ),
                      
                      // Search results dropdown
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on),
                                title: Text(result['name'] ?? ''),
                                subtitle: Text('Aisle ${result['aisle']} - ${result['section']}'),
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _selectedAisle = result['aisle'];
                                    _highlightedLocation = result;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Highlighted product info
                if (_highlightedLocation != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _highlightedLocation!['name'] ?? 'Product',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Aisle ${_highlightedLocation!['aisle_number'] ?? _highlightedLocation!['aisle']} • ${_highlightedLocation!['section'] ?? 'Center'}',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.directions),
                          onPressed: () {
                            // Navigate to aisle
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Turn-by-turn directions coming soon!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Store map
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CustomPaint(
                        painter: StoreMapPainter(
                          aisles: _aisles,
                          selectedAisle: _selectedAisle,
                          highlightedLocation: _highlightedLocation,
                          theme: theme,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                
                // Aisle legend
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildLegendItem('Dairy', Colors.blue, Icons.icecream),
                      _buildLegendItem('Bakery', Colors.orange, Icons.bakery_dining),
                      _buildLegendItem('Produce', Colors.green, Icons.eco),
                      _buildLegendItem('Meat', Colors.red, Icons.restaurant),
                      _buildLegendItem('Frozen', Colors.cyan, Icons.ac_unit),
                      _buildLegendItem('Beverages', Colors.purple, Icons.local_drink),
                      _buildLegendItem('Snacks', Colors.amber, Icons.fastfood),
                      _buildLegendItem('Checkout', Colors.grey, Icons.point_of_sale),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showShoppingListNavigation();
        },
        icon: const Icon(Icons.route),
        label: const Text('Optimize Route'),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showShoppingListNavigation() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optimize Shopping Route', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('I\'ll create the most efficient path through the store based on your shopping list.'),
            const SizedBox(height: 16),
            
            // Sample shopping list
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Milk'),
              trailing: Text('Aisle 1'),
            ),
            const ListTile(
              leading: Icon(Icons.circle_outlined),
              title: Text('Bread'),
              trailing: Text('Aisle 3'),
            ),
            const ListTile(
              leading: Icon(Icons.circle_outlined),
              title: Text('Apples'),
              trailing: Text('Aisle 5'),
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Route optimized! Follow the highlighted path.')),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Navigation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Custom painter for the store map
class StoreMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> aisles;
  final String? selectedAisle;
  final Map<String, dynamic>? highlightedLocation;
  final ThemeData theme;

  StoreMapPainter({
    required this.aisles,
    this.selectedAisle,
    this.highlightedLocation,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw store outline
    paint.color = Colors.grey.shade200;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      paint,
    );
    
    // Draw entrance
    paint.color = Colors.green.shade300;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 - 40, size.height - 20, 80, 20),
        const Radius.circular(8),
      ),
      paint,
    );
    
    // Draw sample aisles
    final aisleWidth = (size.width - 80) / 5;
    final aisleHeight = size.height * 0.6;
    
    for (int i = 0; i < 5; i++) {
      final isSelected = selectedAisle == '${i + 1}';
      final x = 40 + i * aisleWidth;
      final y = 60.0;
      
      paint.color = isSelected 
          ? theme.colorScheme.primary.withOpacity(0.3)
          : Colors.grey.shade300;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, aisleWidth - 10, aisleHeight),
          const Radius.circular(4),
        ),
        paint,
      );
      
      // Aisle number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + aisleWidth / 2 - 10, y - 25),
      );
    }
    
    // Draw checkout area
    paint.color = Colors.grey.shade400;
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(40 + i * 80.0, size.height - 80, 60, 30),
          const Radius.circular(4),
        ),
        paint,
      );
    }
    
    // Draw highlighted product marker
    if (highlightedLocation != null && selectedAisle != null) {
      final aisleNum = int.tryParse(selectedAisle!) ?? 1;
      final markerX = 40 + (aisleNum - 1) * aisleWidth + aisleWidth / 2;
      final markerY = 60.0 + aisleHeight / 2;
      
      // Pulse effect circle
      paint.color = theme.colorScheme.primary.withOpacity(0.3);
      canvas.drawCircle(Offset(markerX, markerY), 30, paint);
      
      // Marker
      paint.color = theme.colorScheme.primary;
      canvas.drawCircle(Offset(markerX, markerY), 15, paint);
      
      // Inner dot
      paint.color = Colors.white;
      canvas.drawCircle(Offset(markerX, markerY), 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
