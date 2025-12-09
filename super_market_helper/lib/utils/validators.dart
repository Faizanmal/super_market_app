import '../config/constants.dart';

/// Input validation utilities
/// Provides validation methods for form inputs
class Validators {
  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(AppConstants.emailPattern);
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate product name
  static String? validateProductName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Product name is required';
    }

    if (value.length < 2) {
      return 'Product name must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Product name must not exceed 100 characters';
    }

    return null;
  }

  /// Validate quantity
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid number';
    }

    if (quantity < 0) {
      return 'Quantity cannot be negative';
    }

    return null;
  }

  /// Validate price
  static String? validatePrice(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    if (price > 999999.99) {
      return 'Price is too high';
    }

    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value, {bool isRequired = false}) {
    if (!isRequired && (value == null || value.isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.isEmpty)) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(AppConstants.phonePattern);
    if (!phoneRegex.hasMatch(value!)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate barcode
  static String? validateBarcode(String? value, {bool isRequired = false}) {
    if (!isRequired && (value == null || value.isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.isEmpty)) {
      return 'Barcode is required';
    }

    final barcodeRegex = RegExp(AppConstants.barcodePattern);
    if (!barcodeRegex.hasMatch(value!)) {
      return 'Please enter a valid barcode (8-13 digits)';
    }

    return null;
  }

  /// Validate expiry date
  static String? validateExpiryDate(DateTime? value) {
    if (value == null) {
      return 'Expiry date is required';
    }

    // Check if date is too far in the past (more than 1 year)
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    if (value.isBefore(oneYearAgo)) {
      return 'Expiry date seems too old';
    }

    // Check if date is too far in the future (more than 10 years)
    final tenYearsFromNow = DateTime.now().add(const Duration(days: 3650));
    if (value.isAfter(tenYearsFromNow)) {
      return 'Expiry date seems too far in the future';
    }

    return null;
  }

  /// Validate category selection
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category';
    }

    if (!AppConstants.productCategories.contains(value)) {
      return 'Invalid category selected';
    }

    return null;
  }

  /// Validate supplier name
  static String? validateSupplier(String? value) {
    if (value == null || value.isEmpty) {
      return 'Supplier name is required';
    }

    if (value.length < 2) {
      return 'Supplier name must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Supplier name must not exceed 100 characters';
    }

    return null;
  }

  /// Validate full name
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }

    if (value.length < 2) {
      return 'Full name must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Full name must not exceed 100 characters';
    }

    // Check if name contains at least one space (first and last name)
    if (!value.contains(' ')) {
      return 'Please enter your full name (first and last name)';
    }

    return null;
  }

  /// Validate number range
  static String? validateNumberRange(
    String? value,
    String fieldName, {
    required double min,
    required double max,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }

    return null;
  }

  /// Validate text length
  static String? validateTextLength(
    String? value,
    String fieldName, {
    int? minLength,
    int? maxLength,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (minLength != null && value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }

  /// Validate alphanumeric
  static String? validateAlphanumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumericRegex.hasMatch(value)) {
      return '$fieldName must contain only letters and numbers';
    }

    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value, {bool isRequired = false}) {
    if (!isRequired && (value == null || value.isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.isEmpty)) {
      return 'URL is required';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value!)) {
      return 'Please enter a valid URL';
    }

    return null;
  }
}
