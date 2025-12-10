"""
Views for Batch Discount Engine.
Automatically applies discounts to products nearing expiry.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Sum, F, Count
from datetime import timedelta
from decimal import Decimal

from .batch_discount_models import (
    DiscountRule, BatchDiscount, DiscountNotification, DiscountAnalytics
)
from .new_features_serializers import (
    DiscountRuleSerializer, BatchDiscountSerializer, DiscountAnalyticsSerializer
)
from .models import Product


class DiscountRuleViewSet(viewsets.ModelViewSet):
    """ViewSet for managing discount rules."""
    serializer_class = DiscountRuleSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return DiscountRule.objects.filter(created_by=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=True, methods=['post'])
    def toggle_status(self, request, pk=None):
        """Toggle rule active/paused status."""
        rule = self.get_object()
        if rule.status == 'active':
            rule.status = 'paused'
        else:
            rule.status = 'active'
        rule.save()
        return Response({'status': rule.status})
    
    @action(detail=True, methods=['post'])
    def apply_now(self, request, pk=None):
        """Manually apply this rule to eligible products."""
        rule = self.get_object()
        applied = apply_discount_rule(rule, request.user)
        return Response({
            'applied_count': len(applied),
            'products': [
                {'id': d.product.id, 'name': d.product.name, 'discount': str(d.discount_percentage)}
                for d in applied
            ]
        })


class BatchDiscountViewSet(viewsets.ModelViewSet):
    """ViewSet for managing applied discounts."""
    serializer_class = BatchDiscountSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return BatchDiscount.objects.filter(
            created_by=self.request.user
        ).select_related('product', 'rule')
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all currently active discounts."""
        now = timezone.now()
        discounts = self.get_queryset().filter(
            status='active',
            start_date__lte=now,
            end_date__gte=now
        )
        serializer = self.get_serializer(discounts, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def expiring_today(self, request):
        """Get discounts expiring today."""
        today = timezone.now().date()
        tomorrow = today + timedelta(days=1)
        discounts = self.get_queryset().filter(
            status='active',
            end_date__date=today
        )
        serializer = self.get_serializer(discounts, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel a discount."""
        discount = self.get_object()
        discount.status = 'cancelled'
        discount.save()
        return Response({'status': 'cancelled'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def discount_dashboard(request):
    """
    Get discount engine dashboard with overview stats.
    """
    user = request.user
    now = timezone.now()
    today = now.date()
    
    # Get counts
    active_discounts = BatchDiscount.objects.filter(
        created_by=user,
        status='active',
        start_date__lte=now,
        end_date__gte=now
    ).count()
    
    total_rules = DiscountRule.objects.filter(created_by=user, status='active').count()
    
    # Products eligible for discounts
    eligible_products = get_eligible_products_for_discount(user)
    
    # Calculate savings
    thirty_days_ago = today - timedelta(days=30)
    analytics = DiscountAnalytics.objects.filter(
        created_by=user,
        date__gte=thirty_days_ago
    ).aggregate(
        total_saved=Sum('waste_prevented_value'),
        total_sold=Sum('total_sold_value'),
        units_saved=Sum('waste_prevented_quantity')
    )
    
    return Response({
        'active_discounts': active_discounts,
        'active_rules': total_rules,
        'eligible_products': len(eligible_products),
        'monthly_savings': str(analytics['total_saved'] or Decimal('0.00')),
        'monthly_sales_from_discounts': str(analytics['total_sold'] or Decimal('0.00')),
        'units_saved_from_waste': analytics['units_saved'] or 0,
        'eligible_products_list': [
            {
                'id': p.id,
                'name': p.name,
                'expiry_date': p.expiry_date,
                'days_until_expiry': (p.expiry_date - today).days if p.expiry_date else None,
                'current_price': str(p.selling_price),
                'quantity': p.quantity
            }
            for p in eligible_products[:10]
        ]
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def auto_apply_discounts(request):
    """
    Automatically apply all active discount rules to eligible products.
    """
    user = request.user
    rules = DiscountRule.objects.filter(created_by=user, status='active').order_by('-priority')
    
    all_applied = []
    for rule in rules:
        applied = apply_discount_rule(rule, user)
        all_applied.extend(applied)
    
    return Response({
        'total_applied': len(all_applied),
        'discounts': BatchDiscountSerializer(all_applied, many=True).data
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def discount_analytics(request):
    """
    Get detailed discount analytics.
    """
    user = request.user
    days = int(request.query_params.get('days', 30))
    start_date = timezone.now().date() - timedelta(days=days)
    
    analytics = DiscountAnalytics.objects.filter(
        created_by=user,
        date__gte=start_date
    ).order_by('date')
    
    serializer = DiscountAnalyticsSerializer(analytics, many=True)
    
    # Calculate totals
    totals = analytics.aggregate(
        total_discounts=Sum('total_discounts_applied'),
        total_products=Sum('total_products_discounted'),
        total_original=Sum('total_original_value'),
        total_discounted=Sum('total_discounted_value'),
        total_sold=Sum('total_sold_value'),
        waste_value=Sum('waste_prevented_value'),
        waste_units=Sum('waste_prevented_quantity')
    )
    
    return Response({
        'analytics': serializer.data,
        'summary': {
            'total_discounts_applied': totals['total_discounts'] or 0,
            'total_products_discounted': totals['total_products'] or 0,
            'total_original_value': str(totals['total_original'] or Decimal('0.00')),
            'total_discounted_value': str(totals['total_discounted'] or Decimal('0.00')),
            'total_revenue_from_discounts': str(totals['total_sold'] or Decimal('0.00')),
            'waste_prevented_value': str(totals['waste_value'] or Decimal('0.00')),
            'waste_prevented_units': totals['waste_units'] or 0
        }
    })


def get_eligible_products_for_discount(user, days=None):
    """Get products eligible for automatic discounts."""
    today = timezone.now().date()
    
    if days:
        expiry_threshold = today + timedelta(days=days)
        products = Product.objects.filter(
            created_by=user,
            is_active=True,
            expiry_date__lte=expiry_threshold,
            expiry_date__gt=today,
            quantity__gt=0
        )
    else:
        # Get products matching any active rule
        rules = DiscountRule.objects.filter(created_by=user, status='active')
        products = Product.objects.none()
        
        for rule in rules:
            threshold = today + timedelta(days=rule.days_before_expiry)
            rule_products = Product.objects.filter(
                created_by=user,
                is_active=True,
                expiry_date__lte=threshold,
                expiry_date__gt=today,
                quantity__gt=0
            )
            products = products | rule_products
    
    return products.distinct().order_by('expiry_date')


def apply_discount_rule(rule, user):
    """Apply a discount rule to eligible products."""
    today = timezone.now().date()
    threshold = today + timedelta(days=rule.days_before_expiry)
    now = timezone.now()
    
    # Get eligible products
    products = Product.objects.filter(
        created_by=user,
        is_active=True,
        expiry_date__lte=threshold,
        expiry_date__gt=today,
        quantity__gt=0
    )
    
    # Filter by category/product scope
    if not rule.apply_to_all:
        if rule.categories.exists():
            products = products.filter(category__in=rule.categories.all())
        if rule.products.exists():
            products = products.filter(id__in=rule.products.values_list('id', flat=True))
    
    # Exclude already discounted products
    already_discounted = BatchDiscount.objects.filter(
        status='active',
        end_date__gte=now
    ).values_list('product_id', flat=True)
    
    products = products.exclude(id__in=already_discounted)
    
    applied = []
    for product in products:
        # Calculate discount
        if rule.discount_type == 'percentage':
            discount_pct = min(rule.discount_value, rule.max_discount_percentage)
            discounted_price = product.selling_price * (1 - discount_pct / 100)
        else:
            discount_amount = min(rule.discount_value, product.selling_price * (rule.max_discount_percentage / 100))
            discounted_price = product.selling_price - discount_amount
            discount_pct = ((product.selling_price - discounted_price) / product.selling_price) * 100
        
        # Create batch discount
        batch_discount = BatchDiscount.objects.create(
            product=product,
            rule=rule,
            original_price=product.selling_price,
            discounted_price=discounted_price,
            discount_percentage=discount_pct,
            start_date=now,
            end_date=timezone.datetime.combine(product.expiry_date, timezone.datetime.max.time()),
            quantity_at_discount=product.quantity,
            created_by=user
        )
        applied.append(batch_discount)
    
    return applied
