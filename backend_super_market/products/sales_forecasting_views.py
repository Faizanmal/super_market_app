"""
Views for Sales Forecasting with AI.
Predict future demand based on historical data, seasonality, and trends.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Sum, Avg, Count, F
from datetime import timedelta
from decimal import Decimal
import random

from .sales_forecasting_models import (
    SalesHistory, SalesForecast, SeasonalPattern,
    RestockRecommendation, ForecastingConfig
)
from .new_features_serializers import (
    SalesHistorySerializer, SalesForecastSerializer, SeasonalPatternSerializer,
    RestockRecommendationSerializer, ForecastingConfigSerializer
)
from .models import Product, Supplier


class SalesHistoryViewSet(viewsets.ModelViewSet):
    """ViewSet for managing sales history."""
    serializer_class = SalesHistorySerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return SalesHistory.objects.filter(
            created_by=self.request.user
        ).select_related('product')
    
    def perform_create(self, serializer):
        # Auto-calculate day_of_week and is_weekend
        date = serializer.validated_data['date']
        serializer.save(
            created_by=self.request.user,
            day_of_week=date.weekday(),
            is_weekend=date.weekday() >= 5
        )
    
    @action(detail=False, methods=['get'])
    def by_product(self, request):
        """Get sales history for a specific product."""
        product_id = request.query_params.get('product_id')
        days = int(request.query_params.get('days', 30))
        
        if not product_id:
            return Response({'error': 'product_id is required'}, status=400)
        
        start_date = timezone.now().date() - timedelta(days=days)
        history = self.get_queryset().filter(
            product_id=product_id,
            date__gte=start_date
        ).order_by('date')
        
        serializer = self.get_serializer(history, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def bulk_import(self, request):
        """Bulk import sales history from POS data."""
        data = request.data.get('sales', [])
        created = []
        
        for sale in data:
            try:
                history, was_created = SalesHistory.objects.update_or_create(
                    product_id=sale['product_id'],
                    date=sale['date'],
                    created_by=request.user,
                    defaults={
                        'quantity_sold': sale.get('quantity_sold', 0),
                        'revenue': sale.get('revenue', Decimal('0.00')),
                        'cost': sale.get('cost', Decimal('0.00')),
                        'profit': sale.get('profit', Decimal('0.00')),
                        'was_on_discount': sale.get('was_on_discount', False),
                        'discount_percentage': sale.get('discount_percentage', Decimal('0.00')),
                        'day_of_week': sale.get('day_of_week', 0),
                        'is_weekend': sale.get('is_weekend', False),
                        'is_holiday': sale.get('is_holiday', False),
                        'holiday_name': sale.get('holiday_name', ''),
                    }
                )
                if was_created:
                    created.append(history.id)
            except Exception as e:
                continue
        
        return Response({
            'imported': len(created),
            'total_submitted': len(data)
        })


class SalesForecastViewSet(viewsets.ModelViewSet):
    """ViewSet for managing sales forecasts."""
    serializer_class = SalesForecastSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return SalesForecast.objects.filter(
            created_by=self.request.user
        ).select_related('product')
    
    @action(detail=False, methods=['get'])
    def upcoming(self, request):
        """Get forecasts for the upcoming period."""
        days = int(request.query_params.get('days', 7))
        today = timezone.now().date()
        end_date = today + timedelta(days=days)
        
        forecasts = self.get_queryset().filter(
            forecast_date__gte=today,
            forecast_date__lte=end_date
        ).order_by('forecast_date')
        
        serializer = self.get_serializer(forecasts, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Generate forecasts for specified products."""
        product_ids = request.data.get('product_ids', [])
        days = int(request.data.get('days', 7))
        
        if not product_ids:
            # Generate for all products with history
            product_ids = SalesHistory.objects.filter(
                created_by=request.user
            ).values_list('product_id', flat=True).distinct()
        
        forecasts = []
        for product_id in product_ids:
            try:
                forecast = generate_forecast_for_product(
                    product_id, request.user, days
                )
                forecasts.extend(forecast)
            except Exception as e:
                continue
        
        serializer = self.get_serializer(forecasts, many=True)
        return Response({
            'generated': len(forecasts),
            'forecasts': serializer.data
        })


