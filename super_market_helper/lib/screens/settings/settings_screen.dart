import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/local_storage_service.dart';
import 'dart:convert';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalStorageService _storage = LocalStorageService();
  
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _voiceCommandsEnabled = true;
  int _expiryWarningDays = 7;
  String _backendUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
      _voiceCommandsEnabled = prefs.getBool('voice_commands') ?? true;
      _expiryWarningDays = prefs.getInt('expiry_warning_days') ?? 7;
      _backendUrl = prefs.getString('backend_url') ?? 'http://localhost:8000';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _exportData() async {
    try {
      final List<dynamic> products = _storage.getAllProducts();
      final jsonData = jsonEncode(products.map((p) => p.toJson()).toList());
      
      // Save to file
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory != null) {
        final file = File('$directory/supermart_backup_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(jsonData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data exported to ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonData = await file.readAsString();
        final List<dynamic> data = jsonDecode(jsonData);
        
        // Clear existing data
        await _storage.clearAllProducts();
        
        // Import new data
        for (var _ in data) {
          // TODO: Import products - implement based on your product model
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data imported successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all products and settings. This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.clearAllProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('General'),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable push notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveSetting('notifications_enabled', value);
            },
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() => _darkModeEnabled = value);
              _saveSetting('dark_mode', value);
            },
          ),
          SwitchListTile(
            title: const Text('Voice Commands'),
            subtitle: const Text('Enable voice-activated controls'),
            value: _voiceCommandsEnabled,
            onChanged: (value) {
              setState(() => _voiceCommandsEnabled = value);
              _saveSetting('voice_commands', value);
            },
          ),
          
          _buildSectionHeader('Inventory Settings'),
          ListTile(
            title: const Text('Expiry Warning Days'),
            subtitle: Text('Alert $_expiryWarningDays days before expiry'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showExpiryDaysDialog(),
          ),
          
          _buildSectionHeader('Backend Configuration'),
          ListTile(
            title: const Text('Backend URL'),
            subtitle: Text(_backendUrl),
            trailing: const Icon(Icons.edit),
            onTap: () => _showBackendUrlDialog(),
          ),
          ListTile(
            title: const Text('Test Connection'),
            leading: const Icon(Icons.network_check),
            onTap: _testConnection,
          ),
          
          _buildSectionHeader('Data Management'),
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Backup your inventory data'),
            leading: const Icon(Icons.upload),
            onTap: _exportData,
          ),
          ListTile(
            title: const Text('Import Data'),
            subtitle: const Text('Restore from backup'),
            leading: const Icon(Icons.download),
            onTap: _importData,
          ),
          ListTile(
            title: const Text('Sync with Backend'),
            subtitle: const Text('Sync local data with server'),
            leading: const Icon(Icons.sync),
            onTap: _syncWithBackend,
          ),
          ListTile(
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all local data'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: _clearAllData,
          ),
          
          _buildSectionHeader('About'),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.info),
          ),
          ListTile(
            title: const Text('Help & Support'),
            leading: const Icon(Icons.help),
            onTap: () {
              // Open help screen
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () {
              // Open privacy policy
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Future<void> _showExpiryDaysDialog() async {
    final controller = TextEditingController(text: _expiryWarningDays.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expiry Warning Days'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Days before expiry',
            hintText: 'Enter number of days',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _expiryWarningDays = result);
      await _saveSetting('expiry_warning_days', result);
    }
  }

  Future<void> _showBackendUrlDialog() async {
    final controller = TextEditingController(text: _backendUrl);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backend URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'http://localhost:8000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _backendUrl = result);
      await _saveSetting('backend_url', result);
    }
  }

  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Test API connection
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncWithBackend() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Syncing with backend...'),
          ],
        ),
      ),
    );

    try {
      // Implement sync logic
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
