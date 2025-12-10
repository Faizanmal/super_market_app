import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:cross_file/cross_file.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/chart_widget.dart';
import '../products/add_product_screen.dart';
import 'stock_list_screen.dart';
import 'expiry_alerts_screen.dart';

/// Dashboard screen
/// Main screen showing inventory overview and analytics
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load products when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const _DashboardHome(),
      const StockListScreen(),
      const ExpiryAlertsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperMart Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProductProvider>().refresh();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final navigator = Navigator.of(context);
                await context.read<AuthProvider>().logout();
                if (!mounted) return;
                navigator.pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outlined),
                    const SizedBox(width: 12),
                    Text(context.read<AuthProvider>().currentUser?.fullName ?? 'Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Alerts',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
    );
  }
}

/// Dashboard home widget
class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = provider.getStatistics();
        final categoryData = stats['categoryCount'] as Map<String, int>;

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.read<AuthProvider>().currentUser?.fullName ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Statistics Cards Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Total Products',
                    value: stats['totalProducts'].toString(),
                    icon: Icons.inventory_2,
                    color: AppTheme.primaryColor,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Stock Value',
                    value: '\$${(stats['totalStockValue'] as double).toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: AppTheme.successColor,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Expiring Soon',
                    value: stats['expiringCount'].toString(),
                    icon: Icons.warning_amber,
                    color: AppTheme.warningColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExpiryAlertsScreen()),
                      );
                    },
                  ),
                  _buildStatCard(
                    context,
                    title: 'Low Stock',
                    value: stats['lowStockCount'].toString(),
                    icon: Icons.trending_down,
                    color: AppTheme.dangerColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Distribution Chart
              if (categoryData.isNotEmpty)
                ChartWidget(
                  chartType: ChartType.pie,
                  data: {'categories': categoryData},
                  title: 'Products by Category',
                ),
              const SizedBox(height: 16),

              // Quick Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildActionButton(
                            context,
                            icon: Icons.add_circle_outline,
                            label: 'Add Product',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AddProductScreen()),
                              );
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.qr_code_scanner,
                            label: 'Scan Barcode',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddProductScreen(enableScanner: true),
                                ),
                              );
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.file_download_outlined,
                            label: 'Export Data',
                            onPressed: () async {
                              await _showExportDialog(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // New Features Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.tertiary),
                          const SizedBox(width: 8),
                          Text(
                            'Smart Features',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildActionButton(
                            context,
                            icon: Icons.discount_rounded,
                            label: 'Batch Discounts',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/batch-discounts');
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.auto_graph_rounded,
                            label: 'AI Forecasting',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/sales-forecasting');
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.people_rounded,
                            label: 'Customer Hub',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/customer-hub');
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.stars_rounded,
                            label: 'Staff Performance',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/gamification');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, color: color, size: 24),
                ],
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select export format:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV (Excel)'),
              subtitle: const Text('Comma-separated values'),
              onTap: () async {
                Navigator.pop(context);
                await _exportAsCSV(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Report'),
              subtitle: const Text('Professional report'),
              onTap: () async {
                Navigator.pop(context);
                await _exportAsPDF(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: const Text('Excel Workbook'),
              subtitle: const Text('Full feature spreadsheet'),
              onTap: () async {
                Navigator.pop(context);
                await _exportAsExcel(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsCSV(BuildContext context) async {
    try {
      final provider = context.read<ProductProvider>();
      final products = provider.products;
      
      // Create CSV content
      final buffer = StringBuffer();
      buffer.writeln('Name,SKU,Category,Stock,Price,Expiry Date');
      
      for (final product in products) {
        buffer.writeln('${product.name},${product.sku},${product.category},${product.stockQuantity},${product.price},${product.expiryDate ?? 'N/A'}');
      }
      
      // Save and share
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/inventory_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());
      
      await Share.shareXFiles([XFile(file.path)], text: 'Inventory Export');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportAsPDF(BuildContext context) async {
    try {
      final provider = context.read<ProductProvider>();
      final products = provider.products;
      final stats = provider.getStatistics();
      
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Inventory Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              data: [
                ['Metric', 'Value'],
                ['Total Products', '${stats['totalProducts']}'],
                ['Stock Value', '\$${(stats['totalStockValue'] as double).toStringAsFixed(2)}'],
                ['Low Stock Items', '${stats['lowStockCount']}'],
                ['Expiring Soon', '${stats['expiringCount']}'],
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Product List', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['Name', 'SKU', 'Stock', 'Price'],
                ...products.map((p) => [p.name, p.sku, '${p.stockQuantity}', '\$${p.price.toStringAsFixed(2)}']),
              ],
            ),
          ],
        ),
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles([XFile(file.path)], text: 'Inventory Report');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportAsExcel(BuildContext context) async {
    try {
      final provider = context.read<ProductProvider>();
      final products = provider.products;
      final stats = provider.getStatistics();
      
      var excel = Excel.createExcel();
      
      // Summary sheet
      Sheet summarySheet = excel['Summary'];
      summarySheet.appendRow([
        TextCellValue('Inventory Summary Report'),
      ]);
      summarySheet.appendRow([
        TextCellValue('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
      ]);
      summarySheet.appendRow([]);
      summarySheet.appendRow([
        TextCellValue('Total Products'),
        IntCellValue(stats['totalProducts'] as int),
      ]);
      summarySheet.appendRow([
        TextCellValue('Stock Value'),
        DoubleCellValue((stats['totalStockValue'] as double)),
      ]);
      summarySheet.appendRow([
        TextCellValue('Low Stock Items'),
        IntCellValue(stats['lowStockCount'] as int),
      ]);
      summarySheet.appendRow([
        TextCellValue('Expiring Soon'),
        IntCellValue(stats['expiringCount'] as int),
      ]);
      
      // Products sheet
      Sheet productsSheet = excel['Products'];
      productsSheet.appendRow([
        TextCellValue('Name'),
        TextCellValue('SKU'),
        TextCellValue('Category'),
        TextCellValue('Stock Quantity'),
        TextCellValue('Price'),
        TextCellValue('Expiry Date'),
      ]);
      
      for (final product in products) {
        productsSheet.appendRow([
          TextCellValue(product.name),
          TextCellValue(product.sku),
          TextCellValue(product.category ?? 'N/A'),
          IntCellValue(product.stockQuantity),
          DoubleCellValue(product.price),
          TextCellValue(product.expiryDate?.toString() ?? 'N/A'),
        ]);
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/inventory_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(excel.encode()!);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Inventory Workbook');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel exported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
