// Barcode Scanner Service with GS1-128 Support
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import '../../core/utils/gs1_parser.dart';

class BarcodeScannerService {
  MobileScannerController? _controller;
  
  /// Initialize scanner controller
  MobileScannerController getController() {
    _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    return _controller!;
  }

  /// Dispose scanner controller
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }

  /// Process scanned barcode
  ScanResult processBarcode(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    
    if (barcodes.isEmpty) {
      return ScanResult.error('No barcode detected');
    }

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue ?? '';

    // Determine barcode type
    final type = _getBarcodeType(barcode.format);
    
    // Check if it's GS1-128
    if (_isGS1Barcode(barcode.format, rawValue)) {
      return _processGS1Barcode(rawValue);
    }

    // Regular barcode
    return ScanResult(
      success: true,
      rawValue: rawValue,
      type: type,
      format: barcode.format.toString(),
    );
  }

  /// Process GS1-128 barcode
  ScanResult _processGS1Barcode(String rawValue) {
    try {
      final gs1Data = GS1Parser.extractData(rawValue);
      
      if (!gs1Data.isValid) {
        return ScanResult.error('Invalid GS1 barcode format');
      }

      return ScanResult(
        success: true,
        rawValue: rawValue,
        type: 'GS1-128',
        format: 'CODE_128',
        isGS1: true,
        gs1Data: gs1Data,
      );
    } catch (e) {
      return ScanResult.error('Failed to parse GS1 barcode: $e');
    }
  }

  /// Check if barcode is GS1 format
  bool _isGS1Barcode(BarcodeFormat format, String rawValue) {
    // GS1-128 uses Code 128
    if (format != BarcodeFormat.code128) return false;
    
    // Check for FNC1 character or common GS1 AIs
    return rawValue.contains(String.fromCharCode(29)) ||
           rawValue.startsWith('01') ||
           rawValue.startsWith('10') ||
           rawValue.startsWith('17');
  }

  /// Get barcode type name
  String _getBarcodeType(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.code93:
        return 'Code 93';
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      // case BarcodeFormat.upcA:
      //   return 'UPC-A';
      // case BarcodeFormat.upcE:
      //   return 'UPC-E';
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      default:
        return 'Unknown';
    }
  }

  /// Toggle torch
  Future<void> toggleTorch() async {
    await _controller?.toggleTorch();
  }

  /// Switch camera
  Future<void> switchCamera() async {
    await _controller?.switchCamera();
  }
}

/// Scan result model
class ScanResult {
  final bool success;
  final String? error;
  final String? rawValue;
  final String? type;
  final String? format;
  final bool isGS1;
  final GS1Data? gs1Data;

  ScanResult({
    required this.success,
    this.error,
    this.rawValue,
    this.type,
    this.format,
    this.isGS1 = false,
    this.gs1Data,
  });

  factory ScanResult.error(String error) {
    return ScanResult(
      success: false,
      error: error,
    );
  }

  /// Get display-friendly summary
  String get summary {
    if (!success) return error ?? 'Scan failed';
    
    if (isGS1 && gs1Data != null) {
      final parts = <String>[];
      if (gs1Data!.gtin != null) parts.add('GTIN: ${gs1Data!.gtin}');
      if (gs1Data!.batchNumber != null) parts.add('Batch: ${gs1Data!.batchNumber}');
      if (gs1Data!.effectiveExpiryDate != null) {
        parts.add('Expiry: ${_formatDate(gs1Data!.effectiveExpiryDate!)}');
      }
      return parts.join('\n');
    }
    
    return rawValue ?? 'No data';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// ML Kit Barcode Scanner (Alternative/Fallback)
class MLKitBarcodeScanner {
  final mlkit.BarcodeScanner _scanner = mlkit.BarcodeScanner(
    formats: [
      mlkit.BarcodeFormat.code128,
      mlkit.BarcodeFormat.code39,
      mlkit.BarcodeFormat.code93,
      mlkit.BarcodeFormat.ean13,
      mlkit.BarcodeFormat.ean8,
      // mlkit.BarcodeFormat.upcA,
      // mlkit.BarcodeFormat.upcE,
      mlkit.BarcodeFormat.qrCode,
    ],
  );

  /// Scan from image
  Future<List<mlkit.Barcode>> scanImage(mlkit.InputImage inputImage) async {
    try {
      return await _scanner.processImage(inputImage);
    } catch (e) {
      throw Exception('Failed to scan image: $e');
    }
  }

  void dispose() {
    _scanner.close();
  }
}
