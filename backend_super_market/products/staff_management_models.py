"""
Staff Management Models - Part 1
Includes staff profiles, shifts, and time tracking
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from datetime import datetime, timedelta
from decimal import Decimal
import uuid

User = get_user_model()


class StaffProfile(models.Model):
    """Extended staff profile with employment details"""
    EMPLOYMENT_TYPE_CHOICES = [
        ('full_time', 'Full Time'),
        ('part_time', 'Part Time'),
        ('contract', 'Contract'),
        ('seasonal', 'Seasonal'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='staff_profile')
    employee_id = models.CharField(max_length=20, unique=True)
    department = models.CharField(max_length=100)
    position = models.CharField(max_length=100)
    employment_type = models.CharField(max_length=20, choices=EMPLOYMENT_TYPE_CHOICES, default='full_time')
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.SET_NULL, null=True, blank=True)
    manager = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='subordinates')
    hire_date = models.DateField()
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    phone_number = models.CharField(max_length=20, blank=True)
    emergency_contact = models.JSONField(default=dict)
    skills = models.JSONField(default=list)
    certifications = models.JSONField(default=list)
    is_active = models.BooleanField(default=True)
    home_location = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'staff_profiles'

    def __str__(self):
        return f"{self.employee_id} - {self.user.get_full_name()}"


class Shift(models.Model):
    """Shift templates and scheduled shifts"""
    SHIFT_TYPE_CHOICES = [
        ('morning', 'Morning'),
        ('afternoon', 'Afternoon'),
        ('evening', 'Evening'),
        ('night', 'Night'),
    ]

    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('confirmed', 'Confirmed'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    staff = models.ForeignKey(StaffProfile, on_delete=models.CASCADE, related_name='shifts')
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE)
    shift_type = models.CharField(max_length=20, choices=SHIFT_TYPE_CHOICES)
    date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    break_duration = models.IntegerField(default=30)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    notes = models.TextField(blank=True)
    actual_start = models.DateTimeField(null=True, blank=True)
    actual_end = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'shifts'
        ordering = ['date', 'start_time']

    def __str__(self):
        return f"{self.staff.user.get_full_name()} - {self.date}"


class TimeEntry(models.Model):
    """Time tracking entries"""
    ENTRY_TYPE_CHOICES = [
        ('clock_in', 'Clock In'),
        ('clock_out', 'Clock Out'),
        ('break_start', 'Break Start'),
        ('break_end', 'Break End'),
    ]

    staff = models.ForeignKey(StaffProfile, on_delete=models.CASCADE, related_name='time_entries')
    shift = models.ForeignKey(Shift, on_delete=models.SET_NULL, null=True, blank=True)
    entry_type = models.CharField(max_length=20, choices=ENTRY_TYPE_CHOICES)
    timestamp = models.DateTimeField()
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    is_within_geofence = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'time_entries'
        ordering = ['-timestamp']


class TimeOffRequest(models.Model):
    """Time off requests"""
    TYPE_CHOICES = [
        ('vacation', 'Vacation'),
        ('sick', 'Sick Leave'),
        ('personal', 'Personal'),
    ]

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('denied', 'Denied'),
    ]

    staff = models.ForeignKey(StaffProfile, on_delete=models.CASCADE, related_name='time_off_requests')
    request_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    start_date = models.DateField()
    end_date = models.DateField()
    reason = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'time_off_requests'
