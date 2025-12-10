/// Application Routes Configuration
/// All routes for new features

import 'package:flutter/material.dart';

// New Feature Screens
import 'screens/ai_assistant/ai_chat_screen.dart';
import 'screens/customer/loyalty_dashboard_screen.dart';
import 'screens/customer/customer_profile_screen.dart';
import 'screens/checkout/self_checkout_screen.dart';
import 'screens/payment/checkout_screen.dart';
import 'screens/navigation/store_map_screen.dart';
import 'screens/orders/order_history_screen.dart';
import 'screens/recipes/recipe_browser_screen.dart';
import 'screens/deals/deals_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';
import 'screens/marketing/marketing_dashboard_screen.dart';
import 'screens/compliance/compliance_dashboard_screen.dart';

/// New feature routes to add to your app
final Map<String, WidgetBuilder> newFeatureRoutes = {
  // Customer-facing features
  '/ai-chat': (context) => const AIChatScreen(),
  '/loyalty': (context) => const LoyaltyDashboardScreen(),
  '/profile': (context) => const CustomerProfileScreen(),
  '/self-checkout': (context) => const SelfCheckoutScreen(),
  '/store-map': (context) => StoreMapScreen(
        storeId: ModalRoute.of(context)?.settings.arguments as String? ?? '1',
      ),
  '/order-history': (context) => const OrderHistoryScreen(),
  '/recipes': (context) => const RecipeBrowserScreen(),
  '/deals': (context) => const DealsScreen(),
  
  // Staff features
  '/staff-portal': (context) => const StaffDashboardScreen(),
  
  // Admin features
  '/marketing': (context) => const MarketingDashboardScreen(),
  '/compliance': (context) => const ComplianceDashboardScreen(),
};

/// Generate checkout route with parameters
Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/checkout':
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          orderId: args?['orderId'] ?? '',
          totalAmount: args?['totalAmount'] ?? 0.0,
          items: args?['items'] ?? [],
        ),
      );
    case '/store-map':
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => StoreMapScreen(
          storeId: args?['storeId'] ?? '1',
          highlightProductId: args?['productId'],
        ),
      );
    default:
      // Check if route exists in newFeatureRoutes
      if (newFeatureRoutes.containsKey(settings.name)) {
        return MaterialPageRoute(
          builder: newFeatureRoutes[settings.name]!,
          settings: settings,
        );
      }
      return null;
  }
}

/// Customer App Bottom Navigation Items
class CustomerAppNavigation {
  static const List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
    BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Deals'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];
  
  static const List<String> routes = [
    '/home',
    '/products',
    '/deals',
    '/order-history',
    '/profile',
  ];
}

/// Quick action buttons for dashboard
class QuickActionItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

const List<QuickActionItem> customerQuickActions = [
  QuickActionItem(
    icon: Icons.qr_code_scanner,
    label: 'Self Checkout',
    route: '/self-checkout',
    color: Colors.blue,
  ),
  QuickActionItem(
    icon: Icons.smart_toy,
    label: 'AI Assistant',
    route: '/ai-chat',
    color: Colors.purple,
  ),
  QuickActionItem(
    icon: Icons.map,
    label: 'Store Map',
    route: '/store-map',
    color: Colors.green,
  ),
  QuickActionItem(
    icon: Icons.restaurant_menu,
    label: 'Recipes',
    route: '/recipes',
    color: Colors.orange,
  ),
  QuickActionItem(
    icon: Icons.card_giftcard,
    label: 'Loyalty',
    route: '/loyalty',
    color: Colors.amber,
  ),
  QuickActionItem(
    icon: Icons.local_offer,
    label: 'Deals',
    route: '/deals',
    color: Colors.red,
  ),
];

const List<QuickActionItem> staffQuickActions = [
  QuickActionItem(
    icon: Icons.schedule,
    label: 'My Schedule',
    route: '/staff-portal',
    color: Colors.blue,
  ),
  QuickActionItem(
    icon: Icons.access_time,
    label: 'Clock In/Out',
    route: '/staff-portal',
    color: Colors.green,
  ),
  QuickActionItem(
    icon: Icons.school,
    label: 'Training',
    route: '/staff-portal',
    color: Colors.purple,
  ),
  QuickActionItem(
    icon: Icons.thermostat,
    label: 'Compliance',
    route: '/compliance',
    color: Colors.red,
  ),
];

const List<QuickActionItem> adminQuickActions = [
  QuickActionItem(
    icon: Icons.campaign,
    label: 'Marketing',
    route: '/marketing',
    color: Colors.blue,
  ),
  QuickActionItem(
    icon: Icons.safety_check,
    label: 'Compliance',
    route: '/compliance',
    color: Colors.red,
  ),
  QuickActionItem(
    icon: Icons.people,
    label: 'Staff',
    route: '/staff-portal',
    color: Colors.green,
  ),
];
