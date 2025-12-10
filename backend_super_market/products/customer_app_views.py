"""
Customer App API Views
Handles customer-facing features like orders, reviews, recipes, loyalty
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, Avg, Count
from django.utils import timezone
from .customer_app_models import (
    CustomerProfile, LoyaltyCard, LoyaltyTransaction, PersonalizedOffer,
    CustomerOrder, OrderItem, ProductReview, Recipe, RecipeIngredient,
    SavedRecipe, StoreAisle, ProductLocation, Referral, ReferralProgram
)
from .customer_app_serializers import (
    CustomerProfileSerializer, LoyaltyCardSerializer, PersonalizedOfferSerializer,
    CustomerOrderSerializer, OrderItemSerializer, ProductReviewSerializer,
    RecipeSerializer, RecipeDetailSerializer, StoreAisleSerializer
)


class CustomerProfileViewSet(viewsets.ModelViewSet):
    """Customer profile management"""
    serializer_class = CustomerProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return CustomerProfile.objects.filter(user=self.request.user)

    @action(detail=False, methods=['get'])
    def me(self, request):
        """Get current customer profile"""
        profile, created = CustomerProfile.objects.get_or_create(
            user=request.user,
            defaults={'notification_preferences': {}, 'dietary_preferences': [], 'allergens': []}
        )
        serializer = self.get_serializer(profile)
        return Response(serializer.data)


class LoyaltyViewSet(viewsets.ViewSet):
    """Loyalty program management"""
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def card(self, request):
        """Get loyalty card info"""
        try:
            profile = CustomerProfile.objects.get(user=request.user)
            card = LoyaltyCard.objects.get(customer=profile)
            return Response({
                'card_number': card.card_number,
                'barcode': card.barcode,
                'points_balance': card.points_balance,
                'lifetime_points': card.lifetime_points,
                'tier': card.tier,
                'tier_display': card.get_tier_display(),
            })
        except (CustomerProfile.DoesNotExist, LoyaltyCard.DoesNotExist):
            return Response({'error': 'No loyalty card found'}, status=404)

    @action(detail=False, methods=['get'])
    def transactions(self, request):
        """Get loyalty transaction history"""
        try:
            profile = CustomerProfile.objects.get(user=request.user)
            card = LoyaltyCard.objects.get(customer=profile)
            transactions = LoyaltyTransaction.objects.filter(card=card)[:50]
            return Response([{
                'type': t.type,
                'points': t.points,
                'description': t.description,
                'date': t.created_at.isoformat()
            } for t in transactions])
        except:
            return Response([])

    @action(detail=False, methods=['post'])
    def redeem(self, request):
        """Redeem points for discount"""
        points = request.data.get('points', 0)
        try:
            profile = CustomerProfile.objects.get(user=request.user)
            card = LoyaltyCard.objects.get(customer=profile)
            discount = card.redeem_points(int(points))
            if discount > 0:
                LoyaltyTransaction.objects.create(
                    card=card, type='redeem', points=-int(points),
                    description=f'Redeemed for ${discount:.2f} discount'
                )
                return Response({'discount': float(discount), 'remaining_points': card.points_balance})
            return Response({'error': 'Insufficient points'}, status=400)
        except:
            return Response({'error': 'Failed to redeem'}, status=400)


class OffersViewSet(viewsets.ReadOnlyModelViewSet):
    """Personalized offers"""
    serializer_class = PersonalizedOfferSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CustomerProfile.objects.get(user=self.request.user)
            now = timezone.now()
            return PersonalizedOffer.objects.filter(
                customer=profile, is_active=True,
                valid_from__lte=now, valid_until__gte=now
            )
        except CustomerProfile.DoesNotExist:
            return PersonalizedOffer.objects.none()


class CustomerOrderViewSet(viewsets.ModelViewSet):
    """Customer order management"""
    serializer_class = CustomerOrderSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        try:
            profile = CustomerProfile.objects.get(user=self.request.user)
            return CustomerOrder.objects.filter(customer=profile)
        except CustomerProfile.DoesNotExist:
            return CustomerOrder.objects.none()

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel an order"""
        order = self.get_object()
        if order.status in ['pending', 'confirmed']:
            order.status = 'cancelled'
            order.save()
            return Response({'status': 'cancelled'})
        return Response({'error': 'Cannot cancel order in current status'}, status=400)


