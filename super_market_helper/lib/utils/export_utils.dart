import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../config/constants.dart';
import '../utils/date_utils.dart' as app_date_utils;

/// Export utilities for generating reports
/// Handles CSV and PDF export functionality
class ExportUtils {
  /// Export products to CSV format
  static String exportToCSV(List<Product> products) {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
      'ID,Name,Category,Quantity,Expiry Date,Supplier,Cost Price,Selling Price,Barcode,Status',
    );

    // CSV Data
    for (var product in products) {
      buffer.writeln(
        '${_escapeCsv(product.id)},'
        '${_escapeCsv(product.name)},'
        '${_escapeCsv(product.category)},'
        '${product.quantity},'
        '${app_date_utils.DateUtils.formatDisplayDate(product.expiryDate)},'
        '${_escapeCsv(product.supplier)},'
        '${product.costPrice.toStringAsFixed(2)},'
        '${product.sellingPrice.toStringAsFixed(2)},'
        '${_escapeCsv(product.barcode ?? '')},'
        '${_getExpiryStatusText(product.expiryStatus)}',
      );
    }

    return buffer.toString();
  }

  /// Escape CSV values
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Get expiry status as text
  static String _getExpiryStatusText(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.fresh:
        return 'Fresh';
      case ExpiryStatus.warning:
        return 'Expiring Soon';
      case ExpiryStatus.danger:
        return 'Critical';
      case ExpiryStatus.expired:
        return 'Expired';
    }
  }

  /// Export products to PDF
  static Future<File> exportToPDF(
    List<Product> products, {
    String title = 'Inventory Report',
  }) async {
    final pdf = pw.Document();

    // Calculate statistics
    final totalProducts = products.length;
    final totalValue = products.fold<double>(
      0,
      (sum, p) => sum + p.totalSellingValue,
    );
    final expiredCount = products.where((p) => p.isExpired).length;
    final lowStockCount = products.where((p) => p.stockStatus == StockStatus.lowStock).length;

    // Add pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildSummaryRow('Total Products:', totalProducts.toString()),
                _buildSummaryRow('Total Value:', '\$${totalValue.toStringAsFixed(2)}'),
                _buildSummaryRow('Expired Products:', expiredCount.toString()),
                _buildSummaryRow('Low Stock Items:', lowStockCount.toString()),
                _buildSummaryRow(
                  'Generated:',
                  DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now()),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // Products Table
          pw.Text(
            'Products',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          // Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                children: [
                  _buildTableCell('Product', isHeader: true),
                  _buildTableCell('Category', isHeader: true),
                  _buildTableCell('Qty', isHeader: true),
                  _buildTableCell('Expiry', isHeader: true),
                  _buildTableCell('Status', isHeader: true),
                ],
              ),
              // Data Rows
              ...products.map(
                (product) => pw.TableRow(
                  children: [
                    _buildTableCell(product.name),
                    _buildTableCell(product.category),
                    _buildTableCell(product.quantity.toString()),
                    _buildTableCell(
                      app_date_utils.DateUtils.formatDisplayDate(product.expiryDate),
                    ),
                    _buildTableCell(_getExpiryStatusText(product.expiryStatus)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${output.path}/inventory_report_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Build summary row for PDF
  static pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build table cell for PDF
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Save CSV to file
  static Future<File> saveCSVToFile(String csvContent) async {
    final output = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${output.path}/inventory_export_$timestamp.csv');
    await file.writeAsString(csvContent);
    return file;
  }

  /// Export expiring products report
  static Future<File> exportExpiringProductsReport(
    List<Product> expiringProducts,
  ) async {
    return exportToPDF(
      expiringProducts,
      title: 'Expiring Products Report',
    );
  }

  /// Export low stock report
  static Future<File> exportLowStockReport(
    List<Product> lowStockProducts,
  ) async {
    return exportToPDF(
      lowStockProducts,
      title: 'Low Stock Report',
    );
  }

  /// Generate inventory value report
  static String generateInventoryValueReport(List<Product> products) {
    final buffer = StringBuffer();
    
    buffer.writeln('INVENTORY VALUE REPORT');
    buffer.writeln('Generated: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    double totalCost = 0;
    double totalSelling = 0;
    double totalProfit = 0;

    for (var product in products) {
      totalCost += product.totalCostValue;
      totalSelling += product.totalSellingValue;
      totalProfit += product.totalProfit;
    }

    buffer.writeln('Total Products: ${products.length}');
    buffer.writeln('Total Cost Value: \$${totalCost.toStringAsFixed(2)}');
    buffer.writeln('Total Selling Value: \$${totalSelling.toStringAsFixed(2)}');
    buffer.writeln('Potential Profit: \$${totalProfit.toStringAsFixed(2)}');
    buffer.writeln('Profit Margin: ${totalCost > 0 ? ((totalProfit / totalCost) * 100).toStringAsFixed(2) : 0}%');
    buffer.writeln();
    buffer.writeln('=' * 50);

    return buffer.toString();
  }
}
