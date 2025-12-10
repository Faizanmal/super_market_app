import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'providers/product_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/expiry_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/enhanced_dashboard_screen.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/smart_pricing/smart_pricing_screen.dart';
import 'screens/iot/iot_dashboard_screen.dart';
import 'screens/sustainability/sustainability_dashboard_screen.dart';
import 'screens/suppliers/supplier_portal_screen.dart';
// New Feature Screens
import 'screens/discounts/batch_discount_screen.dart';
import 'screens/forecasting/sales_forecasting_screen.dart';
import 'screens/customer/customer_hub_screen.dart';
import 'screens/gamification/gamification_dashboard.dart';

/// Main entry point for the SuperMart Manager application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = LocalStorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const SuperMartApp());
}

/// Root application widget
class SuperMartApp extends StatelessWidget {
  const SuperMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide AuthProvider
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..init(),
        ),
        // Provide ProductProvider
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
        ),
        // Provide ExpiryProvider
        ChangeNotifierProvider(
          create: (_) => ExpiryProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            
            // Set initial route based on authentication status
            home: authProvider.isLoggedIn
                ? const EnhancedDashboardScreen()
                : const LoginScreen(),
            
            // Define named routes
            routes: {
              '/login': (context) => const LoginScreen(),
              '/dashboard': (context) => const EnhancedDashboardScreen(),
              '/dashboard-simple': (context) => const DashboardScreen(),
              '/alerts': (context) => const AlertsScreen(),
              '/smart-pricing': (context) => const SmartPricingScreen(),
              '/iot-dashboard': (context) => const IoTDashboardScreen(),
              '/sustainability': (context) => const SustainabilityDashboardScreen(),
              '/supplier-portal': (context) => const SupplierPortalScreen(),
              // New Feature Routes
              '/batch-discounts': (context) => const BatchDiscountScreen(),
              '/sales-forecasting': (context) => const SalesForecastingScreen(),
              '/customer-hub': (context) => const CustomerHubScreen(),
              '/gamification': (context) => const GamificationDashboard(),
            },
            
            // Builder for responsive layout
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0), // Prevent text scaling issues
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
