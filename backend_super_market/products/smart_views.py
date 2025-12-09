"""
Smart features and AI-powered analytics views.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import (
    Product, ShoppingList, ShoppingListItem, PurchaseOrder, 
    ProductFavorite, Store, ProductReview
)
from .serializers import (
    ShoppingListSerializer, ShoppingListItemSerializer,
    PurchaseOrderSerializer, ProductFavoriteSerializer, StoreSerializer, ProductReviewSerializer
)
from .ml_models import DemandForecast, ProfitAnalyzer, SmartAlerts

class SmartAnalyticsViewSet(viewsets.ViewSet):
    """Smart analytics and AI-powered insights."""
    
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def demand_forecast(self, request):
        """Get demand forecast and reorder recommendations."""
        user = request.user
        products = Product.objects.filter(created_by=user, is_deleted=False)
        
        forecasts = []
        for product in products:
            reorder_date, reorder_qty = DemandForecast.predict_reorder_date(product)
            if reorder_date:
                forecasts.append({
                    'product_id': product.id,
                    'product_name': product.name,
                    'current_stock': product.quantity,
                    'predicted_reorder_date': reorder_date,
                    'recommended_quantity': reorder_qty,
                    'days_until_reorder': (reorder_date - timezone.now()).days
                })
        
        # Sort by urgency
        forecasts.sort(key=lambda x: x['days_until_reorder'])
        
        return Response({
            'forecasts': forecasts,
            'total_products': len(forecasts)
        })
    
    @action(detail=False, methods=['get'])
    def trending_products(self, request):
        """Get trending products based on consumption rate."""
        days = int(request.query_params.get('days', 7))
        limit = int(request.query_params.get('limit', 10))
        
        trending = DemandForecast.get_trending_products(request.user, days, limit)
        
        from .serializers import ProductSerializer
        serializer = ProductSerializer(trending, many=True)
        
        return Response({
            'trending_products': serializer.data,
            'period_days': days
        })
    
    @action(detail=False, methods=['get'])
    def stock_health(self, request):
        """Get stock health scores for all products."""
        products = Product.objects.filter(created_by=request.user, is_deleted=False)
        
        health_scores = []
        for product in products:
            score = DemandForecast.calculate_stock_health_score(product)
            health_scores.append({
                'product_id': product.id,
                'product_name': product.name,
                'health_score': score,
                'status': 'critical' if score < 40 else 'warning' if score < 70 else 'good'
            })
        
        # Sort by score (worst first)
        health_scores.sort(key=lambda x: x['health_score'])
        
        return Response({
            'health_scores': health_scores,
            'average_score': sum(h['health_score'] for h in health_scores) / len(health_scores) if health_scores else 0
        })
    
    @action(detail=False, methods=['get'])
    def profit_analysis(self, request):
        """Get comprehensive profit analysis."""
        days = int(request.query_params.get('days', 30))
        report = ProfitAnalyzer.get_profit_report(request.user, days)
        
        return Response({
            'total_revenue': str(report['total_revenue']),
            'total_cost': str(report['total_cost']),
            'total_profit': str(report['total_profit']),
            'profit_margin': float(report['profit_margin']),
            'top_products': [
                {
                    'product_name': item['product'].name,
                    'quantity_sold': item['quantity_sold'],
                    'revenue': str(item['revenue']),
                    'profit': str(item['profit'])
                }
                for item in report['top_products']
            ],
            'period_days': report['period_days']
        })
    
    @action(detail=False, methods=['get'])
    def low_margin_products(self, request):
        """Get products with low profit margins."""
        threshold = int(request.query_params.get('threshold', 20))
        low_margin = ProfitAnalyzer.get_low_margin_products(request.user, threshold)
        
        return Response({
            'low_margin_products': [
                {
                    'product_id': item['product'].id,
                    'product_name': item['product'].name,
                    'cost_price': str(item['product'].cost_price),
                    'selling_price': str(item['product'].selling_price),
                    'margin_percentage': float(item['margin'])
                }
                for item in low_margin
            ],
            'threshold': threshold
        })
    
    @action(detail=False, methods=['get'])
    def smart_alerts(self, request):
        """Get all intelligent alerts and recommendations."""
        alerts = SmartAlerts.get_all_smart_alerts(request.user)
        
        return Response({
            'critical_alerts': [
                {
                    'type': alert['type'],
                    'product_id': alert['product'].id,
                    'product_name': alert['product'].name,
                    'message': alert['message']
                }
                for alert in alerts['critical']
            ],
            'warnings': [
                {
                    'type': alert['type'],
                    'product_id': alert['product'].id,
                    'product_name': alert['product'].name,
                    'message': alert['message'],
                    'recommended_quantity': alert.get('recommended_quantity')
                }
                for alert in alerts['warnings']
            ],
            'recommendations': [
                {
                    'type': alert['type'],
                    'product_id': alert['product'].id,
                    'product_name': alert['product'].name,
                    'message': alert['message'],
                    'health_score': alert.get('health_score')
                }
                for alert in alerts['recommendations']
            ]
        })


class ShoppingListViewSet(viewsets.ModelViewSet):
    """Shopping list management."""
    
    serializer_class = ShoppingListSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return ShoppingList.objects.filter(created_by=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark shopping list as completed."""
        shopping_list = self.get_object()
        shopping_list.status = 'completed'
        shopping_list.completed_at = timezone.now()
        shopping_list.save()
        
        serializer = self.get_serializer(shopping_list)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        """Add item to shopping list."""
        shopping_list = self.get_object()
        
        serializer = ShoppingListItemSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(shopping_list=shopping_list)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ShoppingListItemViewSet(viewsets.ModelViewSet):
    """Shopping list items management."""
    
    serializer_class = ShoppingListItemSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return ShoppingListItem.objects.filter(
            shopping_list__created_by=self.request.user
        )
    
    @action(detail=True, methods=['post'])
    def toggle_purchased(self, request, pk=None):
        """Toggle purchased status of an item."""
        item = self.get_object()
        item.is_purchased = not item.is_purchased
        item.save()
        
        serializer = self.get_serializer(item)
        return Response(serializer.data)


