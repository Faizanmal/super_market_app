"""
Compliance and Regulatory Models
Food safety (HACCP), allergen tracking, temperature logging
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from datetime import datetime
import uuid

User = get_user_model()


class HACCPPlan(models.Model):
    """HACCP Plan for food safety"""
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE, related_name='haccp_plans')
    name = models.CharField(max_length=200)
    version = models.CharField(max_length=20)
    effective_date = models.DateField()
    review_date = models.DateField()
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    document_url = models.URLField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'haccp_plans'

    def __str__(self):
        return f"{self.store.name} - {self.name}"


class CriticalControlPoint(models.Model):
    """Critical Control Points in HACCP"""
    haccp_plan = models.ForeignKey(HACCPPlan, on_delete=models.CASCADE, related_name='control_points')
    ccp_number = models.CharField(max_length=20)
    name = models.CharField(max_length=200)
    hazard_type = models.CharField(max_length=100)
    critical_limits = models.JSONField(default=dict)
    monitoring_procedure = models.TextField()
    corrective_action = models.TextField()
    verification_procedure = models.TextField()
    record_keeping = models.TextField()
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'critical_control_points'

    def __str__(self):
        return f"CCP {self.ccp_number}: {self.name}"


class TemperatureLog(models.Model):
    """Temperature monitoring logs"""
    STATUS_CHOICES = [
        ('normal', 'Normal'),
        ('warning', 'Warning'),
        ('critical', 'Critical'),
    ]

    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE, related_name='temp_logs')
    equipment_id = models.CharField(max_length=50)
    equipment_name = models.CharField(max_length=100)
    equipment_type = models.CharField(max_length=50)
    temperature = models.DecimalField(max_digits=5, decimal_places=2)
    unit = models.CharField(max_length=5, default='°F')
    min_threshold = models.DecimalField(max_digits=5, decimal_places=2)
    max_threshold = models.DecimalField(max_digits=5, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='normal')
    recorded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    is_automatic = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    recorded_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'temperature_logs'
        ordering = ['-recorded_at']

    def save(self, *args, **kwargs):
        if self.temperature < self.min_threshold:
            self.status = 'critical'
        elif self.temperature > self.max_threshold:
            self.status = 'critical'
        super().save(*args, **kwargs)


class AllergenInfo(models.Model):
    """Allergen information for products"""
    name = models.CharField(max_length=100, unique=True)
    icon = models.CharField(max_length=50, blank=True)
    description = models.TextField(blank=True)
    severity_level = models.CharField(max_length=20, default='high')
    is_major = models.BooleanField(default=True)

    class Meta:
        db_table = 'allergen_info'

    def __str__(self):
        return self.name


class ProductAllergen(models.Model):
    """Product-allergen relationships"""
    PRESENCE_CHOICES = [
        ('contains', 'Contains'),
        ('may_contain', 'May Contain'),
        ('free_from', 'Free From'),
    ]

    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='allergens')
    allergen = models.ForeignKey(AllergenInfo, on_delete=models.CASCADE)
    presence = models.CharField(max_length=20, choices=PRESENCE_CHOICES, default='contains')
    notes = models.TextField(blank=True)

    class Meta:
        db_table = 'product_allergens'
        unique_together = ['product', 'allergen']


class ComplianceCheck(models.Model):
    """Compliance check records"""
    CHECK_TYPE_CHOICES = [
        ('haccp', 'HACCP Audit'),
        ('health', 'Health Inspection'),
        ('safety', 'Safety Check'),
        ('quality', 'Quality Audit'),
        ('regulatory', 'Regulatory Inspection'),
    ]

    RESULT_CHOICES = [
        ('pass', 'Pass'),
        ('fail', 'Fail'),
        ('conditional', 'Conditional Pass'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE, related_name='compliance_checks')
    check_type = models.CharField(max_length=20, choices=CHECK_TYPE_CHOICES)
    inspector = models.CharField(max_length=200)
    inspection_date = models.DateField()
    result = models.CharField(max_length=20, choices=RESULT_CHOICES)
    score = models.IntegerField(null=True, blank=True, validators=[MinValueValidator(0), MaxValueValidator(100)])
    findings = models.JSONField(default=list)
    corrective_actions = models.JSONField(default=list)
    next_inspection_date = models.DateField(null=True, blank=True)
    report_url = models.URLField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'compliance_checks'
        ordering = ['-inspection_date']


class CorrectiveAction(models.Model):
    """Corrective action tracking"""
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('verified', 'Verified'),
    ]

    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]

    compliance_check = models.ForeignKey(ComplianceCheck, on_delete=models.CASCADE, related_name='actions')
    description = models.TextField()
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='assigned_actions')
    due_date = models.DateField()
    completed_date = models.DateField(null=True, blank=True)
    verification_notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'corrective_actions'


class RegulatoryDocument(models.Model):
    """Regulatory documents and certificates"""
    DOC_TYPE_CHOICES = [
        ('license', 'Business License'),
        ('permit', 'Operating Permit'),
        ('certificate', 'Certificate'),
        ('inspection', 'Inspection Report'),
    ]

    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE, related_name='regulatory_docs')
    document_type = models.CharField(max_length=20, choices=DOC_TYPE_CHOICES)
    name = models.CharField(max_length=200)
    document_number = models.CharField(max_length=100, blank=True)
    issuing_authority = models.CharField(max_length=200)
    issue_date = models.DateField()
    expiry_date = models.DateField(null=True, blank=True)
    document_url = models.URLField(blank=True)
    is_active = models.BooleanField(default=True)
    reminder_days = models.IntegerField(default=30)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'regulatory_documents'


class FoodRecall(models.Model):
    """Food recall tracking"""
    SEVERITY_CHOICES = [
        ('class_i', 'Class I - High Risk'),
        ('class_ii', 'Class II - Moderate Risk'),
        ('class_iii', 'Class III - Low Risk'),
    ]

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('resolved', 'Resolved'),
        ('monitoring', 'Monitoring'),
    ]

    recall_number = models.CharField(max_length=50, unique=True)
    product_name = models.CharField(max_length=200)
    brand = models.CharField(max_length=100)
    reason = models.TextField()
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    recall_date = models.DateField()
    affected_products = models.ManyToManyField('Product', related_name='recalls', blank=True)
    lot_numbers = models.JSONField(default=list)
    instructions = models.TextField()
    source_url = models.URLField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'food_recalls'
        ordering = ['-recall_date']