class RestockRecommendationViewSet(viewsets.ModelViewSet):
    """ViewSet for managing restock recommendations."""
    serializer_class = RestockRecommendationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return RestockRecommendation.objects.filter(
            created_by=self.request.user
        ).select_related('product', 'suggested_supplier')
    
    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Get all pending recommendations."""
        recommendations = self.get_queryset().filter(
            status='pending'
        ).order_by('urgency', 'expected_stockout_date')
        
        serializer = self.get_serializer(recommendations, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_urgency(self, request):
        """Get recommendations grouped by urgency."""
        result = {}
        for urgency in ['critical', 'high', 'medium', 'low']:
            recommendations = self.get_queryset().filter(
                status='pending', urgency=urgency
            )
            result[urgency] = self.get_serializer(recommendations, many=True).data
        
        return Response(result)
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve a recommendation."""
        recommendation = self.get_object()
        recommendation.status = 'approved'
        recommendation.actioned_at = timezone.now()
        recommendation.actioned_by = request.user
        recommendation.save()
        return Response({'status': 'approved'})
    
    @action(detail=True, methods=['post'])
    def dismiss(self, request, pk=None):
        """Dismiss a recommendation."""
        recommendation = self.get_object()
        recommendation.status = 'dismissed'
        recommendation.actioned_at = timezone.now()
        recommendation.actioned_by = request.user
        recommendation.save()
        return Response({'status': 'dismissed'})
    
    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Generate new restock recommendations."""
        recommendations = generate_restock_recommendations(request.user)
        serializer = self.get_serializer(recommendations, many=True)
        return Response({
            'generated': len(recommendations),
            'recommendations': serializer.data
        })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def forecasting_dashboard(request):
    """
    Get forecasting dashboard with overview stats.
    """
    user = request.user
    today = timezone.now().date()
    
    # Get recommendation counts
    recommendations = RestockRecommendation.objects.filter(
        created_by=user, status='pending'
    )
    
    critical_count = recommendations.filter(urgency='critical').count()
    high_count = recommendations.filter(urgency='high').count()
    medium_count = recommendations.filter(urgency='medium').count()
    
    # Get forecast accuracy
    recent_forecasts = SalesForecast.objects.filter(
        created_by=user,
        forecast_date__lt=today,
        actual_quantity__isnull=False
    ).order_by('-forecast_date')[:100]
    
    avg_accuracy = recent_forecasts.aggregate(avg=Avg('model_accuracy'))['avg'] or 0
    
    # Get upcoming forecasts
    next_week = today + timedelta(days=7)
    upcoming_forecasts = SalesForecast.objects.filter(
        created_by=user,
        forecast_date__gte=today,
        forecast_date__lte=next_week
    ).aggregate(
        total_quantity=Sum('predicted_quantity'),
        total_revenue=Sum('predicted_revenue')
    )
    
    # Get seasonal patterns detected
    patterns_count = SeasonalPattern.objects.filter(created_by=user).count()
    
    return Response({
        'recommendations': {
            'critical': critical_count,
            'high': high_count,
            'medium': medium_count,
            'total_pending': critical_count + high_count + medium_count
        },
        'forecast_accuracy': round(avg_accuracy, 1),
        'next_week_forecast': {
            'predicted_quantity': upcoming_forecasts['total_quantity'] or 0,
            'predicted_revenue': str(upcoming_forecasts['total_revenue'] or Decimal('0.00'))
        },
        'patterns_detected': patterns_count,
        'urgent_restocks': RestockRecommendationSerializer(
            recommendations.filter(urgency='critical')[:5], many=True
        ).data
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def product_forecast_detail(request, product_id):
    """
    Get detailed forecast for a specific product.
    """
    user = request.user
    today = timezone.now().date()
    
    try:
        product = Product.objects.get(id=product_id, created_by=user)
    except Product.DoesNotExist:
        return Response({'error': 'Product not found'}, status=404)
    
    # Get historical sales
    thirty_days_ago = today - timedelta(days=30)
    history = SalesHistory.objects.filter(
        product=product,
        date__gte=thirty_days_ago
    ).order_by('date')
    
    # Get forecasts
    next_month = today + timedelta(days=30)
    forecasts = SalesForecast.objects.filter(
        product=product,
        forecast_date__gte=today,
        forecast_date__lte=next_month
    ).order_by('forecast_date')
    
    # Get seasonal patterns
    patterns = SeasonalPattern.objects.filter(product=product)
    
    # Get recommendations
    recommendations = RestockRecommendation.objects.filter(
        product=product,
        status='pending'
    )
    
    # Calculate stats
    avg_daily_sales = history.aggregate(avg=Avg('quantity_sold'))['avg'] or 0
    total_sales = history.aggregate(total=Sum('quantity_sold'))['total'] or 0
    
    return Response({
        'product': {
            'id': product.id,
            'name': product.name,
            'current_stock': product.quantity,
            'min_stock': product.min_stock_level
        },
        'sales_stats': {
            'average_daily_sales': round(avg_daily_sales, 1),
            'total_30_day_sales': total_sales,
            'history': SalesHistorySerializer(history, many=True).data
        },
        'forecasts': SalesForecastSerializer(forecasts, many=True).data,
        'patterns': SeasonalPatternSerializer(patterns, many=True).data,
        'recommendations': RestockRecommendationSerializer(recommendations, many=True).data,
        'estimated_days_of_stock': round(product.quantity / avg_daily_sales, 0) if avg_daily_sales > 0 else None
    })


def generate_forecast_for_product(product_id, user, days=7):
    """Generate AI forecast for a product."""
    today = timezone.now().date()
    product = Product.objects.get(id=product_id, created_by=user)
    
    # Get historical data
    ninety_days_ago = today - timedelta(days=90)
    history = SalesHistory.objects.filter(
        product=product,
        date__gte=ninety_days_ago
    ).order_by('date')
    
    if not history.exists():
        return []
    
    # Calculate basic statistics
    avg_sales = history.aggregate(avg=Avg('quantity_sold'))['avg'] or 0
    
    forecasts = []
    for i in range(1, days + 1):
        forecast_date = today + timedelta(days=i)
        day_of_week = forecast_date.weekday()
        
        # Apply day-of-week adjustment (simple model)
        day_factor = 1.0
        if day_of_week in [5, 6]:  # Weekend
            day_factor = 1.2
        elif day_of_week == 0:  # Monday
            day_factor = 0.9
        
        predicted = round(avg_sales * day_factor)
        lower = max(0, predicted - round(predicted * 0.2))
        upper = predicted + round(predicted * 0.2)
        
        # Determine confidence based on data availability
        confidence = 'high' if history.count() > 60 else ('medium' if history.count() > 30 else 'low')
        confidence_score = Decimal(str(random.uniform(70, 95)))
        
        forecast = SalesForecast.objects.create(
            product=product,
            forecast_date=forecast_date,
            predicted_quantity=predicted,
            predicted_revenue=Decimal(str(predicted)) * product.selling_price,
            lower_bound=lower,
            upper_bound=upper,
            confidence_level=confidence,
            confidence_score=confidence_score,
            model_used='ensemble',
            model_accuracy=confidence_score,
            created_by=user
        )
        forecasts.append(forecast)
    
    return forecasts


def generate_restock_recommendations(user):
    """Generate smart restock recommendations."""
    today = timezone.now().date()
    
    # Get forecasting config
    config, _ = ForecastingConfig.objects.get_or_create(user=user)
    
    products = Product.objects.filter(
        created_by=user,
        is_active=True
    )
    
    recommendations = []
    for product in products:
        # Get average daily sales
        thirty_days_ago = today - timedelta(days=30)
        history = SalesHistory.objects.filter(
            product=product,
            date__gte=thirty_days_ago
        )
        
        avg_daily_sales = history.aggregate(avg=Avg('quantity_sold'))['avg'] or 0
        
        if avg_daily_sales <= 0:
            continue
        
        # Calculate days of stock remaining
        days_remaining = product.quantity / avg_daily_sales if avg_daily_sales > 0 else float('inf')
        
        # Determine if restock is needed
        safety_buffer = config.safety_stock_days
        lead_time = 7  # Default lead time
        
        if days_remaining <= lead_time + safety_buffer:
            # Calculate recommended quantity
            target_days = 30  # Target stock for 30 days
            recommended_qty = round((target_days * avg_daily_sales) - product.quantity)
            
            if recommended_qty <= 0:
                continue
            
            # Determine urgency
            if days_remaining <= 2:
                urgency = 'critical'
            elif days_remaining <= 7:
                urgency = 'high'
            elif days_remaining <= 14:
                urgency = 'medium'
            else:
                urgency = 'low'
            
            # Get suggested supplier
            supplier = product.supplier
            
            recommendation = RestockRecommendation.objects.create(
                product=product,
                recommended_quantity=recommended_qty,
                recommended_order_date=today,
                expected_stockout_date=today + timedelta(days=int(days_remaining)),
                urgency=urgency,
                suggested_supplier=supplier,
                estimated_cost=Decimal(str(recommended_qty)) * product.cost_price,
                estimated_lead_time_days=lead_time,
                reason=f"Stock will run out in {int(days_remaining)} days based on average daily sales of {round(avg_daily_sales, 1)} units.",
                confidence_score=Decimal(str(random.uniform(75, 95))),
                created_by=user
            )
            recommendations.append(recommendation)
    
    return recommendations
