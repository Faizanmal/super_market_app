"""
Customer App Models - Customer-facing mobile app features
Includes: Product browsing, loyalty cards, orders, reviews, recipes
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from decimal import Decimal
import uuid

User = get_user_model()


class CustomerProfile(models.Model):
    """Extended customer profile for customer app"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='customer_profile')
    phone_number = models.CharField(max_length=20, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=20, blank=True)
    preferred_store = models.ForeignKey(
        'multi_store_models.Store',
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    notification_preferences = models.JSONField(default=dict)
    dietary_preferences = models.JSONField(default=list)  # vegetarian, vegan, halal, etc.
    allergens = models.JSONField(default=list)  # nuts, dairy, gluten, etc.
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'customer_profiles'

    def __str__(self):
        return f"Customer: {self.user.email}"


class LoyaltyProgram(models.Model):
    """Loyalty program configuration"""
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    points_per_dollar = models.DecimalField(max_digits=10, decimal_places=2, default=1.0)
    redemption_rate = models.DecimalField(max_digits=10, decimal_places=4, default=0.01)  # $ per point
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'loyalty_programs'

    def __str__(self):
        return self.name


class LoyaltyCard(models.Model):
    """Customer loyalty cards"""
    TIER_CHOICES = [
        ('bronze', 'Bronze'),
        ('silver', 'Silver'),
        ('gold', 'Gold'),
        ('platinum', 'Platinum'),
        ('diamond', 'Diamond'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.OneToOneField(CustomerProfile, on_delete=models.CASCADE, related_name='loyalty_card')
    program = models.ForeignKey(LoyaltyProgram, on_delete=models.CASCADE)
    card_number = models.CharField(max_length=20, unique=True)
    barcode = models.CharField(max_length=50, unique=True)
    points_balance = models.IntegerField(default=0)
    lifetime_points = models.IntegerField(default=0)
    tier = models.CharField(max_length=20, choices=TIER_CHOICES, default='bronze')
    tier_expiry = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'loyalty_cards'

    def __str__(self):
        return f"{self.card_number} - {self.customer.user.email}"

    def earn_points(self, amount):
        """Earn points from purchase"""
        points = int(amount * self.program.points_per_dollar)
        self.points_balance += points
        self.lifetime_points += points
        self.update_tier()
        self.save()
        return points

    def redeem_points(self, points):
        """Redeem points for discount"""
        if points <= self.points_balance:
            self.points_balance -= points
            self.save()
            return Decimal(points) * self.program.redemption_rate
        return Decimal('0')

    def update_tier(self):
        """Update tier based on lifetime points"""
        if self.lifetime_points >= 100000:
            self.tier = 'diamond'
        elif self.lifetime_points >= 50000:
            self.tier = 'platinum'
        elif self.lifetime_points >= 20000:
            self.tier = 'gold'
        elif self.lifetime_points >= 5000:
            self.tier = 'silver'
        else:
            self.tier = 'bronze'


class LoyaltyTransaction(models.Model):
    """Loyalty points transactions"""
    TYPE_CHOICES = [
        ('earn', 'Earned'),
        ('redeem', 'Redeemed'),
        ('bonus', 'Bonus'),
        ('expire', 'Expired'),
        ('adjust', 'Adjustment'),
    ]

    card = models.ForeignKey(LoyaltyCard, on_delete=models.CASCADE, related_name='transactions')
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    points = models.IntegerField()
    description = models.CharField(max_length=255)
    order = models.ForeignKey('CustomerOrder', on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'loyalty_transactions'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.type}: {self.points} points"


class PersonalizedOffer(models.Model):
    """Personalized offers for customers"""
    OFFER_TYPE_CHOICES = [
        ('percentage', 'Percentage Off'),
        ('fixed', 'Fixed Amount Off'),
        ('bogo', 'Buy One Get One'),
        ('points_multiplier', 'Points Multiplier'),
        ('free_item', 'Free Item'),
    ]

    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE, related_name='offers')
    title = models.CharField(max_length=200)
    description = models.TextField()
    offer_type = models.CharField(max_length=30, choices=OFFER_TYPE_CHOICES)
    value = models.DecimalField(max_digits=10, decimal_places=2)  # % or $ based on type
    product = models.ForeignKey('Product', on_delete=models.CASCADE, null=True, blank=True)
    category = models.ForeignKey('Category', on_delete=models.CASCADE, null=True, blank=True)
    min_purchase = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    code = models.CharField(max_length=20, unique=True)
    valid_from = models.DateTimeField()
    valid_until = models.DateTimeField()
    max_uses = models.IntegerField(default=1)
    times_used = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'personalized_offers'

    def __str__(self):
        return f"{self.title} - {self.customer.user.email}"

    def is_valid(self):
        from django.utils import timezone
        now = timezone.now()
        return (
            self.is_active and
            self.valid_from <= now <= self.valid_until and
            self.times_used < self.max_uses
        )


class CustomerOrder(models.Model):
    """Customer orders for pickup/delivery"""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('preparing', 'Preparing'),
        ('ready', 'Ready for Pickup'),
        ('out_for_delivery', 'Out for Delivery'),
        ('delivered', 'Delivered'),
        ('picked_up', 'Picked Up'),
        ('cancelled', 'Cancelled'),
    ]

    ORDER_TYPE_CHOICES = [
        ('pickup', 'In-Store Pickup'),
        ('delivery', 'Home Delivery'),
        ('in_store', 'In-Store Purchase'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order_number = models.CharField(max_length=20, unique=True)
    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE, related_name='orders')
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    order_type = models.CharField(max_length=20, choices=ORDER_TYPE_CHOICES, default='pickup')
    
    # Delivery info
    delivery_address = models.TextField(blank=True)
    delivery_instructions = models.TextField(blank=True)
    scheduled_time = models.DateTimeField(null=True, blank=True)
    
    # Pricing
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    # Payment
    payment_method = models.CharField(max_length=50, blank=True)
    payment_status = models.CharField(max_length=20, default='pending')
    paid_at = models.DateTimeField(null=True, blank=True)
    
    # Loyalty
    points_earned = models.IntegerField(default=0)
    points_redeemed = models.IntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'customer_orders'
        ordering = ['-created_at']

    def __str__(self):
        return f"Order #{self.order_number}"

    def calculate_totals(self):
        """Calculate order totals"""
        self.subtotal = sum(item.total_price for item in self.items.all())
        self.total_amount = self.subtotal + self.tax_amount + self.delivery_fee - self.discount_amount
        self.save()


class OrderItem(models.Model):
    """Items in customer order"""
    order = models.ForeignKey(CustomerOrder, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey('Product', on_delete=models.CASCADE)
    quantity = models.IntegerField(validators=[MinValueValidator(1)])
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    total_price = models.DecimalField(max_digits=12, decimal_places=2)
    notes = models.TextField(blank=True)

    class Meta:
        db_table = 'order_items'

    def __str__(self):
        return f"{self.quantity}x {self.product.name}"

    def save(self, *args, **kwargs):
        self.total_price = self.quantity * self.unit_price
        super().save(*args, **kwargs)


class ProductReview(models.Model):
    """Customer product reviews"""
    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE, related_name='reviews')
    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='reviews')
    rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    title = models.CharField(max_length=200, blank=True)
    review = models.TextField(blank=True)
    is_verified_purchase = models.BooleanField(default=False)
    helpful_count = models.IntegerField(default=0)
    images = models.JSONField(default=list)  # List of image URLs
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_approved = models.BooleanField(default=True)

    class Meta:
        db_table = 'product_reviews'
        unique_together = ['customer', 'product']
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.customer.user.email} - {self.product.name}: {self.rating}★"


