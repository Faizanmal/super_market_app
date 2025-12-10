"""
Marketing Automation Models
Email campaigns, SMS, push notifications, and referral programs
"""

from django.db import models
from django.contrib.auth import get_user_model
from datetime import datetime
import uuid

User = get_user_model()


class Campaign(models.Model):
    """Marketing campaign"""
    TYPE_CHOICES = [
        ('email', 'Email'),
        ('sms', 'SMS'),
        ('push', 'Push Notification'),
        ('in_app', 'In-App Message'),
    ]

    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('scheduled', 'Scheduled'),
        ('running', 'Running'),
        ('paused', 'Paused'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    campaign_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    subject = models.CharField(max_length=200, blank=True)
    content = models.TextField()
    html_content = models.TextField(blank=True)
    
    target_audience = models.JSONField(default=dict)
    scheduled_at = models.DateTimeField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    # Stats
    total_recipients = models.IntegerField(default=0)
    sent_count = models.IntegerField(default=0)
    delivered_count = models.IntegerField(default=0)
    opened_count = models.IntegerField(default=0)
    clicked_count = models.IntegerField(default=0)
    converted_count = models.IntegerField(default=0)
    
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'marketing_campaigns'
        ordering = ['-created_at']

    def __str__(self):
        return self.name

    @property
    def open_rate(self):
        if self.delivered_count > 0:
            return (self.opened_count / self.delivered_count) * 100
        return 0

    @property
    def click_rate(self):
        if self.opened_count > 0:
            return (self.clicked_count / self.opened_count) * 100
        return 0


class CampaignRecipient(models.Model):
    """Campaign recipient tracking"""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('sent', 'Sent'),
        ('delivered', 'Delivered'),
        ('opened', 'Opened'),
        ('clicked', 'Clicked'),
        ('converted', 'Converted'),
        ('bounced', 'Bounced'),
        ('unsubscribed', 'Unsubscribed'),
    ]

    campaign = models.ForeignKey(Campaign, on_delete=models.CASCADE, related_name='recipients')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    sent_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    opened_at = models.DateTimeField(null=True, blank=True)
    clicked_at = models.DateTimeField(null=True, blank=True)
    converted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'campaign_recipients'
        unique_together = ['campaign', 'user']


class MessageTemplate(models.Model):
    """Reusable message templates"""
    TYPE_CHOICES = [
        ('email', 'Email'),
        ('sms', 'SMS'),
        ('push', 'Push Notification'),
    ]

    name = models.CharField(max_length=200)
    template_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    subject = models.CharField(max_length=200, blank=True)
    content = models.TextField()
    html_content = models.TextField(blank=True)
    variables = models.JSONField(default=list)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'message_templates'

    def __str__(self):
        return self.name


class ABTest(models.Model):
    """A/B testing for campaigns"""
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('running', 'Running'),
        ('completed', 'Completed'),
    ]

    name = models.CharField(max_length=200)
    campaign = models.ForeignKey(Campaign, on_delete=models.CASCADE, related_name='ab_tests')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    variant_a_content = models.TextField()
    variant_b_content = models.TextField()
    split_percentage = models.IntegerField(default=50)
    
    variant_a_sent = models.IntegerField(default=0)
    variant_a_conversions = models.IntegerField(default=0)
    variant_b_sent = models.IntegerField(default=0)
    variant_b_conversions = models.IntegerField(default=0)
    
    winner = models.CharField(max_length=1, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ab_tests'

    def determine_winner(self):
        rate_a = self.variant_a_conversions / self.variant_a_sent if self.variant_a_sent > 0 else 0
        rate_b = self.variant_b_conversions / self.variant_b_sent if self.variant_b_sent > 0 else 0
        self.winner = 'A' if rate_a > rate_b else 'B'
        return self.winner


class CustomerSegment(models.Model):
    """Customer segmentation for targeted marketing"""
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    criteria = models.JSONField(default=dict)
    is_dynamic = models.BooleanField(default=True)
    member_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'customer_segments'

    def __str__(self):
        return self.name


class SegmentMember(models.Model):
    """Segment membership"""
    segment = models.ForeignKey(CustomerSegment, on_delete=models.CASCADE, related_name='members')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    added_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'segment_members'
        unique_together = ['segment', 'user']


class NotificationPreference(models.Model):
    """User notification preferences"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='notification_preferences')
    email_enabled = models.BooleanField(default=True)
    sms_enabled = models.BooleanField(default=True)
    push_enabled = models.BooleanField(default=True)
    
    marketing_emails = models.BooleanField(default=True)
    promotional_sms = models.BooleanField(default=False)
    order_updates = models.BooleanField(default=True)
    deal_alerts = models.BooleanField(default=True)
    
    quiet_hours_start = models.TimeField(null=True, blank=True)
    quiet_hours_end = models.TimeField(null=True, blank=True)
    
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'notification_preferences'
