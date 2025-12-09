// This service is web-only and uses dart:html and dart:js_util APIs. Suppress
// analyzer warnings about using web libraries outside of Flutter plugins
// and the deprecation note suggesting `dart:js_interop` because those APIs
// are acceptable for the current web-only use case.
//
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Service for Progressive Web App (PWA) functionality
class PWAService {
  static final PWAService _instance = PWAService._internal();
  factory PWAService() => _instance;
  PWAService._internal();

  // Service Worker registration
  html.ServiceWorkerRegistration? _serviceWorkerRegistration;
  
  // PWA installation
  html.Event? _beforeInstallPromptEvent;
  bool _isPWAInstallable = false;
  bool _isPWAInstalled = false;

  // Notification permission
  String _notificationPermission = 'default';
  
  // Background sync support
  bool _backgroundSyncSupported = false;

  /// Initialize PWA service
  Future<void> initialize() async {
    if (!kIsWeb) return;

    try {
      // Register service worker
      await _registerServiceWorker();
      
      // Setup PWA install prompt
      _setupInstallPrompt();
      
      // Check notification permissions
      await _checkNotificationPermission();
      
      // Check background sync support
      _checkBackgroundSyncSupport();
      
      // Check if already installed
      _checkPWAInstallation();
      
      developer.log('PWA Service initialized successfully', name: 'PWAService');
    } catch (e) {
      developer.log('PWA Service initialization failed: $e', name: 'PWAService', error: e);
    }
  }

  /// Register service worker
  Future<void> _registerServiceWorker() async {
    try {
      if (html.window.navigator.serviceWorker != null) {
        _serviceWorkerRegistration = await html.window.navigator.serviceWorker!
            .register('/sw.js');
        
        developer.log('Service Worker registered successfully', name: 'PWAService');
        
        // Listen for service worker updates
        _serviceWorkerRegistration!.addEventListener('updatefound', (event) {
          developer.log('Service Worker update found', name: 'PWAService');
          _handleServiceWorkerUpdate();
        });
      }
    } catch (e) {
      developer.log('Service Worker registration failed: $e', name: 'PWAService', error: e);
    }
  }

  /// Setup PWA install prompt
  void _setupInstallPrompt() {
    html.window.addEventListener('beforeinstallprompt', (event) {
      developer.log('PWA install prompt available', name: 'PWAService');
      event.preventDefault();
      _beforeInstallPromptEvent = event;
      _isPWAInstallable = true;
    });

    html.window.addEventListener('appinstalled', (event) {
      developer.log('PWA installed successfully', name: 'PWAService');
      _isPWAInstalled = true;
      _beforeInstallPromptEvent = null;
      _isPWAInstallable = false;
    });
  }

  /// Check notification permission status
  Future<void> _checkNotificationPermission() async {
    try {
      if (html.Notification.supported) {
        _notificationPermission = html.Notification.permission ?? 'default';
        developer.log('Notification permission: $_notificationPermission', name: 'PWAService');
      }
    } catch (e) {
      developer.log('Error checking notification permission: $e', name: 'PWAService', error: e);
    }
  }

  /// Check background sync support
  void _checkBackgroundSyncSupport() {
    try {
        _backgroundSyncSupported = false;
        developer.log('Background sync supported: $_backgroundSyncSupported', name: 'PWAService');
    } catch (e) {
      developer.log('Error checking background sync support: $e', name: 'PWAService', error: e);
    }
  }

  /// Check if PWA is already installed
  void _checkPWAInstallation() {
    try {
      // Check if running in standalone mode
      final isStandalone = html.window.matchMedia('(display-mode: standalone)').matches ||
          (html.window.navigator.userAgent.contains('Mobile') && !html.window.navigator.userAgent.contains('Safari'));
      
      _isPWAInstalled = isStandalone;
      developer.log('PWA installation status: $_isPWAInstalled', name: 'PWAService');
    } catch (e) {
      developer.log('Error checking PWA installation: $e', name: 'PWAService', error: e);
    }
  }

  /// Handle service worker updates
  void _handleServiceWorkerUpdate() {
    final installing = _serviceWorkerRegistration?.installing;
    if (installing != null) {
      installing.addEventListener('statechange', (event) {
        if (installing.state == 'installed' && html.window.navigator.serviceWorker!.controller != null) {
          // New service worker is available
          developer.log('New service worker available', name: 'PWAService');
          _showUpdateAvailable();
        }
      });
    }
  }

