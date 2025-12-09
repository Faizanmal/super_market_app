import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/product_model.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../config/constants.dart';

/// Enhanced notification service for handling:
/// - Firebase Cloud Messaging (FCM) push notifications
/// - Local notifications with custom sounds and actions
/// - Notification preferences and settings
/// - Background notification handling
/// - Rich notification content with images and actions
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

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
  String? _fcmToken;

  /// Enhanced initialization with Firebase and local notifications
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      // Request permissions
      await _requestPermissions();
      
      // Get FCM token and register with backend
      await _registerFCMToken();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      _initialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  /// Initialize local notifications with enhanced configuration
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create enhanced notification channels
    await _createNotificationChannels();
  }

  /// Create custom notification channels for different alert types
  Future<void> _createNotificationChannels() async {
    // Critical alerts channel (highest priority)
    AndroidNotificationChannel criticalChannel = AndroidNotificationChannel(
      'critical_alerts',
      'Critical Alerts',
      description: 'Critical expiry and stock alerts requiring immediate attention',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alert_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ledColor: Color.fromARGB(255, 255, 0, 0),
    );

    // High priority alerts channel
    AndroidNotificationChannel highPriorityChannel = AndroidNotificationChannel(
      'high_priority',
      'High Priority Alerts',
      description: 'High priority notifications for important events',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // General notifications channel
    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'General app notifications and updates',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Task notifications channel
    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      'task_notifications',
      'Task Notifications',
      description: 'Task assignments and reminders',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Register channels with the system
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(criticalChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highPriorityChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(taskChannel);
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Configure Firebase messaging options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request Firebase messaging permissions
    final NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permissions');
    } else {
      debugPrint('User declined or has not accepted notification permissions');
    }

    // Request local notification permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Get FCM token and register with backend
  Future<void> _registerFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');
        
        // Register token with backend
        await _apiService.registerFCMToken(_fcmToken!);
        
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      await _apiService.registerFCMToken(newToken);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
    });
  }

  /// Set up message handlers for different states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleTerminatedAppMessage(message);
      }
    });
  }

  /// Handle messages when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    
    // Show local notification for foreground messages
    await _showLocalNotification(message);
    
    // Process notification data
    final notification = _processNotificationData(message);
    if (notification != null) {
      _notificationStreamController.add(notification);
    }
    
    // Add to message stream
    _messageStreamController.add({
      'type': 'foreground',
      'message': message.toMap(),
    });
  }

  /// Handle messages when app is opened from background
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('App opened from background message: ${message.messageId}');
    
    // Process notification data
    final notification = _processNotificationData(message);
    if (notification != null) {
      _notificationStreamController.add(notification);
    }
    
    // Navigate to relevant screen based on notification type
    _handleNotificationNavigation(message.data);
    
    // Add to message stream
    _messageStreamController.add({
      'type': 'background',
      'message': message.toMap(),
    });
  }

  /// Handle messages when app is opened from terminated state
  Future<void> _handleTerminatedAppMessage(RemoteMessage message) async {
    debugPrint('App opened from terminated state: ${message.messageId}');
    
    // Process notification data
    final notification = _processNotificationData(message);
    if (notification != null) {
      _notificationStreamController.add(notification);
    }
    
    // Handle navigation after app is fully loaded
    Future.delayed(const Duration(seconds: 2), () {
      _handleNotificationNavigation(message.data);
    });
    
    // Add to message stream
    _messageStreamController.add({
      'type': 'terminated',
      'message': message.toMap(),
    });
  }

  /// Show enhanced local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    
    if (notification == null) return;

    // Determine notification channel and priority
    NotificationDetails notificationDetails;
    
    final priority = data['priority']?.toString().toLowerCase() ?? 'normal';
    final type = data['type']?.toString() ?? 'general';
    
    if (type == 'critical_expiry' || priority == 'critical') {
      notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'critical_alerts',
          'Critical Alerts',
          channelDescription: 'Critical expiry and stock alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alert_sound'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          colorized: true,
          color: Color.fromARGB(255, 255, 0, 0),
          ledColor: Color.fromARGB(255, 255, 0, 0),
          ledOnMs: 1000,
          ledOffMs: 500,
          ticker: 'Critical Alert',
          styleInformation: BigTextStyleInformation(''),
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'view',
              'View Details',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_view'),
            ),
            AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_close'),
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alert_sound.caf',
          badgeNumber: 1,
          interruptionLevel: InterruptionLevel.critical,
        ),
      );
    } else if (priority == 'high') {
      notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_priority',
          'High Priority Alerts',
          channelDescription: 'High priority notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          colorized: true,
          color: Color.fromARGB(255, 255, 152, 0),
          ticker: 'High Priority Alert',
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('view', 'View'),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );
    } else {
      notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'general_notifications',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    }

    // Show the notification
    await _notifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(data),
    );
  }

  /// Process notification data into NotificationModel
  NotificationModel? _processNotificationData(RemoteMessage message) {
    try {
      final type = message.data['type'] ?? 'general';
      final priority = message.data['priority'] ?? 'normal';
      return NotificationModel(
        id: int.tryParse(message.messageId ?? '') ?? DateTime.now().millisecondsSinceEpoch,
        notificationType: type,
        notificationTypeDisplay: type,
        priority: priority,
        priorityDisplay: priority,
        title: message.notification?.title ?? 'Notification',
        message: message.notification?.body ?? '',
        isRead: false,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error processing notification data: $e');
      return null;
    }
  }

  /// Handle notification navigation based on type
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    
    // You can implement navigation logic here based on notification type
    switch (type) {
      case 'critical_expiry':
        // Navigate to expiry alerts screen
        _messageStreamController.add({
          'action': 'navigate',
          'route': '/alerts/expiry',
          'data': data,
        });
        break;
      case 'task_assignment':
        // Navigate to tasks screen
        _messageStreamController.add({
          'action': 'navigate',
          'route': '/tasks',
          'data': data,
        });
        break;
      case 'inventory_alert':
        // Navigate to inventory screen
        _messageStreamController.add({
          'action': 'navigate',
          'route': '/inventory',
          'data': data,
        });
        break;
      default:
        // Navigate to notifications screen
        _messageStreamController.add({
          'action': 'navigate',
          'route': '/notifications',
          'data': data,
        });
    }
  }

  /// Handle notification tap events
  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isExpiryAlert = true,
  }) async {
    final channelId = isExpiryAlert
        ? AppConstants.expiryNotificationChannel
        : AppConstants.stockNotificationChannel;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      isExpiryAlert ? 'Expiry Alerts' : 'Stock Alerts',
      channelDescription: isExpiryAlert
          ? 'Notifications for products nearing expiry or expired'
          : 'Notifications for low stock or out of stock items',
      importance: isExpiryAlert ? Importance.high : Importance.defaultImportance,
      priority: isExpiryAlert ? Priority.high : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    bool isExpiryAlert = true,
  }) async {
    final channelId = isExpiryAlert
        ? AppConstants.expiryNotificationChannel
        : AppConstants.stockNotificationChannel;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      isExpiryAlert ? 'Expiry Alerts' : 'Stock Alerts',
      channelDescription: isExpiryAlert
          ? 'Notifications for products nearing expiry or expired'
          : 'Notifications for low stock or out of stock items',
      importance: isExpiryAlert ? Importance.high : Importance.defaultImportance,
      priority: isExpiryAlert ? Priority.high : Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Show expiry alert for a product
  Future<void> showExpiryAlert(Product product) async {
    final daysUntilExpiry = product.daysUntilExpiry;
    String title;
    String body;

    if (daysUntilExpiry < 0) {
      title = '⚠️ Product Expired!';
      body = '${product.name} expired ${-daysUntilExpiry} day(s) ago';
    } else if (daysUntilExpiry == 0) {
      title = '⚠️ Product Expires Today!';
      body = '${product.name} expires today';
    } else {
      title = '⏰ Product Expiring Soon';
      body = '${product.name} expires in $daysUntilExpiry day(s)';
    }

    await showNotification(
      id: product.id.hashCode,
      title: title,
      body: body,
      payload: 'expiry_${product.id}',
      isExpiryAlert: true,
    );
  }

  /// Show low stock alert for a product
  Future<void> showLowStockAlert(Product product) async {
    final title = product.quantity == 0
        ? '📦 Out of Stock!'
        : '📉 Low Stock Alert';
    final body = product.quantity == 0
        ? '${product.name} is out of stock'
        : '${product.name} is low on stock (${product.quantity} remaining)';

    await showNotification(
      id: product.id.hashCode + 1000000, // Different ID range for stock alerts
      title: title,
      body: body,
      payload: 'stock_${product.id}',
      isExpiryAlert: false,
    );
  }

  /// Schedule daily expiry check notification
  Future<void> scheduleDailyExpiryCheck(List<Product> expiringProducts) async {
    if (expiringProducts.isEmpty) return;

    // Schedule for 9 AM tomorrow
    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day + 1,
      9,
      0,
    );

    final count = expiringProducts.length;
    await scheduleNotification(
      id: 999999, // Special ID for daily summary
      title: '📅 Daily Expiry Report',
      body: '$count product(s) expiring soon. Check your inventory!',
      scheduledDate: scheduledDate,
      payload: 'daily_report',
      isExpiryAlert: true,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (_notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>() !=
        null) {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.areNotificationsEnabled() ?? false;
    }
    return true; // iOS/macOS permissions handled differently
  }
}
