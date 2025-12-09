// Receiving Screen
// Stock receiving workflow with barcode scanning

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/expiry_api_service.dart';
import '../../services/barcode_service.dart';
import '../../widgets/barcode_scanner_widget.dart';

class ReceivingScreen extends StatefulWidget {
  const ReceivingScreen({super.key});
  
  @override
  State<ReceivingScreen> createState() => _ReceivingScreenState();
}

class _ReceivingScreenState extends State<ReceivingScreen> {
  final _apiService = ExpiryApiService();
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _notesController = TextEditingController();
  
  GS1BarcodeData? _scannedBarcode;
  File? _palletPhoto;
  File? _invoicePhoto;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _quantityController.dispose();
    _invoiceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _scanBarcode() async {
    final result = await Navigator.push<GS1BarcodeData>(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScanner(
          title: 'Scan Product Batch',
          scanGS1Only: true,
          onGS1Scanned: (data) => data,
        ),
      ),
    );
    
    if (result != null && result.isValid) {
      setState(() {
        _scannedBarcode = result;
        _errorMessage = null;
      });
    }
  }
  
  Future<void> _takePalletPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (photo != null) {
      setState(() {
        _palletPhoto = File(photo.path);
      });
    }
  }
  
  Future<void> _takeInvoicePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (photo != null) {
      setState(() {
        _invoicePhoto = File(photo.path);
      });
    }
  }
  
  Future<void> _submitReceiving() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scannedBarcode == null) {
      setState(() {
        _errorMessage = 'Please scan a product barcode';
      });
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser!;
      
      final logData = {
        'store': user.store!.id,
        'gtin': _scannedBarcode!.gtin,
        'batch_number': _scannedBarcode!.batchNumber,
        'expiry_date': _scannedBarcode!.expiryDate!.toIso8601String().split('T')[0],
        'quantity_received': int.parse(_quantityController.text),
        'invoice_number': _invoiceController.text,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };
      
      await _apiService.createReceivingLog(
        logData,
        palletPhoto: _palletPhoto,
        invoicePhoto: _invoicePhoto,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Receiving log created successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        _formKey.currentState!.reset();
        setState(() {
          _scannedBarcode = null;
          _palletPhoto = null;
          _invoicePhoto = null;
          _quantityController.clear();
          _invoiceController.clear();
          _notesController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Stock'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scan barcode section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Step 1: Scan Product Batch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(
                          _scannedBarcode == null ? 'Scan GS1-128 Barcode' : 'Rescan Barcode',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      if (_scannedBarcode != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('GTIN', _scannedBarcode!.gtin!),
                              _buildInfoRow('Batch', _scannedBarcode!.batchNumber!),
                              _buildInfoRow(
                                'Expiry Date',
                                _formatDate(_scannedBarcode!.expiryDate!),
                              ),
                              if (_scannedBarcode!.productionDate != null)
                                _buildInfoRow(
                                  'Production Date',
                                  _formatDate(_scannedBarcode!.productionDate!),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Quantity and invoice
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step 2: Enter Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity Received *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _invoiceController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter invoice number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Photos section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step 3: Take Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _takePalletPhoto,
                              icon: Icon(
                                _palletPhoto != null ? Icons.check_circle : Icons.camera_alt,
                              ),
                              label: const Text('Pallet Photo'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _takeInvoicePhoto,
                              icon: Icon(
                                _invoicePhoto != null ? Icons.check_circle : Icons.camera_alt,
                              ),
                              label: const Text('Invoice Photo'),
                            ),
                          ),
                        ],
                      ),
                      if (_palletPhoto != null || _invoicePhoto != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (_palletPhoto != null)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _palletPhoto!,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            if (_palletPhoto != null && _invoicePhoto != null)
                              const SizedBox(width: 8),
                            if (_invoicePhoto != null)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _invoicePhoto!,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReceiving,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Submit Receiving Log',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