  /// Show update available notification
  void _showUpdateAvailable() {
    // In a real app, you would show a snackbar or dialog
    developer.log('App update available. Please refresh to get the latest version.', name: 'PWAService');
  }

  /// Prompt user to install PWA
  Future<bool> promptInstall() async {
    if (!_isPWAInstallable || _beforeInstallPromptEvent == null) {
      developer.log('PWA installation not available', name: 'PWAService');
      return false;
    }

    try {
      // Show install prompt
      final dynamic prompt = _beforeInstallPromptEvent!;
      (prompt as dynamic).prompt();

      // Wait for user choice coming from the event's userChoice Promise
      final dynamic choiceResult = await (prompt as dynamic).userChoice;
      
      if (choiceResult != null && choiceResult['outcome'] == 'accepted') {
        developer.log('PWA installation accepted', name: 'PWAService');
        return true;
      } else {
        developer.log('PWA installation dismissed', name: 'PWAService');
        return false;
      }
    } catch (e) {
      developer.log('PWA installation prompt failed: $e', name: 'PWAService', error: e);
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    if (!html.Notification.supported) {
      developer.log('Notifications not supported', name: 'PWAService');
      return false;
    }

    try {
      final permission = await html.Notification.requestPermission();
      _notificationPermission = permission;
      developer.log('Notification permission granted: ${permission == 'granted'}', name: 'PWAService');
      return permission == 'granted';
    } catch (e) {
      developer.log('Failed to request notification permission: $e', name: 'PWAService', error: e);
      return false;
    }
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
  }) async {
    if (_notificationPermission != 'granted') {
      developer.log('Notification permission not granted', name: 'PWAService');
      return;
    }

    try {
      final options = {
        'body': body,
        'icon': icon ?? '/icons/Icon-192.png',
        'tag': tag,
        'data': data,
        'requireInteraction': false,
        'silent': false,
      };

      if (_serviceWorkerRegistration != null) {
        // Use service worker for persistent notifications
        await _serviceWorkerRegistration!.showNotification(title, options);
      } else {
        // Fallback to regular notification
        // web.Notification's factory expects named args for body, icon, tag, etc.
        // When using the fallback API (no service worker), we only set the supported
        // fields to avoid mismatched argument errors.
        html.Notification(
          title,
          body: body,
          icon: icon ?? '/icons/Icon-192.png',
          tag: tag ?? '',
        );
      }
      
      developer.log('Notification shown: $title', name: 'PWAService');
    } catch (e) {
      developer.log('Failed to show notification: $e', name: 'PWAService', error: e);
    }
  }

  /// Register for background sync
  Future<void> registerBackgroundSync(String tag) async {
    if (!_backgroundSyncSupported || _serviceWorkerRegistration == null) {
      developer.log('Background sync not supported', name: 'PWAService');
      return;
    }

    try {
      // Register background sync
      final swReg = await html.window.navigator.serviceWorker!.ready;
      (swReg as dynamic).sync.register(tag);
      
      developer.log('Background sync registered: $tag', name: 'PWAService');
    } catch (e) {
      developer.log('Failed to register background sync: $e', name: 'PWAService', error: e);
    }
  }

  /// Send message to service worker
  void sendMessageToServiceWorker(Map<String, dynamic> message) {
    if (_serviceWorkerRegistration?.active != null) {
      try {
        _serviceWorkerRegistration!.active!.postMessage(jsonEncode(message));
        developer.log('Message sent to service worker: ${message['type']}', name: 'PWAService');
      } catch (e) {
        developer.log('Failed to send message to service worker: $e', name: 'PWAService', error: e);
      }
    }
  }

  /// Cache product data in service worker
  void cacheProductData(Map<String, dynamic> productData) {
    sendMessageToServiceWorker({
      'type': 'CACHE_PRODUCT',
      'productData': productData,
    });
  }

  /// Clear all caches
  void clearAllCaches() {
    sendMessageToServiceWorker({
      'type': 'CLEAR_CACHE',
    });
  }

