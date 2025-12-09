// Audit Workflow Screen
// Interactive audit workflow with QR scanning and photo capture

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/expiry_models.dart';
import '../../services/expiry_api_service.dart';
import '../../services/barcode_service.dart';
import '../../widgets/barcode_scanner_widget.dart';

class AuditWorkflowScreen extends StatefulWidget {
  final ShelfAudit audit;
  
  const AuditWorkflowScreen({super.key, required this.audit});
  
  @override
  State<AuditWorkflowScreen> createState() => _AuditWorkflowScreenState();
}

class _AuditWorkflowScreenState extends State<AuditWorkflowScreen> {
  final _apiService = ExpiryApiService();
  final _notesController = TextEditingController();
  
  ShelfLocationData? _currentLocation;
  File? _currentPhoto;
  String _selectedCondition = 'good';
  bool _isSubmitting = false;
  int _itemsScanned = 0;
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _scanShelfLocation() async {
    final result = await Navigator.push<ShelfLocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScanner(
          title: 'Scan Shelf Location',
          onQRScanned: (data) => data,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _currentLocation = result;
      });
    }
  }
  
  Future<void> _scanProductBatch() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan shelf location first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
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
      _showAddItemDialog(result);
    }
  }
  
  void _showAddItemDialog(GS1BarcodeData barcodeData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Audit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GTIN: ${barcodeData.gtin}'),
              Text('Batch: ${barcodeData.batchNumber}'),
              Text('Expiry: ${_formatDate(barcodeData.expiryDate!)}'),
              const SizedBox(height: 16),
              const Text(
                'Condition:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedCondition,
                items: const [
                  DropdownMenuItem(value: 'good', child: Text('Good')),
                  DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                  DropdownMenuItem(value: 'expired', child: Text('Expired')),
                  DropdownMenuItem(value: 'near_expiry', child: Text('Near Expiry')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );
                  
                  if (photo != null) {
                    setState(() {
                      _currentPhoto = File(photo.path);
                    });
                  }
                },
                icon: Icon(_currentPhoto != null ? Icons.check : Icons.camera_alt),
                label: Text(_currentPhoto != null ? 'Photo Taken' : 'Take Photo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetItemForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addAuditItem(barcodeData);
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addAuditItem(GS1BarcodeData barcodeData) async {
    setState(() => _isSubmitting = true);
    
    try {
      // In a real app, you'd need to get the actual batch ID from the backend
      // For now, we'll use placeholder data
      final itemData = {
        'audit': widget.audit.id,
        'gtin': barcodeData.gtin,
        'batch_number': barcodeData.batchNumber,
        'condition': _selectedCondition,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };
      
      await _apiService.addAuditItem(itemData, photo: _currentPhoto);
      
      setState(() {
        _itemsScanned++;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added to audit'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _resetItemForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
  
  void _resetItemForm() {
    setState(() {
      _currentPhoto = null;
      _selectedCondition = 'good';
      _notesController.clear();
    });
  }
  
  Future<void> _completeAudit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Audit'),
        content: Text(
          'Complete this audit with $_itemsScanned items scanned?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      await _apiService.completeAudit(widget.audit.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audit #${widget.audit.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _itemsScanned > 0 && !_isSubmitting
                ? _completeAudit
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.qr_code,
                  'Items Scanned',
                  _itemsScanned.toString(),
                ),
                _buildStatItem(
                  Icons.location_on,
                  'Current Location',
                  _currentLocation?.locationCode ?? 'None',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Instructions
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline, size: 48, color: Colors.blue),
                          const SizedBox(height: 16),
                          const Text(
                            'Audit Workflow',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionStep(
                            1,
                            'Scan shelf location QR code',
                            _currentLocation != null,
                          ),
                          _buildInstructionStep(
                            2,
                            'Scan product batch barcodes',
                            _itemsScanned > 0,
                          ),
                          _buildInstructionStep(
                            3,
                            'Take photos of damaged items',
                            false,
                          ),
                          _buildInstructionStep(
                            4,
                            'Complete audit when finished',
                            false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  ElevatedButton.icon(
                    onPressed: _scanShelfLocation,
                    icon: const Icon(Icons.qr_code_2),
                    label: Text(
                      _currentLocation == null
                          ? 'Scan Shelf Location'
                          : 'Change Location',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ElevatedButton.icon(
                    onPressed: _currentLocation != null ? _scanProductBatch : null,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Product Batch'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                    ),
                  ),
                  
                  if (_itemsScanned > 0) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$_itemsScanned items have been added to this audit',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildInstructionStep(int step, String text, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: completed ? Colors.green : Colors.grey[300],
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(step.toString()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                decoration: completed ? TextDecoration.lineThrough : null,
                color: completed ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
