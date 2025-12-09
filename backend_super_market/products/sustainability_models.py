"""
Sustainability and Environmental Impact Tracking Models
Track carbon footprint, waste reduction, and environmental metrics
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from decimal import Decimal

User = get_user_model()


class SustainabilityMetrics(models.Model):
    """
    Overall sustainability metrics for a store or organization
    """
    store = models.ForeignKey('products.Store', on_delete=models.CASCADE, related_name='sustainability_metrics')
    
    # Time period
    period_start = models.DateField()
    period_end = models.DateField()
    period_type = models.CharField(max_length=20, choices=[
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
        ('yearly', 'Yearly'),
    ])
    
    # Waste metrics (in kg)
    total_waste = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    food_waste = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    packaging_waste = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    recycled_waste = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    composted_waste = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    landfill_waste = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Waste diversion rate
    waste_diversion_rate = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=0,
        help_text="% of waste diverted from landfill"
    )
    
    # Carbon footprint (in kg CO2e)
    total_carbon_footprint = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    product_carbon_footprint = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    transportation_carbon = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    energy_carbon = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    waste_carbon = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    # Energy usage (in kWh)
    total_energy_consumption = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    renewable_energy_usage = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    renewable_energy_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    
    # Water usage (in liters)
    total_water_consumption = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    water_recycled = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Packaging
    sustainable_packaging_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    plastic_reduced = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Local sourcing
    local_products_percentage = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=0,
        help_text="% of products sourced locally"
    )
    local_supplier_count = models.IntegerField(default=0)
    
    # Cost savings
    waste_reduction_savings = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    energy_savings = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Goals and targets
    waste_reduction_goal = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    carbon_reduction_goal = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    goal_achievement_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    
    # Overall sustainability score (0-100)
    sustainability_score = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    
    # Metadata
    calculated_at = models.DateTimeField(auto_now=True)
    notes = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-period_start']
        indexes = [
            models.Index(fields=['store', 'period_start']),
            models.Index(fields=['period_type', 'period_start']),
        ]
        unique_together = [['store', 'period_start', 'period_type']]
        verbose_name_plural = 'Sustainability metrics'
    
    def __str__(self):
        return f"{self.store.name} - {self.period_start} to {self.period_end}"
    
    def calculate_waste_diversion_rate(self):
        """Calculate percentage of waste diverted from landfill"""
        if self.total_waste > 0:
            diverted = self.recycled_waste + self.composted_waste
            self.waste_diversion_rate = (diverted / self.total_waste) * 100
            self.save()
    
    def calculate_sustainability_score(self):
        """Calculate overall sustainability score"""
        scores = []
        
        # Waste diversion (30%)
        scores.append(min(self.waste_diversion_rate, 100) * 0.30)
        
        # Renewable energy (25%)
        scores.append(min(self.renewable_energy_percentage, 100) * 0.25)
        
        # Local sourcing (20%)
        scores.append(min(self.local_products_percentage, 100) * 0.20)
        
        # Goal achievement (25%)
        scores.append(min(self.goal_achievement_percentage, 100) * 0.25)
        
        self.sustainability_score = Decimal(sum(scores))
        self.save()


class ProductCarbonFootprint(models.Model):
    """
    Track carbon footprint for individual products
    """
    product = models.OneToOneField('products.Product', on_delete=models.CASCADE, related_name='carbon_footprint')
    
    # Production emissions (kg CO2e)
    raw_material_emissions = models.DecimalField(max_digits=10, decimal_places=4, default=0)
    manufacturing_emissions = models.DecimalField(max_digits=10, decimal_places=4, default=0)
    packaging_emissions = models.DecimalField(max_digits=10, decimal_places=4, default=0)
    
    # Transportation emissions
    transportation_distance_km = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    transportation_method = models.CharField(max_length=50, choices=[
        ('air', 'Air Freight'),
        ('sea', 'Sea Freight'),
        ('road', 'Road Transport'),
        ('rail', 'Rail Transport'),
        ('local', 'Local Transport'),
    ], default='road')
    transportation_emissions = models.DecimalField(max_digits=10, decimal_places=4, default=0)
    
    # Total carbon footprint per unit
    total_emissions_per_unit = models.DecimalField(max_digits=10, decimal_places=4, default=0)
    
    # Category
    carbon_category = models.CharField(max_length=20, choices=[
        ('low', 'Low Carbon (<1 kg CO2e)'),
        ('medium', 'Medium Carbon (1-5 kg CO2e)'),
        ('high', 'High Carbon (5-10 kg CO2e)'),
        ('very_high', 'Very High Carbon (>10 kg CO2e)'),
    ], default='medium')
    
    # Certification
    is_carbon_neutral = models.BooleanField(default=False)
    carbon_offset_program = models.CharField(max_length=200, blank=True)
    
    # Data source
    data_source = models.CharField(max_length=20, choices=[
        ('supplier', 'Supplier Data'),
        ('calculated', 'Calculated'),
        ('database', 'Database Lookup'),
        ('certified', 'Third-party Certified'),
    ], default='calculated')
    data_quality = models.CharField(max_length=20, choices=[
        ('high', 'High Quality'),
        ('medium', 'Medium Quality'),
        ('low', 'Low Quality/Estimate'),
    ], default='medium')
    
    # Metadata
    last_updated = models.DateTimeField(auto_now=True)
    verified_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    notes = models.TextField(blank=True)
    
    class Meta:
        verbose_name_plural = 'Product carbon footprints'
    
    def __str__(self):
        return f"{self.product.name} - {self.total_emissions_per_unit} kg CO2e"
    
    def calculate_total_emissions(self):
        """Calculate total emissions per unit"""
        self.total_emissions_per_unit = (
            self.raw_material_emissions +
            self.manufacturing_emissions +
            self.packaging_emissions +
            self.transportation_emissions
        )
        
        # Categorize
        if self.total_emissions_per_unit < 1:
            self.carbon_category = 'low'
        elif self.total_emissions_per_unit < 5:
            self.carbon_category = 'medium'
        elif self.total_emissions_per_unit < 10:
            self.carbon_category = 'high'
        else:
            self.carbon_category = 'very_high'
        
        self.save()


class WasteRecord(models.Model):
    """
    Track individual waste disposal records
    """
    WASTE_TYPE_CHOICES = [
        ('food', 'Food Waste'),
        ('packaging', 'Packaging'),
        ('plastic', 'Plastic'),
        ('paper', 'Paper/Cardboard'),
        ('glass', 'Glass'),
        ('metal', 'Metal'),
        ('electronic', 'E-Waste'),
        ('organic', 'Organic'),
        ('general', 'General Waste'),
    ]
    
    DISPOSAL_METHOD_CHOICES = [
        ('landfill', 'Landfill'),
        ('recycle', 'Recycling'),
        ('compost', 'Composting'),
        ('donation', 'Donation'),
        ('animal_feed', 'Animal Feed'),
        ('energy_recovery', 'Energy Recovery'),
        ('biogas', 'Biogas Production'),
    ]
    
    # Reference
    store = models.ForeignKey('products.Store', on_delete=models.CASCADE, related_name='waste_records')
    product = models.ForeignKey('products.Product', on_delete=models.SET_NULL, null=True, blank=True, related_name='waste_records')
    # batch field removed as Batch model doesn't exist
    
    # Waste details
    waste_type = models.CharField(max_length=20, choices=WASTE_TYPE_CHOICES)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, help_text="Weight in kg")
    unit_count = models.IntegerField(null=True, blank=True, help_text="Number of items")
    
    # Financial
    monetary_value = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Disposal
    disposal_method = models.CharField(max_length=20, choices=DISPOSAL_METHOD_CHOICES)
    disposal_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    disposal_partner = models.CharField(max_length=200, blank=True)
    
    # Reason for waste
    reason = models.CharField(max_length=20, choices=[
        ('expired', 'Expired'),
        ('damaged', 'Damaged'),
        ('recall', 'Product Recall'),
        ('overstock', 'Overstock'),
        ('quality', 'Quality Issue'),
        ('customer_return', 'Customer Return'),
        ('other', 'Other'),
    ])
    reason_details = models.TextField(blank=True)
    
    # Prevention
    preventable = models.BooleanField(default=True)
    prevention_notes = models.TextField(blank=True)
    
    # Environmental impact
    carbon_impact = models.DecimalField(
        max_digits=10, 
        decimal_places=4, 
        default=0,
        help_text="Carbon footprint in kg CO2e"
    )
    
    # Photos and evidence
    photos = models.JSONField(default=list)
    
    # Tracking
    recorded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    recorded_at = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-recorded_at']
        indexes = [
            models.Index(fields=['store', 'waste_type', 'recorded_at']),
            models.Index(fields=['disposal_method']),
            models.Index(fields=['recorded_at']),
        ]
    
    def __str__(self):
        return f"{self.waste_type} - {self.quantity}kg ({self.disposal_method})"
    
    def calculate_carbon_impact(self):
        """Calculate carbon impact of waste"""
        # Rough estimates (kg CO2e per kg of waste)
        carbon_factors = {
            'landfill': {
                'food': 2.5,
                'packaging': 0.5,
                'plastic': 3.0,
                'paper': 1.2,
                'glass': 0.3,
                'metal': 0.5,
                'organic': 2.0,
                'general': 1.0,
            },
            'recycle': {
                'plastic': -1.5,  # Recycling saves emissions
                'paper': -0.8,
                'glass': -0.2,
                'metal': -0.3,
            },
            'compost': {
                'food': -0.5,
                'organic': -0.5,
            },
        }
        
        factor = carbon_factors.get(self.disposal_method, {}).get(self.waste_type, 0)
        self.carbon_impact = self.quantity * Decimal(str(factor))
        self.save()


class SustainabilityInitiative(models.Model):
    """
    Track sustainability initiatives and programs
    """
    store = models.ForeignKey('products.Store', on_delete=models.CASCADE, related_name='sustainability_initiatives')
    
    # Initiative details
    name = models.CharField(max_length=200)
    description = models.TextField()
    category = models.CharField(max_length=20, choices=[
        ('waste_reduction', 'Waste Reduction'),
        ('energy_efficiency', 'Energy Efficiency'),
        ('water_conservation', 'Water Conservation'),
        ('sustainable_sourcing', 'Sustainable Sourcing'),
        ('packaging', 'Packaging Reduction'),
        ('transportation', 'Transportation'),
        ('education', 'Education & Awareness'),
    ])
    
    # Timeline
    start_date = models.DateField()
    target_completion_date = models.DateField(null=True, blank=True)
    actual_completion_date = models.DateField(null=True, blank=True)
    
    # Status
    status = models.CharField(max_length=20, choices=[
        ('planned', 'Planned'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('on_hold', 'On Hold'),
        ('cancelled', 'Cancelled'),
    ], default='planned')
    
    # Goals
    target_waste_reduction_kg = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    target_carbon_reduction_kg = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    target_cost_savings = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Actual results
    actual_waste_reduction_kg = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    actual_carbon_reduction_kg = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    actual_cost_savings = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Investment
    budget = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    actual_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    roi_percentage = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    
    # Team
    initiative_owner = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='owned_initiatives')
    team_members = models.ManyToManyField(User, blank=True, related_name='sustainability_initiatives')
    
    # Progress tracking
    progress_percentage = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    milestones = models.JSONField(default=list)
    
    # Documentation
    documents = models.JSONField(default=list)
    photos = models.JSONField(default=list)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-start_date']
        indexes = [
            models.Index(fields=['store', 'status']),
            models.Index(fields=['category', 'status']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.store.name})"
    
    def calculate_roi(self):
        """Calculate return on investment"""
        if self.actual_cost > 0:
            net_benefit = self.actual_cost_savings - self.actual_cost
            self.roi_percentage = (net_benefit / self.actual_cost) * 100
            self.save()


class GreenSupplierRating(models.Model):
    """
    Sustainability rating for suppliers
    """
    supplier = models.OneToOneField('products.Supplier', on_delete=models.CASCADE, related_name='green_rating')
    
    # Environmental certifications
    iso14001_certified = models.BooleanField(default=False, help_text="ISO 14001 Environmental Management")
    carbon_neutral_certified = models.BooleanField(default=False)
    organic_certified = models.BooleanField(default=False)
    fair_trade_certified = models.BooleanField(default=False)
    
    # Scoring criteria (0-100 each)
    carbon_footprint_score = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    renewable_energy_score = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    waste_management_score = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    water_management_score = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    sustainable_packaging_score = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    social_responsibility_score = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    
    # Overall sustainability rating
    overall_rating = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    
    # Rating category
    rating_category = models.CharField(max_length=20, choices=[
        ('A', 'Excellent (90-100)'),
        ('B', 'Very Good (80-89)'),
        ('C', 'Good (70-79)'),
        ('D', 'Average (60-69)'),
        ('E', 'Below Average (50-59)'),
        ('F', 'Poor (<50)'),
    ])
    
    # Additional data
    carbon_emissions_per_product = models.DecimalField(max_digits=10, decimal_places=4, null=True, blank=True)
    renewable_energy_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    waste_diversion_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    
    # Transportation
    average_delivery_distance_km = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    uses_efficient_vehicles = models.BooleanField(default=False)
    
    # Tracking
    last_assessed = models.DateField()
    assessed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    next_assessment_date = models.DateField(null=True, blank=True)
    
    # Notes
    sustainability_initiatives = models.TextField(blank=True)
    improvement_areas = models.TextField(blank=True)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name_plural = 'Green supplier ratings'
    
    def __str__(self):
        return f"{self.supplier.name} - {self.rating_category}"
    
    def calculate_overall_rating(self):
        """Calculate overall sustainability rating"""
        scores = [
            self.carbon_footprint_score,
            self.renewable_energy_score,
            self.waste_management_score,
            self.water_management_score,
            self.sustainable_packaging_score,
            self.social_responsibility_score,
        ]
        
        # Add bonus points for certifications
        certification_bonus = 0
        if self.iso14001_certified:
            certification_bonus += 5
        if self.carbon_neutral_certified:
            certification_bonus += 5
        if self.organic_certified:
            certification_bonus += 3
        if self.fair_trade_certified:
            certification_bonus += 2
        
        self.overall_rating = min(sum(scores) / len(scores) + Decimal(certification_bonus), 100)
        
        # Determine category
        if self.overall_rating >= 90:
            self.rating_category = 'A'
        elif self.overall_rating >= 80:
            self.rating_category = 'B'
        elif self.overall_rating >= 70:
            self.rating_category = 'C'
        elif self.overall_rating >= 60:
            self.rating_category = 'D'
        elif self.overall_rating >= 50:
            self.rating_category = 'E'
        else:
            self.rating_category = 'F'
        
        self.save()
