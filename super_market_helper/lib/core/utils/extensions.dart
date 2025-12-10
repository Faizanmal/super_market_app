/// Extension methods for common classes
/// Provides useful extensions across the app
library;

import 'dart:math';

extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Check if string is a valid email
  bool isValidEmail() {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Remove all whitespace
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }
}

extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Format as relative time
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

extension DoubleExtensions on double {
  /// Round to specified decimal places
  double roundTo(int places) {
    final mod = pow(10.0, places).toDouble();
    return (this * mod).round() / mod;
  }
}

extension IntExtensions on int {
  /// Convert to ordinal string (1st, 2nd, 3rd, etc.)
  String toOrdinal() {
    if (this % 100 == 11 || this % 100 == 12 || this % 100 == 13) {
      return '${this}th';
    }
    switch (this % 10) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }
}