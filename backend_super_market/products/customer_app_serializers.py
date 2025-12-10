"""
Customer App Serializers
"""

from rest_framework import serializers
from .customer_app_models import (
    CustomerProfile, LoyaltyCard, LoyaltyProgram, LoyaltyTransaction,
    PersonalizedOffer, CustomerOrder, OrderItem, ProductReview,
    Recipe, RecipeIngredient, SavedRecipe, StoreAisle, ProductLocation,
    Referral, ReferralProgram
)


class CustomerProfileSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(source='user.email', read_only=True)
    full_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = CustomerProfile
        fields = [
            'id', 'email', 'full_name', 'phone_number', 'date_of_birth',
            'gender', 'notification_preferences', 'dietary_preferences',
            'allergens', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class LoyaltyCardSerializer(serializers.ModelSerializer):
    tier_display = serializers.CharField(source='get_tier_display', read_only=True)
    program_name = serializers.CharField(source='program.name', read_only=True)

    class Meta:
        model = LoyaltyCard
        fields = [
            'id', 'card_number', 'barcode', 'points_balance', 'lifetime_points',
            'tier', 'tier_display', 'tier_expiry', 'program_name', 'is_active'
        ]


class LoyaltyTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = LoyaltyTransaction
        fields = ['id', 'type', 'points', 'description', 'created_at']


class PersonalizedOfferSerializer(serializers.ModelSerializer):
    is_valid = serializers.BooleanField(source='is_valid', read_only=True)

    class Meta:
        model = PersonalizedOffer
        fields = [
            'id', 'title', 'description', 'offer_type', 'value', 'code',
            'min_purchase', 'valid_from', 'valid_until', 'max_uses',
            'times_used', 'is_valid'
        ]


class OrderItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)

    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'product_name', 'quantity', 'unit_price', 'total_price', 'notes']


class CustomerOrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = CustomerOrder
        fields = [
            'id', 'order_number', 'status', 'status_display', 'order_type',
            'delivery_address', 'delivery_instructions', 'scheduled_time',
            'subtotal', 'tax_amount', 'discount_amount', 'delivery_fee',
            'total_amount', 'payment_method', 'payment_status', 'paid_at',
            'points_earned', 'points_redeemed', 'items',
            'created_at', 'updated_at', 'completed_at'
        ]
        read_only_fields = ['id', 'order_number', 'created_at', 'updated_at']


class ProductReviewSerializer(serializers.ModelSerializer):
    customer_name = serializers.SerializerMethodField()

    class Meta:
        model = ProductReview
        fields = [
            'id', 'product', 'customer_name', 'rating', 'title', 'review',
            'is_verified_purchase', 'helpful_count', 'images', 'created_at'
        ]
        read_only_fields = ['id', 'is_verified_purchase', 'helpful_count', 'created_at']

    def get_customer_name(self, obj):
        name = obj.customer.user.get_full_name()
        if name:
            return name[0] + '***'
        return 'Anonymous'


class RecipeIngredientSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True, allow_null=True)

    class Meta:
        model = RecipeIngredient
        fields = ['id', 'product', 'product_name', 'name', 'quantity', 'is_optional', 'substitutes']


class RecipeSerializer(serializers.ModelSerializer):
    total_time = serializers.IntegerField(read_only=True)

    class Meta:
        model = Recipe
        fields = [
            'id', 'title', 'description', 'image_url', 'prep_time', 'cook_time',
            'total_time', 'servings', 'difficulty', 'meal_type', 'cuisine',
            'tags', 'is_featured'
        ]


class RecipeDetailSerializer(serializers.ModelSerializer):
    ingredients = RecipeIngredientSerializer(many=True, read_only=True)
    total_time = serializers.IntegerField(read_only=True)

    class Meta:
        model = Recipe
        fields = [
            'id', 'title', 'description', 'image_url', 'video_url',
            'prep_time', 'cook_time', 'total_time', 'servings', 'difficulty',
            'meal_type', 'cuisine', 'instructions', 'nutrition_info',
            'tags', 'is_featured', 'ingredients'
        ]


class StoreAisleSerializer(serializers.ModelSerializer):
    class Meta:
        model = StoreAisle
        fields = [
            'id', 'aisle_number', 'name', 'description', 'floor',
            'x_position', 'y_position', 'width', 'height'
        ]


class ProductLocationSerializer(serializers.ModelSerializer):
    aisle_number = serializers.CharField(source='aisle.aisle_number', read_only=True)
    aisle_name = serializers.CharField(source='aisle.name', read_only=True)

    class Meta:
        model = ProductLocation
        fields = ['product', 'store', 'aisle_number', 'aisle_name', 'shelf_number', 'section']
