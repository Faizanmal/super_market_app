/// Utility functions for formatting data
/// Provides common formatting operations for the app
library;

class Formatters {
  /// Format currency amount
  static String formatCurrency(double amount, {String currency = 'USD'}) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Format date
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format percentage
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  /// Format number with commas
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}