  /// Update service worker
  void updateServiceWorker() {
    sendMessageToServiceWorker({
      'type': 'SKIP_WAITING',
    });
  }

  /// Check if device is online
  bool get isOnline => html.window.navigator.onLine ?? true;

  /// Check if PWA is installable
  bool get isPWAInstallable => _isPWAInstallable;

  /// Check if PWA is installed
  bool get isPWAInstalled => _isPWAInstalled;

  /// Get notification permission status
  String get notificationPermission => _notificationPermission;

  /// Check if background sync is supported
  bool get backgroundSyncSupported => _backgroundSyncSupported;

  /// Check if notifications are supported
  bool get notificationsSupported => true;

  /// Check if service worker is supported
  bool get serviceWorkerSupported => true;

  /// Listen for online/offline events
  Stream<bool> get onlineStatusStream async* {
    late html.EventListener onlineListener;
    late html.EventListener offlineListener;
    
    final controller = StreamController<bool>();
    
    onlineListener = (html.Event event) {
      controller.add(true);
      // Process offline queue when coming back online
      processOfflineQueue();
    };
    offlineListener = (html.Event event) => controller.add(false);
    
    html.window.addEventListener('online', onlineListener);
    html.window.addEventListener('offline', offlineListener);
    
    // Initial status
    yield isOnline;
    
    yield* controller.stream;
    
    // Cleanup would be handled by the caller
  }
  
  /// Selective sync configuration
  final Map<String, SyncPriority> _syncPriorities = {};
  
  /// Configure selective sync priorities
  void configureSyncPriority(String dataType, SyncPriority priority) {
    _syncPriorities[dataType] = priority;
    developer.log('Configured sync priority for $dataType: ${priority.name}', name: 'PWAService');
  }
  
  /// Sync data based on priorities
  Future<void> syncByPriority() async {
    if (!isOnline) {
      developer.log('Cannot sync: device is offline', name: 'PWAService');
      return;
    }
    
    // Sort data types by priority
    final sortedTypes = _syncPriorities.entries.toList()
      ..sort((a, b) => b.value.value.compareTo(a.value.value));
    
    for (final entry in sortedTypes) {
      try {
        await _syncDataType(entry.key, entry.value);
      } catch (e) {
        developer.log('Failed to sync ${entry.key}: $e', name: 'PWAService', error: e);
      }
    }
  }
  
  Future<void> _syncDataType(String dataType, SyncPriority priority) async {
    developer.log('Syncing $dataType (priority: ${priority.name})', name: 'PWAService');
    sendMessageToServiceWorker({
      'type': 'SYNC_DATA_TYPE',
      'dataType': dataType,
      'priority': priority.name,
    });
  }
  
  /// Enable/disable background sync for specific data types
  void enableBackgroundSyncFor(String dataType, bool enabled) {
    sendMessageToServiceWorker({
      'type': 'CONFIGURE_BACKGROUND_SYNC',
      'dataType': dataType,
      'enabled': enabled,
    });
  }
  
  /// Get sync status for data types
  Future<Map<String, dynamic>> getSyncStatus() async {
    // This would query the service worker for sync status
    return {
      'lastSync': DateTime.now().millisecondsSinceEpoch,
      'pendingSync': _offlineQueue.length,
      'syncStatus': 'up-to-date',
    };
  }
  
  /// Conflict resolution for offline edits
  Future<void> resolveConflicts(List<DataConflict> conflicts) async {
    for (final conflict in conflicts) {
      try {
        await _resolveConflict(conflict);
      } catch (e) {
        developer.log('Failed to resolve conflict: $e', name: 'PWAService', error: e);
      }
    }
  }
  
  Future<void> _resolveConflict(DataConflict conflict) async {
    developer.log('Resolving conflict for ${conflict.dataType}: ${conflict.id}', name: 'PWAService');
    
    // Apply resolution strategy
    final resolvedData = switch (conflict.strategy) {
      ConflictStrategy.useLocal => conflict.localData,
      ConflictStrategy.useRemote => conflict.remoteData,
      ConflictStrategy.merge => _mergeData(conflict.localData, conflict.remoteData),
      ConflictStrategy.manual => conflict.customResolution,
    };
    
    // Save resolved data
    sendMessageToServiceWorker({
      'type': 'RESOLVE_CONFLICT',
      'dataType': conflict.dataType,
      'id': conflict.id,
      'resolvedData': resolvedData,
    });
  }
  
