from rest_framework import serializers
from .gamification_models import GamificationProfile, Badge, UserBadge, PointTransaction
from django.contrib.auth import get_user_model

User = get_user_model()

class BadgeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Badge
        fields = '__all__'

class UserBadgeSerializer(serializers.ModelSerializer):
    badge_details = BadgeSerializer(source='badge', read_only=True)
    
    class Meta:
        model = UserBadge
        fields = ['id', 'badge', 'badge_details', 'earned_at']

class PointTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PointTransaction
        fields = '__all__'

class GamificationProfileSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    earned_badges = UserBadgeSerializer(source='user.earned_badges', many=True, read_only=True)
    recent_transactions = serializers.SerializerMethodField()
    
    class Meta:
        model = GamificationProfile
        fields = [
            'id', 'user', 'user_name', 'total_points', 'current_level', 
            'current_xp', 'xp_to_next_level', 'total_tasks_completed',
            'streak_days', 'earned_badges', 'recent_transactions'
        ]
        read_only_fields = ['user', 'total_points', 'current_level', 'current_xp']

    def get_recent_transactions(self, obj):
        # Return last 5 transactions
        qs = PointTransaction.objects.filter(user=obj.user).order_by('-created_at')[:5]
        return PointTransactionSerializer(qs, many=True).data

class LeaderboardSerializer(serializers.ModelSerializer):
    """Simplified profile for leaderboard view"""
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    badge_count = serializers.IntegerField(source='user.earned_badges.count', read_only=True)
    
    class Meta:
        model = GamificationProfile
        fields = ['user_name', 'current_level', 'total_points', 'badge_count']
