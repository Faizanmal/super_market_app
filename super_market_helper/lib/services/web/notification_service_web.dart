import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../models/notification_model.dart';

/// Web-compatible notification service without Firebase
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Notification stream controllers
  final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();
  final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams for listening to notifications
  Stream<NotificationModel> get notificationStream => _notificationStreamController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;

  // Notification settings
  bool _initialized = false;

  /// Web-compatible initialization without Firebase
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize local notifications only
      await _initializeLocalNotifications();

      // Skip Firebase initialization on web
      debugPrint('Running on web - Firebase messaging not available');

      // Set up basic message handlers (no Firebase listeners)
      _setupMessageHandlers();

      _initialized = true;
      debugPrint('NotificationService initialized successfully (web mode)');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  /// Initialize local notifications with enhanced configuration
  Future<void> _initializeLocalNotifications() async {
    // For web, we can still use local notifications
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels (web doesn't use channels but this is safe)
    await _createNotificationChannels();
  }

  /// Create notification channels (stub for web)
  Future<void> _createNotificationChannels() async {
    // Web doesn't support notification channels, but this won't cause errors
    debugPrint('Notification channels not supported on web');
  }

  /// Set up message handlers (no Firebase listeners on web)
  void _setupMessageHandlers() {
    debugPrint('Message handlers set up (no Firebase listeners on web)');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'general_notifications',
        'General Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedule local notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'scheduled_notifications',
        'Scheduled Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController.close();
    _messageStreamController.close();
  }
}