class ProductReviewViewSet(viewsets.ModelViewSet):
    """Product reviews"""
    serializer_class = ProductReviewSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        product_id = self.request.query_params.get('product_id')
        if product_id:
            return ProductReview.objects.filter(product_id=product_id, is_approved=True)
        try:
            profile = CustomerProfile.objects.get(user=self.request.user)
            return ProductReview.objects.filter(customer=profile)
        except:
            return ProductReview.objects.none()

    def perform_create(self, serializer):
        profile = CustomerProfile.objects.get(user=self.request.user)
        serializer.save(customer=profile)


class RecipeViewSet(viewsets.ReadOnlyModelViewSet):
    """Recipe browsing and search"""
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return RecipeDetailSerializer
        return RecipeSerializer

    def get_queryset(self):
        queryset = Recipe.objects.all()
        meal_type = self.request.query_params.get('meal_type')
        difficulty = self.request.query_params.get('difficulty')
        search = self.request.query_params.get('search')

        if meal_type:
            queryset = queryset.filter(meal_type=meal_type)
        if difficulty:
            queryset = queryset.filter(difficulty=difficulty)
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(description__icontains=search)
            )
        return queryset

    @action(detail=True, methods=['post'])
    def save(self, request, pk=None):
        """Save recipe to favorites"""
        recipe = self.get_object()
        profile = CustomerProfile.objects.get(user=request.user)
        SavedRecipe.objects.get_or_create(customer=profile, recipe=recipe)
        return Response({'saved': True})

    @action(detail=False, methods=['get'])
    def saved(self, request):
        """Get saved recipes"""
        profile = CustomerProfile.objects.get(user=request.user)
        saved = SavedRecipe.objects.filter(customer=profile).select_related('recipe')
        recipes = [s.recipe for s in saved]
        serializer = RecipeSerializer(recipes, many=True)
        return Response(serializer.data)


class StoreNavigationViewSet(viewsets.ViewSet):
    """Store navigation and product location"""
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def aisles(self, request):
        """Get store aisles"""
        store_id = request.query_params.get('store_id')
        if not store_id:
            return Response({'error': 'store_id required'}, status=400)
        aisles = StoreAisle.objects.filter(store_id=store_id)
        return Response(StoreAisleSerializer(aisles, many=True).data)

    @action(detail=False, methods=['get'])
    def find_product(self, request):
        """Find product location in store"""
        product_id = request.query_params.get('product_id')
        store_id = request.query_params.get('store_id')
        if not product_id or not store_id:
            return Response({'error': 'product_id and store_id required'}, status=400)
        
        try:
            location = ProductLocation.objects.select_related('aisle').get(
                product_id=product_id, store_id=store_id
            )
            return Response({
                'aisle_number': location.aisle.aisle_number,
                'aisle_name': location.aisle.name,
                'shelf': location.shelf_number,
                'section': location.section,
                'x': location.aisle.x_position,
                'y': location.aisle.y_position,
            })
        except ProductLocation.DoesNotExist:
            return Response({'error': 'Product location not found'}, status=404)


class ReferralViewSet(viewsets.ViewSet):
    """Referral program management"""
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def code(self, request):
        """Get user's referral code"""
        profile = CustomerProfile.objects.get(user=request.user)
        program = ReferralProgram.objects.filter(is_active=True).first()
        if not program:
            return Response({'error': 'No active referral program'}, status=404)
        
        import hashlib
        code = hashlib.md5(f"{request.user.id}-{program.id}".encode()).hexdigest()[:8].upper()
        return Response({
            'code': code,
            'url': f'https://app.supermart.com/refer/{code}',
            'reward_points': program.referrer_reward_points,
        })

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get referral statistics"""
        profile = CustomerProfile.objects.get(user=request.user)
        referrals = Referral.objects.filter(referrer=profile)
        return Response({
            'total_referrals': referrals.count(),
            'completed': referrals.filter(status='completed').count(),
            'pending': referrals.filter(status='pending').count(),
        })
