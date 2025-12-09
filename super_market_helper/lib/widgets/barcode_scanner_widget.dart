// GS1 Barcode Scanner Widget
// Full-screen barcode scanner with GS1-128 parsing

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/barcode_service.dart';

class BarcodeScanner extends StatefulWidget {
  final Function(GS1BarcodeData) onGS1Scanned;
  final Function(StandardBarcodeData)? onStandardScanned;
  final String title;
  final bool scanGS1Only;
  
  const BarcodeScanner({
    super.key,
    required this.onGS1Scanned,
    this.onStandardScanned,
    this.title = 'Scan Barcode',
    this.scanGS1Only = false,
  });
  
  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  final BarcodeService _barcodeService = BarcodeService();
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.all],
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _isProcessing = false;
  String? _lastScannedCode;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    
    if (rawValue == null || rawValue == _lastScannedCode) return;
    
    _lastScannedCode = rawValue;
    _isProcessing = true;
    
    // Check if it's GS1-128
    if (_isGS1Format(rawValue)) {
      final gs1Data = _barcodeService.parseGS1(rawValue);
      
      if (gs1Data.isValid) {
        _showSuccess('GS1 Barcode Scanned');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
            widget.onGS1Scanned(gs1Data);
          }
        });
      } else {
        _showError('Invalid GS1 barcode format');
        _resetScanning();
      }
    } else {
      // Standard barcode
      if (widget.scanGS1Only) {
        _showError('Please scan a GS1-128 barcode');
        _resetScanning();
      } else {
        final standardData = _barcodeService.parseStandardBarcode(rawValue);
        if (widget.onStandardScanned != null) {
          _showSuccess('Barcode Scanned');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
              widget.onStandardScanned!(standardData);
            }
          });
        } else {
          _showError('Please scan a GS1-128 barcode');
          _resetScanning();
        }
      }
    }
  }
  
  bool _isGS1Format(String barcode) {
    // GS1-128 typically starts with AI codes
    return barcode.startsWith('01') || 
           barcode.startsWith('10') || 
           barcode.startsWith('17') ||
           barcode.contains(String.fromCharCode(29)); // FNC1 character
  }
  
  void _showSuccess(String message) {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _showError(String message) {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _resetScanning() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastScannedCode = null;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, child) {
                switch (value.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, child) {
                return const Icon(Icons.flip_camera_ios);
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          
          // Scan area overlay
          CustomPaint(
            painter: ScannerOverlay(
              scanAreaSize: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Container(),
          ),
          
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    widget.scanGS1Only
                        ? 'Position GS1-128 barcode within the frame'
                        : 'Position barcode within the frame',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Scanner overlay painter
class ScannerOverlay extends CustomPainter {
  final double scanAreaSize;
  
  ScannerOverlay({required this.scanAreaSize});
  
  @override
  void paint(Canvas canvas, Size size) {
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize * 0.6,
    );
    
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final scanAreaPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(12)));
    
    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanAreaPath,
    );
    
    // Dark overlay
    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black54,
    );
    
    // Scan area border
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(12)),
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    
    // Corner markers
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    
    // Top-left
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left + cornerLength, scanArea.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left, scanArea.top + cornerLength),
      cornerPaint,
    );
    
    // Top-right
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right - cornerLength, scanArea.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right, scanArea.top + cornerLength),
      cornerPaint,
    );
    
    // Bottom-left
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left + cornerLength, scanArea.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left, scanArea.bottom - cornerLength),
      cornerPaint,
    );
    
    // Bottom-right
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom),
      Offset(scanArea.right - cornerLength, scanArea.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom - cornerLength),
      cornerPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// QR Code Scanner for Shelf Locations
class QRScanner extends StatefulWidget {
  final Function(ShelfLocationData) onQRScanned;
  final String title;
  
  const QRScanner({
    super.key,
    required this.onQRScanned,
    this.title = 'Scan Shelf Location',
  });
  
  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final BarcodeService _barcodeService = BarcodeService();
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _isProcessing = false;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleQRCode(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    
    if (rawValue == null) return;
    
    _isProcessing = true;
    
    final shelfData = _barcodeService.parseShelfQR(rawValue);
    
    if (shelfData != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Shelf Location Scanned'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
          widget.onQRScanned(shelfData);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Invalid shelf location QR code'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, child) {
                switch (value.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleQRCode,
          ),
          
          CustomPaint(
            painter: ScannerOverlay(scanAreaSize: MediaQuery.of(context).size.width * 0.7),
            child: Container(),
          ),
          
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Icon(Icons.qr_code_2, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Position QR code within the frame',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
