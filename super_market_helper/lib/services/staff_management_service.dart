/// Staff Management Service
/// Handles shifts, time tracking, training, and performance

import 'api_service.dart';

/// Staff Profile
class StaffProfile {
  final String id;
  final String employeeId;
  final String department;
  final String position;
  final String? hireDate;

  StaffProfile({
    required this.id,
    required this.employeeId,
    required this.department,
    required this.position,
    this.hireDate,
  });

  factory StaffProfile.fromJson(Map<String, dynamic> json) {
    return StaffProfile(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id'] ?? '',
      department: json['department'] ?? '',
      position: json['position'] ?? '',
      hireDate: json['hire_date'],
    );
  }
}

/// Shift
class Shift {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String shiftType;
  final String status;
  final String? staffName;

  Shift({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shiftType,
    required this.status,
    this.staffName,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id']?.toString() ?? '',
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      shiftType: json['shift_type'] ?? '',
      status: json['status'] ?? '',
      staffName: json['staff_name'],
    );
  }

  String get displayTime => '$startTime - $endTime';
}

/// Training Module
class TrainingModule {
  final String id;
  final String name;
  final String description;
  final String category;
  final int durationMinutes;
  final bool isMandatory;
  final String? status;
  final int? progress;
  final int? score;
  final String? dueDate;

  TrainingModule({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.durationMinutes,
    required this.isMandatory,
    this.status,
    this.progress,
    this.score,
    this.dueDate,
  });

  factory TrainingModule.fromJson(Map<String, dynamic> json) {
    return TrainingModule(
      id: json['id']?.toString() ?? json['module_id']?.toString() ?? '',
      name: json['name'] ?? json['module_name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      durationMinutes: json['duration'] ?? json['duration_minutes'] ?? 0,
      isMandatory: json['is_mandatory'] ?? false,
      status: json['status'],
      progress: json['progress'],
      score: json['score'] ?? json['quiz_score'],
      dueDate: json['due_date'],
    );
  }
}

/// Performance Review
class PerformanceReview {
  final String id;
  final String type;
  final String period;
  final double? overallScore;
  final String status;

  PerformanceReview({
    required this.id,
    required this.type,
    required this.period,
    this.overallScore,
    required this.status,
  });

  factory PerformanceReview.fromJson(Map<String, dynamic> json) {
    return PerformanceReview(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      period: json['period'] ?? '',
      overallScore: json['overall_score']?.toDouble(),
      status: json['status'] ?? '',
    );
  }
}

/// Payroll Record
class PayrollRecord {
  final String period;
  final double regularHours;
  final double overtimeHours;
  final double grossPay;
  final double netPay;
  final String status;

  PayrollRecord({
    required this.period,
    required this.regularHours,
    required this.overtimeHours,
    required this.grossPay,
    required this.netPay,
    required this.status,
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    return PayrollRecord(
      period: json['period'] ?? '',
      regularHours: (json['regular_hours'] ?? 0).toDouble(),
      overtimeHours: (json['overtime_hours'] ?? 0).toDouble(),
      grossPay: (json['gross_pay'] ?? 0).toDouble(),
      netPay: (json['net_pay'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

/// Staff Management Service
class StaffManagementService {
  final ApiService _apiService;

  StaffManagementService(this._apiService);

  // === Profile ===
  Future<StaffProfile?> getMyProfile() async {
    try {
      final response = await _apiService.get('/api/staff/profiles/me/');
      return StaffProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // === Shifts ===
  Future<List<Shift>> getMyShifts() async {
    try {
      final response = await _apiService.get('/api/staff/shifts/my_shifts/');
      return (response as List).map((s) => Shift.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Shift>> getWeeklySchedule({String? storeId, String? startDate}) async {
    try {
      final response = await _apiService.get('/api/staff/shifts/schedule/', queryParams: {
        if (storeId != null) 'store_id': storeId,
        if (startDate != null) 'start_date': startDate,
      });
      return (response as List).map((s) => Shift.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  // === Time Tracking ===
  Future<Map<String, dynamic>> getClockStatus() async {
    try {
      final response = await _apiService.get('/api/staff/time/status/');
      return response;
    } catch (e) {
      return {'clocked_in': false};
    }
  }

  Future<Map<String, dynamic>> clockIn({double? latitude, double? longitude}) async {
    final response = await _apiService.post('/api/staff/time/clock_in/', body: {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return response;
  }

  Future<Map<String, dynamic>> clockOut({double? latitude, double? longitude}) async {
    final response = await _apiService.post('/api/staff/time/clock_out/', body: {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return response;
  }

  // === Time Off ===
  Future<void> requestTimeOff({
    required String type,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    await _apiService.post('/api/staff/time-off/', body: {
      'request_type': type,
      'start_date': startDate,
      'end_date': endDate,
      if (reason != null) 'reason': reason,
    });
  }

  Future<List<Map<String, dynamic>>> getTimeOffRequests() async {
    try {
      final response = await _apiService.get('/api/staff/time-off/');
      final list = response is List ? response : response['results'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return [];
    }
  }

  // === Training ===
  Future<List<TrainingModule>> getTrainingModules() async {
    try {
      final response = await _apiService.get('/api/staff/training/modules/');
      return (response as List).map((m) => TrainingModule.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TrainingModule>> getMyTraining() async {
    try {
      final response = await _apiService.get('/api/staff/training/my_training/');
      return (response as List).map((m) => TrainingModule.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> startTraining(String moduleId) async {
    await _apiService.post('/api/staff/training/$moduleId/start/', body: {});
  }

  // === Performance ===
  Future<List<PerformanceReview>> getMyReviews() async {
    try {
      final response = await _apiService.get('/api/staff/performance/my_reviews/');
      return (response as List).map((r) => PerformanceReview.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  // === Payroll ===
  Future<List<PayrollRecord>> getMyPayroll() async {
    try {
      final response = await _apiService.get('/api/staff/payroll/my_payroll/');
      return (response as List).map((p) => PayrollRecord.fromJson(p)).toList();
    } catch (e) {
      return [];
    }
  }
}