class Recipe(models.Model):
    """Recipe database"""
    DIFFICULTY_CHOICES = [
        ('easy', 'Easy'),
        ('medium', 'Medium'),
        ('hard', 'Hard'),
    ]

    MEAL_TYPE_CHOICES = [
        ('breakfast', 'Breakfast'),
        ('lunch', 'Lunch'),
        ('dinner', 'Dinner'),
        ('snack', 'Snack'),
        ('dessert', 'Dessert'),
    ]

    title = models.CharField(max_length=200)
    description = models.TextField()
    image_url = models.URLField(blank=True)
    video_url = models.URLField(blank=True)  # YouTube/Vimeo link
    prep_time = models.IntegerField(help_text="Preparation time in minutes")
    cook_time = models.IntegerField(help_text="Cooking time in minutes")
    servings = models.IntegerField(default=4)
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_CHOICES, default='medium')
    meal_type = models.CharField(max_length=20, choices=MEAL_TYPE_CHOICES)
    cuisine = models.CharField(max_length=50, blank=True)
    instructions = models.JSONField(default=list)  # List of steps
    nutrition_info = models.JSONField(default=dict)  # calories, protein, etc.
    tags = models.JSONField(default=list)  # vegetarian, quick, healthy, etc.
    is_featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'recipes'

    def __str__(self):
        return self.title

    @property
    def total_time(self):
        return self.prep_time + self.cook_time


