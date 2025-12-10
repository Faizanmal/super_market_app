import '../core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import '../models/gamification_model.dart';
import 'package:flutter/foundation.dart';

class GamificationService {
  final ApiClient _client = ApiClient();
  
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  /// Get current user's gamification profile
  Future<GamificationProfile?> getMyProfile() async {
    try {
      final response = await _client.get<GamificationProfile>(
        '/products/gamification/my_profile/',
        parser: (data) => GamificationProfile.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (e) {
      // Handle error or return null
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  /// Get global leaderboard
  Future<List<GamificationProfile>> getLeaderboard() async {
    try {
      final response = await _client.get<List<GamificationProfile>>(
        '/products/gamification/leaderboard/',
        parser: (data) => (data as List)
            .map((item) => GamificationProfile.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
      return response.data ?? [];
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Get available badges
  Future<List<Badge>> getBadges() async {
    try {
      final response = await _client.get<List<Badge>>(
        '/products/badges/',
        parser: (data) => (data as List)
            .map((item) => Badge.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
      return response.data ?? [];
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      return [];
    }
  }
}
