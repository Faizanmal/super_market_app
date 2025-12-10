/// SuperMart Pro - Enhanced Dashboard Screen
/// Modern Material 3 design with analytics overview
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/voice_fab.dart';
import 'gamification/gamification_dashboard.dart';
// import '../providers/app_providers.dart';

class EnhancedDashboardScreen extends ConsumerStatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  ConsumerState<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends ConsumerState<EnhancedDashboardScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Side Navigation Rail (for larger screens)
            if (MediaQuery.of(context).size.width > 800)
              _buildNavigationRail(colorScheme),
            
            // Main Content
            Expanded(
              child: _selectedNavIndex == 4 
                  ? const GamificationDashboard() 
                  : CustomScrollView(
                slivers: [
                  // App Bar
                  _buildSliverAppBar(theme, colorScheme),
                  
                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Welcome Header
                        _buildWelcomeHeader(theme),
                        const SizedBox(height: 24),
                        
                        // Quick Stats
                        _buildQuickStats(colorScheme),
                        const SizedBox(height: 24),
                        
                        // Alerts Section
                        _buildAlertsSection(theme, colorScheme),
                        const SizedBox(height: 24),
                        
                        // Charts Section
                        _buildChartsSection(theme, colorScheme),
                        const SizedBox(height: 24),
                        
                        // AI Recommendations
                        _buildAIRecommendations(theme, colorScheme),
                        const SizedBox(height: 24),
                        
                        // Recent Activity
                        _buildRecentActivity(theme, colorScheme),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation (for smaller screens)
      bottomNavigationBar: MediaQuery.of(context).size.width <= 800
          ? _buildBottomNavigation(colorScheme)
          : null,
      
      // FAB
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const VoiceFAB(),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () => _showQuickActionMenu(context),
            icon: const Icon(Icons.add),
            label: const Text('Quick Add'),
            elevation: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(ColorScheme colorScheme) {
    return NavigationRail(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedNavIndex = index);
      },
      labelType: NavigationRailLabelType.selected,
      backgroundColor: colorScheme.surfaceContainerLow,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.store, color: colorScheme.onPrimaryContainer),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('Products'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.warning_amber_outlined),
          selectedIcon: Icon(Icons.warning_amber),
          label: Text('Expiry'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Analytics'),
        ),

        NavigationRailDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events),
          label: Text('Gamification'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      floating: true,
      snap: true,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.storefront,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SuperMart Pro',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Main Store',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Search
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search),
          tooltip: 'Search',
        ),
        // Notifications
        Badge(
          label: const Text('3'),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
        ),
        // Profile
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () {},
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.secondaryContainer,
              child: Text(
                'JD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good ${_getGreeting()}, John!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s what\'s happening with your inventory today.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Total Products',
          value: '1,250',
          icon: Icons.inventory_2,
          color: colorScheme.primary,
          trend: '+12',
          trendUp: true,
        ),
        _StatCard(
          title: 'Expiring Soon',
          value: '23',
          icon: Icons.warning_amber,
          color: colorScheme.error,
          trend: '-5',
          trendUp: false,
        ),
        _StatCard(
          title: 'Low Stock',
          value: '15',
          icon: Icons.trending_down,
          color: Colors.orange,
          trend: '+3',
          trendUp: true,
        ),
        _StatCard(
          title: 'Today\'s Sales',
          value: '\$4,580',
          icon: Icons.point_of_sale,
          color: Colors.green,
          trend: '+8%',
          trendUp: true,
        ),
      ],
    );
  }

  Widget _buildAlertsSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alerts & Notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AlertTile(
          icon: Icons.error_outline,
          iconColor: colorScheme.error,
          title: '5 products expired today',
          subtitle: 'Review and remove from inventory',
          action: 'Review',
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _AlertTile(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
          title: 'Organic Milk running low',
          subtitle: 'Only 8 units remaining (below reorder point)',
          action: 'Reorder',
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _AlertTile(
          icon: Icons.local_shipping,
          iconColor: colorScheme.primary,
          title: 'Shipment arriving today',
          subtitle: 'PO-2025-0234 from Farm Fresh Supplies',
          action: 'Track',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildChartsSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Overview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sales & Inventory Chart',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'FL Chart integration area',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIRecommendations(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: colorScheme.onPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Smart Recommendations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Predicted high demand for dairy products this weekend',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Consider ordering 50 additional units of milk and yogurt to avoid stockouts.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.tonal(
                      onPressed: () {},
                      child: const Text('Create Order'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._buildActivityItems(theme, colorScheme),
      ],
    );
  }

  List<Widget> _buildActivityItems(ThemeData theme, ColorScheme colorScheme) {
    final activities = [
      _ActivityItem(
        icon: Icons.add_circle,
        iconColor: Colors.green,
        title: 'Stock received',
        subtitle: '50 units of Organic Milk added',
        time: '5 min ago',
      ),
      _ActivityItem(
        icon: Icons.remove_circle,
        iconColor: Colors.orange,
        title: 'Stock sold',
        subtitle: '12 units of Fresh Bread sold',
        time: '15 min ago',
      ),
      _ActivityItem(
        icon: Icons.warning,
        iconColor: colorScheme.error,
        title: 'Expiry alert',
        subtitle: '3 products expiring in 2 days',
        time: '1 hour ago',
      ),
      _ActivityItem(
        icon: Icons.person_add,
        iconColor: colorScheme.primary,
        title: 'New user added',
        subtitle: 'Sarah Johnson joined as Cashier',
        time: '2 hours ago',
      ),
    ];

    return activities.map((activity) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: activity.iconColor.withValues(alpha: 0.1),
            child: Icon(activity.icon, color: activity.iconColor, size: 20),
          ),
          title: Text(
            activity.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            activity.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Text(
            activity.time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBottomNavigation(ColorScheme colorScheme) {
    return NavigationBar(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedNavIndex = index);
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
          label: 'Products',
        ),
        NavigationDestination(
          icon: Icon(Icons.warning_amber_outlined),
          selectedIcon: Icon(Icons.warning_amber),
          label: 'Expiry',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),

        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events),
          label: 'Gamification',
        ),
      ],
    );
  }

  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: const Text('Add Product'),
              subtitle: const Text('Create a new product entry'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.qr_code_scanner, color: Colors.white),
              ),
              title: const Text('Scan Barcode'),
              subtitle: const Text('Scan product barcode'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.inventory, color: Colors.white),
              ),
              title: const Text('Stock Adjustment'),
              subtitle: const Text('Record stock in/out'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                child: const Icon(Icons.receipt_long, color: Colors.white),
              ),
              title: const Text('Generate Report'),
              subtitle: const Text('Create inventory report'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ============================================================================
// Supporting Widgets
// ============================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool trendUp;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendUp ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: trendUp ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  const _AlertTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: TextButton(
          onPressed: onTap,
          child: Text(action),
        ),
      ),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
