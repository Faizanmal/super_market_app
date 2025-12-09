import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SecurityRole {
  final int id;
  final String name;
  final String level;
  final String description;
  final Map<String, bool> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  SecurityRole({
    required this.id,
    required this.name,
    required this.level,
    required this.description,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SecurityRole.fromJson(Map<String, dynamic> json) {
    return SecurityRole(
      id: json['id'],
      name: json['name'],
      level: json['level'],
      description: json['description'] ?? '',
      permissions: Map<String, bool>.from(json['permissions'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'description': description,
      'permissions': permissions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SecurityAuditLog {
  final int id;
  final String eventType;
  final String riskLevel;
  final String description;
  final Map<String, dynamic>? user;
  final String? ipAddress;
  final String? endpoint;
  final String? method;
  final int? responseCode;
  final Map<String, dynamic>? contextData;
  final DateTime timestamp;

  SecurityAuditLog({
    required this.id,
    required this.eventType,
    required this.riskLevel,
    required this.description,
    this.user,
    this.ipAddress,
    this.endpoint,
    this.method,
    this.responseCode,
    this.contextData,
    required this.timestamp,
  });

  factory SecurityAuditLog.fromJson(Map<String, dynamic> json) {
    return SecurityAuditLog(
      id: json['id'],
      eventType: json['event_type'],
      riskLevel: json['risk_level'],
      description: json['description'],
      user: json['user'],
      ipAddress: json['ip_address'],
      endpoint: json['endpoint'],
      method: json['method'],
      responseCode: json['response_code'],
      contextData: json['context_data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class UserPermissions {
  final SecurityRole? role;
  final Map<String, bool> permissions;
  final bool isSuperuser;
  final bool twoFactorEnabled;
  final bool accountLocked;

  UserPermissions({
    this.role,
    required this.permissions,
    required this.isSuperuser,
    required this.twoFactorEnabled,
    required this.accountLocked,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      role: json['role'] != null ? SecurityRole.fromJson(json['role']) : null,
      permissions: Map<String, bool>.from(json['permissions'] ?? {}),
      isSuperuser: json['is_superuser'] ?? false,
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      accountLocked: json['account_locked'] ?? false,
    );
  }

  bool hasPermission(String permission) {
    if (isSuperuser) return true;
    return permissions[permission] ?? false;
  }

  bool hasAnyPermission(List<String> permissionList) {
    if (isSuperuser) return true;
    return permissionList.any((permission) => hasPermission(permission));
  }

  bool hasAllPermissions(List<String> permissionList) {
    if (isSuperuser) return true;
    return permissionList.every((permission) => hasPermission(permission));
  }
}

class SecurityDashboard {
  final Map<String, dynamic> metrics;
  final List<SecurityAuditLog> recentAlerts;
  final List<Map<String, dynamic>> roleDistribution;
  final DateTime lastUpdated;

  SecurityDashboard({
    required this.metrics,
    required this.recentAlerts,
    required this.roleDistribution,
    required this.lastUpdated,
  });

  factory SecurityDashboard.fromJson(Map<String, dynamic> json) {
    var dashboard = json['dashboard'];
    return SecurityDashboard(
      metrics: dashboard['metrics'],
      recentAlerts: (dashboard['recent_alerts'] as List)
          .map((alert) => SecurityAuditLog.fromJson(alert))
          .toList(),
      roleDistribution: List<Map<String, dynamic>>.from(dashboard['role_distribution']),
      lastUpdated: DateTime.parse(dashboard['last_updated']),
    );
  }
}

class SecurityService extends ChangeNotifier {
  static const String _baseUrl = 'http://10.0.2.2:8000/api';
  static const String _securityEndpoint = '/security';
  
  String? _authToken;
  UserPermissions? _userPermissions;
  List<SecurityRole> _roles = [];
  SecurityDashboard? _dashboard;
  
  // Getters
  UserPermissions? get userPermissions => _userPermissions;
  List<SecurityRole> get roles => _roles;
  SecurityDashboard? get dashboard => _dashboard;
  bool get isAuthenticated => _authToken != null;

  // Initialize service
  Future<void> initialize() async {
    await _loadAuthToken();
    if (isAuthenticated) {
      await loadUserPermissions();
    }
  }

  // Load auth token from storage
  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error loading auth token: $e');
    }
  }

  // Set auth token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      debugPrint('Error saving auth token: $e');
    }
    notifyListeners();
  }

  // Clear auth token
  Future<void> clearAuthToken() async {
    _authToken = null;
    _userPermissions = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      debugPrint('Error clearing auth token: $e');
    }
    notifyListeners();
  }

  // Get request headers
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // Load user permissions
  Future<void> loadUserPermissions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_securityEndpoint/permissions/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _userPermissions = UserPermissions.fromJson(data['user']);
          notifyListeners();
        }
      } else {
        throw Exception('Failed to load user permissions');
      }
    } catch (e) {
      debugPrint('Error loading user permissions: $e');
      rethrow;
    }
  }

  // Check if user has permission
  bool hasPermission(String permission) {
    return _userPermissions?.hasPermission(permission) ?? false;
  }

  // Check if user has any of the permissions
  bool hasAnyPermission(List<String> permissions) {
    return _userPermissions?.hasAnyPermission(permissions) ?? false;
  }

  // Check if user has all permissions
  bool hasAllPermissions(List<String> permissions) {
    return _userPermissions?.hasAllPermissions(permissions) ?? false;
  }

  // Load security roles
  Future<List<SecurityRole>> loadRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_securityEndpoint/roles/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _roles = (data['roles'] as List)
              .map((roleData) => SecurityRole.fromJson(roleData))
              .toList();
          notifyListeners();
          return _roles;
        }
      }
      throw Exception('Failed to load security roles');
    } catch (e) {
      debugPrint('Error loading security roles: $e');
      rethrow;
    }
  }

  // Create security role
  Future<bool> createRole({
    required String name,
    required String level,
    required String description,
    required Map<String, bool> permissions,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_securityEndpoint/roles/'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'level': level,
          'description': description,
          'permissions': permissions,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await loadRoles(); // Refresh roles list
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error creating security role: $e');
      return false;
    }
  }

  // Update security role
  Future<bool> updateRole({
    required int roleId,
    required String name,
    required String level,
    required String description,
    required Map<String, bool> permissions,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_securityEndpoint/roles/$roleId/'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'level': level,
          'description': description,
          'permissions': permissions,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await loadRoles(); // Refresh roles list
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error updating security role: $e');
      return false;
    }
  }

  // Delete security role
  Future<bool> deleteRole(int roleId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$_securityEndpoint/roles/$roleId/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await loadRoles(); // Refresh roles list
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting security role: $e');
      return false;
    }
  }

  // Load security audit logs
  Future<List<SecurityAuditLog>> loadAuditLogs({
    String? eventType,
    String? riskLevel,
    int? userId,
    String? startDate,
    String? endDate,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (eventType != null) queryParams['event_type'] = eventType;
      if (riskLevel != null) queryParams['risk_level'] = riskLevel;
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('$_baseUrl$_securityEndpoint/audit-logs/')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['logs'] as List)
              .map((logData) => SecurityAuditLog.fromJson(logData))
              .toList();
        }
      }
      throw Exception('Failed to load audit logs');
    } catch (e) {
      debugPrint('Error loading audit logs: $e');
      rethrow;
    }
  }

  // Load security dashboard
  Future<SecurityDashboard> loadDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_securityEndpoint/dashboard/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _dashboard = SecurityDashboard.fromJson(data);
          notifyListeners();
          return _dashboard!;
        }
      }
      throw Exception('Failed to load security dashboard');
    } catch (e) {
      debugPrint('Error loading security dashboard: $e');
      rethrow;
    }
  }

  // Initialize security system
  Future<bool> initializeSecuritySystem() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_securityEndpoint/initialize/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await loadRoles(); // Refresh roles list
          await loadUserPermissions(); // Refresh permissions
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error initializing security system: $e');
      return false;
    }
  }

  // Get available permissions list
  static List<String> get availablePermissions => [
    'can_create_products',
    'can_edit_products',
    'can_delete_products',
    'can_view_products',
    'can_manage_inventory',
    'can_view_analytics',
    'can_export_data',
    'can_manage_users',
    'can_view_reports',
    'can_manage_settings',
    'can_access_financial_data',
    'can_manage_suppliers',
    'can_approve_purchases',
    'can_use_ml_features',
    'can_access_raw_data',
    'can_modify_security',
  ];

  // Get permission display names
  static Map<String, String> get permissionDisplayNames => {
    'can_create_products': 'Create Products',
    'can_edit_products': 'Edit Products',
    'can_delete_products': 'Delete Products',
    'can_view_products': 'View Products',
    'can_manage_inventory': 'Manage Inventory',
    'can_view_analytics': 'View Analytics',
    'can_export_data': 'Export Data',
    'can_manage_users': 'Manage Users',
    'can_view_reports': 'View Reports',
    'can_manage_settings': 'Manage Settings',
    'can_access_financial_data': 'Access Financial Data',
    'can_manage_suppliers': 'Manage Suppliers',
    'can_approve_purchases': 'Approve Purchases',
    'can_use_ml_features': 'Use ML Features',
    'can_access_raw_data': 'Access Raw Data',
    'can_modify_security': 'Modify Security',
  };

  // Get role levels
  static List<String> get roleLevels => [
    'viewer',
    'employee', 
    'supervisor',
    'manager',
    'owner',
  ];

  // Get role level display names
  static Map<String, String> get roleLevelDisplayNames => {
    'viewer': 'Read-Only Viewer',
    'employee': 'Employee',
    'supervisor': 'Supervisor', 
    'manager': 'Store Manager',
    'owner': 'Store Owner',
  };
}