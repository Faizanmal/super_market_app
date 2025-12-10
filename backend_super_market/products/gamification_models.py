from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()

class GamificationProfile(models.Model):
    """
    Profile to track user's gamification stats (XP, Level, Badges).
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='gamification_profile')
    total_points = models.IntegerField(default=0)
    current_level = models.IntegerField(default=1)
    current_xp = models.IntegerField(default=0)  # XP in current level
    xp_to_next_level = models.IntegerField(default=100) # Simple scaling: level * 100 or similar
    
    total_tasks_completed = models.IntegerField(default=0)
    streak_days = models.IntegerField(default=0)
    last_activity_date = models.DateField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.email} - Lvl {self.current_level}"
        
    def add_points(self, points):
        self.total_points += points
        self.current_xp += points
        self.check_level_up()
        self.save()
        
    def check_level_up(self):
        # Basic logic: Level N requires N * 100 XP
        required = self.current_level * 100
        while self.current_xp >= required:
            self.current_xp -= required
            self.current_level += 1
            required = self.current_level * 100
            self.xp_to_next_level = required
            # Could trigger a Level Up notification here

class Badge(models.Model):
    """
    Achievable badges for users.
    """
    CONDITION_TYPES = [
        ('tasks_completed', 'Tasks Completed'),
        ('login_streak', 'Login Streak'),
        ('scan_speed', 'Scanning Speed'),
        ('inventory_accuracy', 'Inventory Accuracy'),
        ('voice_commands', 'Voice Commands Used'),
        ('manual', 'Manual Award'),
    ]
    
    name = models.CharField(max_length=100)
    description = models.TextField()
    icon = models.CharField(max_length=50, help_text="Material Icon name")
    xp_reward = models.IntegerField(default=50)
    
    condition_type = models.CharField(max_length=50, choices=CONDITION_TYPES)
    condition_target = models.IntegerField(default=10, help_text="Value required to earn badge")
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.name

class UserBadge(models.Model):
    """
    Badges earned by users.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='earned_badges')
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE)
    earned_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'badge')
        
    def __str__(self):
        return f"{self.user.email} - {self.badge.name}"

class PointTransaction(models.Model):
    """
    Log of all point changes.
    """
    TRANSACTION_TYPES = [
        ('task', 'Task Completion'),
        ('bonus', 'Bonus'),
        ('badge', 'Badge Earned'),
        ('penalty', 'Penalty'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='point_transactions')
    points = models.IntegerField()
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    description = models.CharField(max_length=255)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.email} - {self.points} pts - {self.description}"
