/// Customer Profile Screen
/// User account settings, preferences, and profile management

import 'package:flutter/material.dart';
import '../../services/customer_app_service.dart';
import '../../services/api_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  late final CustomerAppService _customerService;
  
  CustomerProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  // Form controllers
  final _phoneController = TextEditingController();
  final List<String> _selectedDietaryPrefs = [];
  final List<String> _selectedAllergens = [];

  final List<String> _dietaryOptions = [
    'Vegetarian', 'Vegan', 'Pescatarian', 'Gluten-Free', 
    'Dairy-Free', 'Keto', 'Paleo', 'Halal', 'Kosher'
  ];

  final List<String> _allergenOptions = [
    'Peanuts', 'Tree Nuts', 'Milk', 'Eggs', 'Fish', 
    'Shellfish', 'Wheat', 'Soy', 'Sesame'
  ];

  @override
  void initState() {
    super.initState();
    _customerService = CustomerAppService(ApiService());
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _customerService.getProfile();
      setState(() {
        _profile = profile;
        _phoneController.text = profile.phoneNumber ?? '';
        _selectedDietaryPrefs.addAll(profile.dietaryPreferences);
        _selectedAllergens.addAll(profile.allergens);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Use mock data
      setState(() {
        _profile = CustomerProfile(
          id: '1',
          email: 'user@example.com',
          fullName: 'John Doe',
          phoneNumber: '+1 555-123-4567',
        );
        _phoneController.text = _profile!.phoneNumber ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile header
                  _buildProfileHeader(theme),
                  
                  // Profile sections
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildContactSection(theme),
                        const SizedBox(height: 16),
                        _buildDietarySection(theme),
                        const SizedBox(height: 16),
                        _buildAllergenSection(theme),
                        const SizedBox(height: 16),
                        _buildNotificationSection(theme),
                        const SizedBox(height: 16),
                        _buildQuickActionsSection(theme),
                        const SizedBox(height: 24),
                        
                        if (_isEditing)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              child: const Text('Save Changes'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(_profile?.fullName ?? 'U'),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.secondary,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 16),
                      color: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name and email
          Text(
            _profile?.fullName ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _profile?.email ?? '',
            style: const TextStyle(color: Colors.white70),
          ),
          
          const SizedBox(height: 16),
          
          // Member since
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                SizedBox(width: 8),
                Text('Gold Member since 2023', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_phone),
                SizedBox(width: 12),
                Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            _isEditing
                ? TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  )
                : ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone'),
                    subtitle: Text(_profile?.phoneNumber ?? 'Not set'),
                    contentPadding: EdgeInsets.zero,
                  ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(_profile?.email ?? ''),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietarySection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant),
                SizedBox(width: 12),
                Text('Dietary Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            const Text('Help us recommend products that match your diet:', 
              style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dietaryOptions.map((pref) {
                final isSelected = _selectedDietaryPrefs.contains(pref);
                return FilterChip(
                  label: Text(pref),
                  selected: isSelected,
                  onSelected: _isEditing
                      ? (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDietaryPrefs.add(pref);
                            } else {
                              _selectedDietaryPrefs.remove(pref);
                            }
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergenSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Text('Allergen Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            const Text('We\'ll warn you about products containing these allergens:', 
              style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allergenOptions.map((allergen) {
                final isSelected = _selectedAllergens.contains(allergen);
                return FilterChip(
                  label: Text(allergen),
                  selected: isSelected,
                  selectedColor: Colors.red.shade100,
                  checkmarkColor: Colors.red,
                  onSelected: _isEditing
                      ? (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAllergens.add(allergen);
                            } else {
                              _selectedAllergens.remove(allergen);
                            }
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications),
                SizedBox(width: 12),
                Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Order Updates'),
              subtitle: const Text('Get notified about your orders'),
              value: true,
              onChanged: _isEditing ? (v) {} : null,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Deal Alerts'),
              subtitle: const Text('Personalized offers and flash sales'),
              value: true,
              onChanged: _isEditing ? (v) {} : null,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Recipe Suggestions'),
              subtitle: const Text('Based on your preferences'),
              value: false,
              onChanged: _isEditing ? (v) {} : null,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Payment Methods'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/payment-methods'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Saved Addresses'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Order History'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/order-history'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: const Text('Gift Cards'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade400),
            title: Text('Sign Out', style: TextStyle(color: Colors.red.shade400)),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Future<void> _saveProfile() async {
    try {
      await _customerService.updateProfile({
        'phone_number': _phoneController.text,
        'dietary_preferences': _selectedDietaryPrefs,
        'allergens': _selectedAllergens,
      });
      
      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