class RecipeIngredient(models.Model):
    """Ingredients for recipes linked to products"""
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE, related_name='ingredients')
    product = models.ForeignKey('Product', on_delete=models.SET_NULL, null=True, blank=True)
    name = models.CharField(max_length=100)  # Fallback if no product linked
    quantity = models.CharField(max_length=50)  # "2 cups", "500g", etc.
    is_optional = models.BooleanField(default=False)
    substitutes = models.JSONField(default=list)  # Alternative ingredients

    class Meta:
        db_table = 'recipe_ingredients'

    def __str__(self):
        return f"{self.quantity} {self.name}"


class SavedRecipe(models.Model):
    """Customer's saved/favorite recipes"""
    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE, related_name='saved_recipes')
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'saved_recipes'
        unique_together = ['customer', 'recipe']

    def __str__(self):
        return f"{self.customer.user.email} - {self.recipe.title}"


class StoreAisle(models.Model):
    """Store aisle/section mapping for navigation"""
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE, related_name='aisles')
    aisle_number = models.CharField(max_length=10)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    categories = models.ManyToManyField('Category', related_name='aisles')
    floor = models.IntegerField(default=1)
    x_position = models.FloatField(default=0)  # For map positioning
    y_position = models.FloatField(default=0)
    width = models.FloatField(default=1)
    height = models.FloatField(default=1)

    class Meta:
        db_table = 'store_aisles'
        unique_together = ['store', 'aisle_number']

    def __str__(self):
        return f"{self.store.name} - Aisle {self.aisle_number}: {self.name}"


class ProductLocation(models.Model):
    """Product location within store for navigation"""
    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='locations')
    store = models.ForeignKey('multi_store_models.Store', on_delete=models.CASCADE)
    aisle = models.ForeignKey(StoreAisle, on_delete=models.CASCADE)
    shelf_number = models.CharField(max_length=10, blank=True)
    section = models.CharField(max_length=50, blank=True)  # Top, Middle, Bottom, etc.

    class Meta:
        db_table = 'product_locations'
        unique_together = ['product', 'store']

    def __str__(self):
        return f"{self.product.name} @ Aisle {self.aisle.aisle_number}"


class SocialShare(models.Model):
    """Social sharing activity tracking"""
    SHARE_TYPE_CHOICES = [
        ('recipe', 'Recipe'),
        ('shopping_list', 'Shopping List'),
        ('deal', 'Deal'),
        ('review', 'Review'),
    ]

    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE, related_name='shares')
    share_type = models.CharField(max_length=20, choices=SHARE_TYPE_CHOICES)
    content_id = models.CharField(max_length=100)
    platform = models.CharField(max_length=50)  # Facebook, Twitter, WhatsApp, etc.
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'social_shares'

    def __str__(self):
        return f"{self.customer.user.email} shared {self.share_type} on {self.platform}"


class ReferralProgram(models.Model):
    """Referral program for customer acquisition"""
    name = models.CharField(max_length=100)
    description = models.TextField()
    referrer_reward_points = models.IntegerField(default=500)
    referee_reward_points = models.IntegerField(default=250)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'referral_programs'

    def __str__(self):
        return self.name


class Referral(models.Model):
    """Customer referrals"""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('expired', 'Expired'),
    ]

    program = models.ForeignKey(ReferralProgram, on_delete=models.CASCADE)
    referrer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE, related_name='referrals_made')
    referee_email = models.EmailField()
    referee = models.ForeignKey(
        CustomerProfile, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='referred_by'
    )
    referral_code = models.CharField(max_length=20, unique=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'referrals'

    def __str__(self):
        return f"{self.referrer.user.email} -> {self.referee_email}"
