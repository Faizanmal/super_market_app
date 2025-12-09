import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/secure_api_service.dart';

/// Provider for managing notifications with real-time updates
class NotificationProvider with ChangeNotifier {
  final SecureApiService _apiService = SecureApiService();
  
  List<NotificationModel> _notifications = [];
  NotificationSummary? _summary;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  NotificationSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Fetch all notifications
  Future<void> fetchNotifications({
    bool? isRead,
    String? notificationType,
    String? priority,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getNotifications(
        isRead: isRead,
        notificationType: notificationType,
        priority: priority,
      );
      
      if (response['success']) {
        final data = response['data'];
        final results = data['results'] ?? data;
        if (results is List) {
          _notifications = results
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        } else {
          _notifications = [];
        }
        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Fetch unread notifications only
  Future<void> fetchUnreadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getUnreadNotifications();
      
      if (response['success']) {
        final data = response['data'];
        if (data is List) {
          _notifications = data
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        } else {
          _notifications = [];
        }
        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching unread notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Fetch notification summary statistics
  Future<void> fetchSummary() async {
    try {
      final summary = await _apiService.getNotificationSummary();
      if (summary != null) {
        _summary = summary;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching notification summary: $e');
    }
  }
  
  /// Mark a single notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _apiService.markNotificationAsRead(notificationId);
      
      if (response['success']) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true, readAt: DateTime.now());
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }
  
  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.markAllNotificationsAsRead();
      
      if (response['success']) {
        // Refresh notifications
        await fetchNotifications();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }
  
  /// Delete a notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await _apiService.deleteNotification(notificationId);
      
      if (response['success']) {
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }
  
  /// Clear old notifications (older than 30 days)
  Future<bool> clearOldNotifications() async {
    try {
      final response = await _apiService.clearOldNotifications();
      
      if (response['success']) {
        await fetchNotifications();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error clearing old notifications: $e');
      return false;
    }
  }
  
  /// Get notifications by type
  List<NotificationModel> getByType(String type) {
    return _notifications.where((n) => n.notificationType == type).toList();
  }
  
  /// Get notifications by priority
  List<NotificationModel> getByPriority(String priority) {
    return _notifications.where((n) => n.priority == priority).toList();
  }
  
  /// Refresh notifications (pull-to-refresh)
  Future<void> refresh() async {
    await fetchNotifications();
    await fetchSummary();
  }
}
