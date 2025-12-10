/// Network information utilities
/// Provides information about network connectivity and status
library;

import 'dart:io';

class NetworkInfo {
  /// Check if device is connected to the internet
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Get current network type (WiFi, Mobile, None)
  Future<String> getNetworkType() async {
    // This is a simplified implementation
    // In a real app, you might use connectivity_plus package
    if (await isConnected) {
      return 'WiFi'; // Assume WiFi for simplicity
    }
    return 'None';
  }

  /// Check if connection is fast enough for large downloads
  Future<bool> isConnectionFast() async {
    // Simplified check - in real app, measure ping or bandwidth
    return await isConnected;
  }
}