class PurchaseOrderViewSet(viewsets.ModelViewSet):
    """Purchase order management."""
    
    serializer_class = PurchaseOrderSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return PurchaseOrder.objects.filter(created_by=self.request.user)
    
    def perform_create(self, serializer):
        # Generate order number
        import uuid
        order_number = f"PO{timezone.now().strftime('%Y%m%d')}{uuid.uuid4().hex[:6].upper()}"
        serializer.save(created_by=self.request.user, order_number=order_number)
    
    @action(detail=True, methods=['post'])
    def mark_received(self, request, pk=None):
        """Mark purchase order as received."""
        po = self.get_object()
        po.status = 'received'
        po.actual_delivery = timezone.now().date()
        po.save()
        
        # Update product stock
        for item in po.items.all():
            item.product.quantity += item.quantity
            item.received_quantity = item.quantity
            item.product.save()
            item.save()
        
        serializer = self.get_serializer(po)
        return Response(serializer.data)


class ProductFavoriteViewSet(viewsets.ModelViewSet):
    """Product favorites management."""
    
    serializer_class = ProductFavoriteSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return ProductFavorite.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    @action(detail=False, methods=['post'])
    def toggle(self, request):
        """Toggle favorite status for a product."""
        product_id = request.data.get('product_id')
        
        if not product_id:
            return Response(
                {'error': 'product_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            product = Product.objects.get(id=product_id, created_by=request.user)
        except Product.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        favorite, created = ProductFavorite.objects.get_or_create(
            user=request.user,
            product=product
        )
        
        if not created:
            favorite.delete()
            return Response({'status': 'removed'})
        
        serializer = self.get_serializer(favorite)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class StoreViewSet(viewsets.ModelViewSet):
    """Store/location management."""
    
    serializer_class = StoreSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Store.objects.filter(created_by=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


class ProductReviewViewSet(viewsets.ModelViewSet):
    """Product reviews management."""
    
    serializer_class = ProductReviewSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        product_id = self.request.query_params.get('product_id')
        if product_id:
            return ProductReview.objects.filter(product_id=product_id)
        return ProductReview.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