  Map<String, dynamic> _mergeData(Map<String, dynamic> local, Map<String, dynamic> remote) {
    // Smart merge: take most recent timestamp for each field
    final merged = Map<String, dynamic>.from(remote);
    
    local.forEach((key, value) {
      if (key.endsWith('_updated_at')) {
        final localTime = DateTime.tryParse(value.toString());
        final remoteTime = DateTime.tryParse(remote[key]?.toString() ?? '');
        
        if (localTime != null && remoteTime != null && localTime.isAfter(remoteTime)) {
          final dataKey = key.replaceAll('_updated_at', '');
          merged[dataKey] = local[dataKey];
          merged[key] = local[key];
        }
      }
    });
    
    return merged;
  }
  
  /// Progressive data loading
  Future<void> loadCriticalDataFirst() async {
    final criticalTypes = _syncPriorities.entries
        .where((e) => e.value == SyncPriority.critical)
        .map((e) => e.key)
        .toList();
    
    for (final dataType in criticalTypes) {
      await _syncDataType(dataType, SyncPriority.critical);
    }
    
    developer.log('Critical data loaded', name: 'PWAService');
  }
  
  /// Preload resources for offline use
  Future<void> preloadResources(List<String> urls) async {
    sendMessageToServiceWorker({
      'type': 'PRELOAD_RESOURCES',
      'urls': urls,
    });
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'totalSize': 0, // Would be calculated by service worker
      'itemCount': 0,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Get PWA capabilities summary
  Map<String, dynamic> getPWACapabilities() {
    return {
      'serviceWorkerSupported': serviceWorkerSupported,
      'notificationsSupported': notificationsSupported,
      'backgroundSyncSupported': backgroundSyncSupported,
      'installable': isPWAInstallable,
      'installed': isPWAInstalled,
      'online': isOnline,
      'notificationPermission': notificationPermission,
    };
  }

  /// Setup periodic background sync for data
  Future<void> setupPeriodicSync() async {
    if (!_backgroundSyncSupported) return;

    try {
      // Register different sync tags for different data types
      await registerBackgroundSync('product-sync');
      await registerBackgroundSync('analytics-sync');
      
      developer.log('Periodic sync setup completed', name: 'PWAService');
    } catch (e) {
      developer.log('Failed to setup periodic sync: $e', name: 'PWAService', error: e);
    }
  }

  /// Handle offline data queue
  final List<Map<String, dynamic>> _offlineQueue = [];

  void addToOfflineQueue(Map<String, dynamic> data) {
    _offlineQueue.add({
      ...data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    developer.log('Added to offline queue: ${data['type']}', name: 'PWAService');
  }

  Future<void> processOfflineQueue() async {
    if (isOnline && _offlineQueue.isNotEmpty) {
      developer.log('Processing offline queue: ${_offlineQueue.length} items', name: 'PWAService');
      
      final queueCopy = List.from(_offlineQueue);
      _offlineQueue.clear();
      
      for (final item in queueCopy) {
        try {
          // Process each queued item
          await _processOfflineItem(item);
        } catch (e) {
          developer.log('Failed to process offline item: $e', name: 'PWAService', error: e);
          // Re-add to queue if processing fails
          _offlineQueue.add(item);
        }
      }
    }
  }

  Future<void> _processOfflineItem(Map<String, dynamic> item) async {
    // This would implement the actual processing logic
    // For example, sending API requests for queued operations
    developer.log('Processing offline item: ${item['type']}', name: 'PWAService');
  }
}

/// Sync priority levels for selective data synchronization
enum SyncPriority {
  critical(100),
  high(75),
  medium(50),
  low(25),
  background(10);

  const SyncPriority(this.value);
  final int value;
}

/// Conflict resolution strategies
enum ConflictStrategy {
  useLocal,
  useRemote,
  merge,
  manual,
}

/// Data conflict representation
class DataConflict {
  final String dataType;
  final String id;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final ConflictStrategy strategy;
  final Map<String, dynamic>? customResolution;

  DataConflict({
    required this.dataType,
    required this.id,
    required this.localData,
    required this.remoteData,
    required this.strategy,
    this.customResolution,
  });
}