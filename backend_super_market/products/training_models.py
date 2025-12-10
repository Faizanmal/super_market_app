"""
Training and Performance Models
Includes training modules and performance reviews
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from decimal import Decimal
import uuid

User = get_user_model()


class TrainingModule(models.Model):
    """Training courses and modules"""
    CATEGORY_CHOICES = [
        ('onboarding', 'Onboarding'),
        ('safety', 'Safety'),
        ('customer_service', 'Customer Service'),
        ('product_knowledge', 'Product Knowledge'),
        ('compliance', 'Compliance'),
    ]

    name = models.CharField(max_length=200)
    description = models.TextField()
    category = models.CharField(max_length=30, choices=CATEGORY_CHOICES)
    duration_minutes = models.IntegerField()
    passing_score = models.IntegerField(default=80)
    is_mandatory = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    video_url = models.URLField(blank=True)
    document_url = models.URLField(blank=True)
    content = models.JSONField(default=dict)
    quiz_questions = models.JSONField(default=list)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'training_modules'

    def __str__(self):
        return self.name


class StaffTraining(models.Model):
    """Staff training progress"""
    STATUS_CHOICES = [
        ('not_started', 'Not Started'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
    ]

    staff = models.ForeignKey('StaffProfile', on_delete=models.CASCADE, related_name='trainings')
    module = models.ForeignKey(TrainingModule, on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='not_started')
    progress = models.IntegerField(default=0)
    quiz_score = models.IntegerField(null=True, blank=True)
    assigned_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    due_date = models.DateField(null=True, blank=True)

    class Meta:
        db_table = 'staff_trainings'
        unique_together = ['staff', 'module']


class PerformanceReview(models.Model):
    """Staff performance reviews"""
    REVIEW_TYPE_CHOICES = [
        ('probation', 'Probation Review'),
        ('quarterly', 'Quarterly Review'),
        ('annual', 'Annual Review'),
    ]

    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('submitted', 'Submitted'),
        ('completed', 'Completed'),
    ]

    staff = models.ForeignKey('StaffProfile', on_delete=models.CASCADE, related_name='performance_reviews')
    reviewer = models.ForeignKey('StaffProfile', on_delete=models.CASCADE, related_name='reviews_given')
    review_type = models.CharField(max_length=20, choices=REVIEW_TYPE_CHOICES)
    review_period_start = models.DateField()
    review_period_end = models.DateField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    attendance_score = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    punctuality_score = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    productivity_score = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    quality_score = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    teamwork_score = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    customer_service_score = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    
    overall_score = models.DecimalField(max_digits=3, decimal_places=2, null=True, blank=True)
    strengths = models.TextField(blank=True)
    areas_for_improvement = models.TextField(blank=True)
    goals = models.JSONField(default=list)
    reviewer_comments = models.TextField(blank=True)
    staff_comments = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'performance_reviews'
        ordering = ['-created_at']

    def calculate_overall_score(self):
        scores = [
            self.attendance_score, self.punctuality_score,
            self.productivity_score, self.quality_score,
            self.teamwork_score, self.customer_service_score,
        ]
        self.overall_score = Decimal(sum(scores)) / len(scores)
        return self.overall_score


class PayrollRecord(models.Model):
    """Staff payroll records"""
    staff = models.ForeignKey('StaffProfile', on_delete=models.CASCADE, related_name='payroll_records')
    pay_period_start = models.DateField()
    pay_period_end = models.DateField()
    regular_hours = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    overtime_hours = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    base_pay = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    overtime_pay = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    bonuses = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    deductions = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    gross_pay = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    net_pay = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    status = models.CharField(max_length=20, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'payroll_records'
        ordering = ['-pay_period_end']
