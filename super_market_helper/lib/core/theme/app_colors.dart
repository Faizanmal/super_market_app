import 'package:flutter/material.dart';

/// Application Color Palette
/// Defines all colors used throughout the app for consistent theming.
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ==================== Primary Colors ====================
  /// Primary brand color - Green representing freshness and sustainability
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);
  static const Color primaryVariant = Color(0xFF1B5E20);
  
  // ==================== Secondary Colors ====================
  /// Secondary color - Orange for alerts and important actions
  static const Color secondary = Color(0xFFFF6F00);
  static const Color secondaryLight = Color(0xFFFFA040);
  static const Color secondaryDark = Color(0xFFC43E00);
  
  // ==================== Accent Colors ====================
  /// Accent color - Blue for information and links
  static const Color accent = Color(0xFF0288D1);
  static const Color accentLight = Color(0xFF5EB8FF);
  static const Color accentDark = Color(0xFF005B9F);
  
  // ==================== Semantic Colors ====================
  /// Success - Green for positive actions and confirmations
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF80E27E);
  static const Color successDark = Color(0xFF087F23);
  
  /// Warning - Orange/Amber for warnings and cautions
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFD95B);
  static const Color warningDark = Color(0xFFC77800);
  
  /// Error/Danger - Red for errors and destructive actions
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFF7961);
  static const Color errorDark = Color(0xFFBA000D);
  
  /// Info - Blue for informational messages
  static const Color info = Color(0xFF29B6F6);
  static const Color infoLight = Color(0xFF73E8FF);
  static const Color infoDark = Color(0xFF0086C3);
  
  // ==================== Neutral Colors ====================
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color surfaceContainerHighest = Color(0xFFE6E6E6);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);
  
  // ==================== Background Colors ====================
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2D2D2D);
  
  // ==================== Text Colors ====================
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textHintDark = Color(0xFF808080);
  
  // ==================== Divider Colors ====================
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);
  
  // ==================== Status Colors ====================
  /// Stock status colors
  static const Color stockAdequate = Color(0xFF4CAF50);
  static const Color stockLow = Color(0xFFFF9800);
  static const Color stockCritical = Color(0xFFFF5722);
  static const Color stockOut = Color(0xFFF44336);
  static const Color stockOverstocked = Color(0xFF2196F3);
  
  /// Expiry status colors
  static const Color expiryFresh = Color(0xFF4CAF50);
  static const Color expiryWarning = Color(0xFFFF9800);
  static const Color expiryExpired = Color(0xFFF44336);
  
  /// Order status colors
  static const Color orderDraft = Color(0xFF9E9E9E);
  static const Color orderPending = Color(0xFFFFA726);
  static const Color orderConfirmed = Color(0xFF29B6F6);
  static const Color orderReceived = Color(0xFF4CAF50);
  static const Color orderCancelled = Color(0xFFF44336);
  
  // ==================== Priority Colors ====================
  static const Color priorityLow = Color(0xFF4CAF50);
  static const Color priorityMedium = Color(0xFFFFA726);
  static const Color priorityHigh = Color(0xFFFF5722);
  static const Color priorityCritical = Color(0xFFF44336);
  
  // ==================== Category Colors ====================
  /// Predefined colors for categories
  static const List<Color> categoryColors = [
    Color(0xFF2E7D32), // Green
    Color(0xFF1565C0), // Blue
    Color(0xFFE65100), // Orange
    Color(0xFF6A1B9A), // Purple
    Color(0xFFD32F2F), // Red
    Color(0xFF00838F), // Cyan
    Color(0xFF558B2F), // Light Green
    Color(0xFFC2185B), // Pink
    Color(0xFF5D4037), // Brown
    Color(0xFF37474F), // Blue Grey
  ];
  
  // ==================== Chart Colors ====================
  static const List<Color> chartColors = [
    Color(0xFF2E7D32),
    Color(0xFFFF6F00),
    Color(0xFF0288D1),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFFF5722),
  ];
  
  // ==================== Gradient Colors ====================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryLight, secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [successLight, success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningLight, warning],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorLight, error],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ==================== Shimmer Colors ====================
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF424242);
  static const Color shimmerHighlightDark = Color(0xFF616161);
  
  // ==================== Helper Methods ====================
  
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Get stock status color
  static Color getStockStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'adequate':
        return stockAdequate;
      case 'low':
        return stockLow;
      case 'critical':
        return stockCritical;
      case 'out_of_stock':
      case 'out':
        return stockOut;
      case 'overstocked':
        return stockOverstocked;
      default:
        return neutral500;
    }
  }
  
  /// Get expiry status color
  static Color getExpiryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'fresh':
        return expiryFresh;
      case 'expiring_soon':
        return expiryWarning;
      case 'expired':
        return expiryExpired;
      default:
        return neutral500;
    }
  }
  
  /// Get priority color
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return priorityLow;
      case 'medium':
        return priorityMedium;
      case 'high':
        return priorityHigh;
      case 'critical':
        return priorityCritical;
      default:
        return priorityMedium;
    }
  }
  
  /// Get category color by index
  static Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }
  
  /// Get chart color by index
  static Color getChartColor(int index) {
    return chartColors[index % chartColors.length];
  }
}
