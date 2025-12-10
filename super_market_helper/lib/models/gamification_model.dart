import 'package:json_annotation/json_annotation.dart';

part 'gamification_model.g.dart';

@JsonSerializable()
class GamificationProfile {
  final int? id;
  @JsonKey(name: 'user_name')
  final String? userName;
  @JsonKey(name: 'total_points')
  final int totalPoints;
  @JsonKey(name: 'current_level')
  final int currentLevel;
  @JsonKey(name: 'current_xp')
  final int currentXp;
  @JsonKey(name: 'xp_to_next_level')
  final int xpToNextLevel;
  @JsonKey(name: 'total_tasks_completed')
  final int totalTasksCompleted;
  @JsonKey(name: 'streak_days')
  final int streakDays;
  @JsonKey(name: 'earned_badges')
  final List<UserBadge> earnedBadges;
  @JsonKey(name: 'recent_transactions')
  final List<PointTransaction> recentTransactions;

  GamificationProfile({
    this.id,
    this.userName,
    this.totalPoints = 0,
    this.currentLevel = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 100,
    this.totalTasksCompleted = 0,
    this.streakDays = 0,
    this.earnedBadges = const [],
    this.recentTransactions = const [],
  });

  factory GamificationProfile.fromJson(Map<String, dynamic> json) =>
      _$GamificationProfileFromJson(json);

  Map<String, dynamic> toJson() => _$GamificationProfileToJson(this);

  // Helper for UI
  double get progressToNextLevel {
    if (xpToNextLevel == 0) return 0.0;
    return currentXp / xpToNextLevel;
  }
}

@JsonSerializable()
class Badge {
  final int? id;
  final String name;
  final String description;
  final String icon;
  @JsonKey(name: 'xp_reward')
  final int xpReward;

  Badge({
    this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.xpReward = 0,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);

  Map<String, dynamic> toJson() => _$BadgeToJson(this);
}

@JsonSerializable()
class UserBadge {
  final int? id;
  @JsonKey(name: 'badge_details')
  final Badge? badgeDetails;
  @JsonKey(name: 'earned_at')
  final DateTime? earnedAt;

  UserBadge({
    this.id,
    this.badgeDetails,
    this.earnedAt,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) =>
      _$UserBadgeFromJson(json);

  Map<String, dynamic> toJson() => _$UserBadgeToJson(this);
}

@JsonSerializable()
class PointTransaction {
  final int? id;
  final int points;
  @JsonKey(name: 'transaction_type')
  final String transactionType;
  final String description;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  PointTransaction({
    this.id,
    required this.points,
    required this.transactionType,
    required this.description,
    this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) =>
      _$PointTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$PointTransactionToJson(this);
  
  bool get isPositive => points > 0;
}
