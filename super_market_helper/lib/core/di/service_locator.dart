/// Service Locator for Dependency Injection
/// Provides centralized access to app services and dependencies
class ServiceLocator {
  // Singleton instance
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Service registrations
  final Map<Type, dynamic> _services = {};

  /// Register a service
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Get a service
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    return service as T;
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  /// Unregister a service
  void unregister<T>() {
    _services.remove(T);
  }

  /// Clear all services
  void clear() {
    _services.clear();
  }
}

/// Global service locator instance
final serviceLocator = ServiceLocator();