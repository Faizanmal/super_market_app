from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .gamification_models import GamificationProfile, Badge, UserBadge, PointTransaction
from .gamification_serializers import (
    GamificationProfileSerializer, 
    BadgeSerializer, 
    UserBadgeSerializer,
    LeaderboardSerializer
)

class GamificationViewSet(viewsets.ModelViewSet):
    """
    Viewset for managing Gamification Profiles, but mostly read-only for clients.
    """
    queryset = GamificationProfile.objects.all()
    serializer_class = GamificationProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Users can see everyone's basic stats (for leaderboards), but full detail might be restricted
        # For now, allow viewing all, but we might want to restrict editing
        return GamificationProfile.objects.all()

    @action(detail=False, methods=['get'])
    def my_profile(self, request):
        """Get the current user's profile, create if not exists."""
        profile, created = GamificationProfile.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(profile)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def leaderboard(self, request):
        """Get global leaderboard."""
        profiles = GamificationProfile.objects.order_by('-total_points')[:20]
        serializer = LeaderboardSerializer(profiles, many=True)
        return Response(serializer.data)

class BadgeViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Viewset for viewing available badges.
    """
    queryset = Badge.objects.filter(is_active=True)
    serializer_class = BadgeSerializer
    permission_classes = [permissions.IsAuthenticated]
