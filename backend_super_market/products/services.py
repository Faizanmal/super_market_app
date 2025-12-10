"""
Enhanced API Service - Enterprise-grade Inventory Intelligence Service.
Provides real-time analytics, AI-powered predictions, and smart automation.
"""
from typing import Dict, List, Optional, Any, Tuple
from decimal import Decimal
from datetime import datetime, date, timedelta
from collections import defaultdict
import logging

from django.db import transaction
from django.db.models import (
    Sum, Avg, Count, F, Q, Case, When, Value,
    DecimalField, IntegerField, CharField,
    ExpressionWrapper
)
from django.db.models.functions import (
    TruncDate, TruncWeek, TruncMonth,
    Coalesce, ExtractWeekDay
)
from django.utils import timezone
from django.core.cache import cache

from products.models import (
    Product, Category, StockMovement, Store, Supplier,
    PurchaseOrder, Notification
)
from core.services import BaseService, ServiceResult, EventDispatcher, Events
from core.cache import cache_manager, CacheKeyBuilder, CACHE_MEDIUM, CACHE_HOUR
from core.exceptions import ValidationError, InsufficientStockError

logger = logging.getLogger(__name__)


class InventoryAnalyticsService(BaseService):
    """
    Advanced inventory analytics service with AI-powered insights.
    Provides comprehensive analytics, forecasting, and recommendations.
    """
    
    model = Product
    
    def get_queryset(self):
        """Get products for the current user/store."""
        queryset = super().get_queryset().filter(is_active=True)
        
        if self.user and not self.user.is_superuser:
            if self.user.role != 'head_office':
                user_store = getattr(self.user, 'store', None)
                if user_store:
                    queryset = queryset.filter(store=user_store)
        
        return queryset
    
    def get_dashboard_metrics(self) -> Dict[str, Any]:
        """Get comprehensive dashboard metrics."""
        cache_key = CacheKeyBuilder.analytics_key('dashboard', {'user_id': self.user.id if self.user else None})
        cached_data = cache_manager.get(cache_key)
        
        if cached_data:
            return cached_data
        
        products = self.get_queryset()
        today = timezone.now().date()
        
        metrics = {
            'inventory': self._get_inventory_metrics(products),
            'expiry': self._get_expiry_metrics(products, today),
            'stock_health': self._get_stock_health_metrics(products),
            'financial': self._get_financial_metrics(products),
            'trends': self._get_trend_metrics(),
            'alerts': self._get_alert_counts(),
            'timestamp': timezone.now().isoformat(),
        }
        
        cache_manager.set(cache_key, metrics, CACHE_MEDIUM)
        return metrics
    
    def _get_inventory_metrics(self, products) -> Dict[str, Any]:
        """Calculate inventory metrics."""
        aggregates = products.aggregate(
            total_products=Count('id'),
            total_quantity=Coalesce(Sum('quantity'), 0),
            total_value=Coalesce(Sum(F('quantity') * F('cost_price')), Decimal('0')),
            total_retail_value=Coalesce(Sum(F('quantity') * F('selling_price')), Decimal('0')),
            avg_quantity=Coalesce(Avg('quantity'), 0),
            total_categories=Count('category', distinct=True),
            total_suppliers=Count('supplier', distinct=True),
        )
        
        return {
            'total_products': aggregates['total_products'],
            'total_quantity': aggregates['total_quantity'],
            'total_cost_value': float(aggregates['total_value']),
            'total_retail_value': float(aggregates['total_retail_value']),
            'potential_profit': float(aggregates['total_retail_value'] - aggregates['total_value']),
            'average_quantity': round(aggregates['avg_quantity'], 1),
            'categories_count': aggregates['total_categories'],
            'suppliers_count': aggregates['total_suppliers'],
        }
    
    def _get_expiry_metrics(self, products, today: date) -> Dict[str, Any]:
        """Calculate expiry-related metrics."""
        expired = products.filter(expiry_date__lt=today)
        expiring_7_days = products.filter(
            expiry_date__gte=today,
            expiry_date__lte=today + timedelta(days=7)
        )
        expiring_30_days = products.filter(
            expiry_date__gte=today,
            expiry_date__lte=today + timedelta(days=30)
        )
        
        expired_value = expired.aggregate(
            value=Coalesce(Sum(F('quantity') * F('cost_price')), Decimal('0'))
        )['value']
        
        return {
            'expired_count': expired.count(),
            'expired_value': float(expired_value),
            'expiring_7_days_count': expiring_7_days.count(),
            'expiring_30_days_count': expiring_30_days.count(),
            'expiring_soon_value': float(
                expiring_7_days.aggregate(
                    value=Coalesce(Sum(F('quantity') * F('cost_price')), Decimal('0'))
                )['value']
            ),
            'freshness_score': self._calculate_freshness_score(products, today),
        }
    
    def _get_stock_health_metrics(self, products) -> Dict[str, Any]:
        """Calculate stock health metrics."""
        out_of_stock = products.filter(quantity=0)
        low_stock = products.filter(quantity__gt=0, quantity__lte=F('min_stock_level'))
        adequate_stock = products.filter(quantity__gt=F('min_stock_level'))
        overstocked = products.filter(quantity__gt=F('reorder_quantity') * 2)
        
        return {
            'out_of_stock': out_of_stock.count(),
            'low_stock': low_stock.count(),
            'adequate_stock': adequate_stock.count(),
            'overstocked': overstocked.count(),
            'stock_health_score': self._calculate_stock_health_score(products),
            'reorder_needed': low_stock.count() + out_of_stock.count(),
        }
    
    def _get_financial_metrics(self, products) -> Dict[str, Any]:
        """Calculate financial metrics."""
        aggregates = products.aggregate(
            total_cost=Coalesce(Sum(F('quantity') * F('cost_price')), Decimal('0')),
            total_retail=Coalesce(Sum(F('quantity') * F('selling_price')), Decimal('0')),
            avg_margin=Coalesce(
                Avg(
                    ExpressionWrapper(
                        (F('selling_price') - F('cost_price')) / F('cost_price') * 100,
                        output_field=DecimalField()
                    )
                ),
                Decimal('0')
            ),
        )
        
        return {
            'total_cost_value': float(aggregates['total_cost']),
            'total_retail_value': float(aggregates['total_retail']),
            'potential_profit': float(aggregates['total_retail'] - aggregates['total_cost']),
            'average_margin': round(float(aggregates['avg_margin']), 2),
        }
    
    def _get_trend_metrics(self) -> Dict[str, Any]:
        """Calculate trend metrics from stock movements."""
        last_30_days = timezone.now() - timedelta(days=30)
        last_7_days = timezone.now() - timedelta(days=7)
        
        movements = StockMovement.objects.filter(created_at__gte=last_30_days)
        
        if self.user and hasattr(self.user, 'store') and self.user.store:
            movements = movements.filter(product__store=self.user.store)
        
        daily_trends = movements.filter(
            created_at__gte=last_7_days
        ).annotate(
            date=TruncDate('created_at')
        ).values('date').annotate(
            stock_in=Sum(Case(
                When(movement_type='in', then='quantity'),
                default=0,
                output_field=IntegerField()
            )),
            stock_out=Sum(Case(
                When(movement_type__in=['out', 'wastage'], then='quantity'),
                default=0,
                output_field=IntegerField()
            )),
        ).order_by('date')
        
        return {
            'daily_movements': list(daily_trends),
            'total_stock_in_30d': movements.filter(movement_type='in').aggregate(
                total=Coalesce(Sum('quantity'), 0)
            )['total'],
            'total_stock_out_30d': movements.filter(movement_type__in=['out', 'wastage']).aggregate(
                total=Coalesce(Sum('quantity'), 0)
            )['total'],
            'wastage_30d': movements.filter(movement_type='wastage').aggregate(
                total=Coalesce(Sum('quantity'), 0)
            )['total'],
        }
    
    def _get_alert_counts(self) -> Dict[str, int]:
        """Get counts of different alert types."""
        if not self.user:
            return {}
        
        alerts = Notification.objects.filter(user=self.user, is_read=False)
        
        return {
            'total_unread': alerts.count(),
            'critical': alerts.filter(priority='critical').count(),
            'high': alerts.filter(priority='high').count(),
            'medium': alerts.filter(priority='medium').count(),
            'low': alerts.filter(priority='low').count(),
        }
    
    def _calculate_freshness_score(self, products, today: date) -> float:
        """Calculate overall inventory freshness score (0-100)."""
        if not products.exists():
            return 100.0
        
        total = products.count()
        fresh = products.filter(expiry_date__gt=today + timedelta(days=30)).count()
        expiring = products.filter(
            expiry_date__gte=today,
            expiry_date__lte=today + timedelta(days=30)
        ).count()
        expired = products.filter(expiry_date__lt=today).count()
        
        score = ((fresh * 100) + (expiring * 50) + (expired * 0)) / total
        return round(score, 1)
    
    def _calculate_stock_health_score(self, products) -> float:
        """Calculate overall stock health score (0-100)."""
        if not products.exists():
            return 100.0
        
        total = products.count()
        adequate = products.filter(quantity__gt=F('min_stock_level')).count()
        low = products.filter(quantity__gt=0, quantity__lte=F('min_stock_level')).count()
        out_of_stock = products.filter(quantity=0).count()
        
        score = ((adequate * 100) + (low * 40) + (out_of_stock * 0)) / total
        return round(score, 1)
    
    def get_category_analysis(self) -> List[Dict[str, Any]]:
        """Get detailed analysis by category."""
        products = self.get_queryset()
        today = timezone.now().date()
        
        categories = products.values(
            'category__id',
            'category__name',
            'category__color',
        ).annotate(
            total_products=Count('id'),
            total_quantity=Coalesce(Sum('quantity'), 0),
            total_value=Coalesce(Sum(F('quantity') * F('cost_price')), Decimal('0')),
            low_stock_count=Count(Case(
                When(quantity__lte=F('min_stock_level'), then=1),
                output_field=IntegerField()
            )),
            expiring_count=Count(Case(
                When(expiry_date__lte=today + timedelta(days=7), then=1),
                output_field=IntegerField()
            )),
            avg_margin=Coalesce(
                Avg(
                    ExpressionWrapper(
                        (F('selling_price') - F('cost_price')) / F('cost_price') * 100,
                        output_field=DecimalField()
                    )
                ),
                Decimal('0')
            ),
        ).order_by('-total_value')
        
        return [
            {
                'id': cat['category__id'],
                'name': cat['category__name'] or 'Uncategorized',
                'color': cat['category__color'] or '#9E9E9E',
                'products_count': cat['total_products'],
                'total_quantity': cat['total_quantity'],
                'total_value': float(cat['total_value']),
                'low_stock_count': cat['low_stock_count'],
                'expiring_count': cat['expiring_count'],
                'average_margin': round(float(cat['avg_margin']), 2),
            }
            for cat in categories
        ]
    
    def get_supplier_performance(self) -> List[Dict[str, Any]]:
        """Get supplier performance metrics."""
        products = self.get_queryset()
        
        suppliers = products.values(
            'supplier__id',
            'supplier__name',
        ).annotate(
            total_products=Count('id'),
            total_value=Coalesce(Sum(F('quantity') * F('cost_price')), Decimal('0')),
            avg_lead_time=Value(7),  # Placeholder - implement actual calculation
            on_time_delivery_rate=Value(95),  # Placeholder
            defect_rate=Value(2),  # Placeholder
        ).filter(supplier__isnull=False).order_by('-total_value')
        
        return [
            {
                'id': sup['supplier__id'],
                'name': sup['supplier__name'],
                'products_count': sup['total_products'],
                'total_value': float(sup['total_value']),
                'avg_lead_time_days': sup['avg_lead_time'],
                'on_time_delivery_rate': sup['on_time_delivery_rate'],
                'defect_rate': sup['defect_rate'],
            }
            for sup in suppliers
        ]
    
    def get_ai_recommendations(self) -> List[Dict[str, Any]]:
        """Generate AI-powered recommendations."""
        recommendations = []
        products = self.get_queryset()
        today = timezone.now().date()
        
        # Low stock recommendations
        low_stock_products = products.filter(
            quantity__lte=F('min_stock_level'),
            quantity__gt=0
        ).select_related('supplier')[:10]
        
        for product in low_stock_products:
            recommendations.append({
                'type': 'reorder',
                'priority': 'high',
                'product_id': product.id,
                'product_name': product.name,
                'current_quantity': product.quantity,
                'recommended_action': f"Reorder {product.reorder_quantity} units",
                'reason': f"Stock below minimum level ({product.min_stock_level})",
                'supplier': product.supplier.name if product.supplier else None,
            })
        
        # Expiring soon recommendations
        expiring_products = products.filter(
            expiry_date__gte=today,
            expiry_date__lte=today + timedelta(days=7)
        )[:10]
        
        for product in expiring_products:
            days_left = (product.expiry_date - today).days
            recommendations.append({
                'type': 'expiry_action',
                'priority': 'high' if days_left <= 3 else 'medium',
                'product_id': product.id,
                'product_name': product.name,
                'expiry_date': product.expiry_date.isoformat(),
                'days_until_expiry': days_left,
                'quantity': product.quantity,
                'recommended_action': 'Apply discount' if days_left > 3 else 'Consider markdown sale',
                'reason': f"Product expires in {days_left} days",
            })
        
        # Overstocked recommendations
        overstocked = products.filter(
            quantity__gt=F('reorder_quantity') * 3
        )[:5]
        
        for product in overstocked:
            recommendations.append({
                'type': 'overstock',
                'priority': 'low',
                'product_id': product.id,
                'product_name': product.name,
                'current_quantity': product.quantity,
                'recommended_action': 'Consider promotion or inter-store transfer',
                'reason': 'Stock significantly above optimal level',
            })
        
        return recommendations
    
    def generate_demand_forecast(self, product_id: int, days: int = 30) -> Dict[str, Any]:
        """Generate demand forecast for a product using historical data."""
        try:
            product = self.get_queryset().get(pk=product_id)
        except Product.DoesNotExist:
            return {'error': 'Product not found'}
        
        # Get historical stock movements
        movements = StockMovement.objects.filter(
            product=product,
            movement_type='out',
            created_at__gte=timezone.now() - timedelta(days=90)
        )
        
        if not movements.exists():
            return {
                'product_id': product_id,
                'product_name': product.name,
                'forecast': [],
                'confidence': 0,
                'message': 'Insufficient historical data for forecast'
            }
        
        # Calculate daily average sales
        daily_sales = movements.annotate(
            date=TruncDate('created_at')
        ).values('date').annotate(
            total=Sum('quantity')
        ).order_by('date')
        
        if not daily_sales:
            avg_daily_sales = 0
        else:
            avg_daily_sales = sum(d['total'] for d in daily_sales) / len(daily_sales)
        
        # Generate forecast
        forecast = []
        current_date = timezone.now().date()
        
        for i in range(days):
            forecast_date = current_date + timedelta(days=i + 1)
            # Simple forecast with day-of-week adjustment
            weekday_factor = 1.2 if forecast_date.weekday() in [5, 6] else 1.0
            predicted_sales = round(avg_daily_sales * weekday_factor, 1)
            
            forecast.append({
                'date': forecast_date.isoformat(),
                'predicted_sales': predicted_sales,
                'lower_bound': max(0, predicted_sales * 0.8),
                'upper_bound': predicted_sales * 1.2,
            })
        
        # Calculate confidence based on data quality
        confidence = min(100, len(daily_sales) * 2)
        
        return {
            'product_id': product_id,
            'product_name': product.name,
            'current_stock': product.quantity,
            'average_daily_sales': round(avg_daily_sales, 2),
            'forecast': forecast,
            'confidence': confidence,
            'stockout_risk_days': int(product.quantity / avg_daily_sales) if avg_daily_sales > 0 else None,
            'recommended_reorder_date': (
                current_date + timedelta(days=int(product.quantity / avg_daily_sales) - 7)
            ).isoformat() if avg_daily_sales > 0 and product.quantity / avg_daily_sales > 7 else None,
        }


class StockManagementService(BaseService):
    """
    Service for managing stock operations with full audit trail.
    """
    
    model = Product
    
    @transaction.atomic
    def record_stock_movement(
        self,
        product_id: int,
        movement_type: str,
        quantity: int,
        reason: str = None,
        reference_number: str = None,
        unit_price: Decimal = None
    ) -> ServiceResult:
        """Record a stock movement and update product quantity."""
        try:
            product = self.model.objects.select_for_update().get(pk=product_id)
        except Product.DoesNotExist:
            return ServiceResult.fail("Product not found")
        
        # Validate movement
        if movement_type in ['out', 'wastage'] and quantity > product.quantity:
            return ServiceResult.fail(
                f"Insufficient stock. Available: {product.quantity}, Requested: {quantity}"
            )
        
        # Create movement record
        movement = StockMovement.objects.create(
            product=product,
            movement_type=movement_type,
            quantity=quantity,
            reason=reason,
            reference_number=reference_number,
            unit_price=unit_price or product.cost_price,
            created_by=self.user,
        )
        
        # Update product quantity
        if movement_type == 'in':
            product.quantity += quantity
        elif movement_type in ['out', 'wastage']:
            product.quantity -= quantity
        elif movement_type == 'adjustment':
            product.quantity = quantity
        
        product.save(update_fields=['quantity', 'updated_at'])
        
        # Dispatch event for notifications
        EventDispatcher.dispatch(Events.STOCK_MOVEMENT, movement=movement, product=product)
        
        # Check for low stock alert
        if product.is_low_stock:
            EventDispatcher.dispatch(Events.PRODUCT_LOW_STOCK, product=product)
        
        # Invalidate cache
        cache_manager.invalidate_product(product.id)
        
        return ServiceResult.ok(
            data={
                'movement_id': movement.id,
                'product_id': product.id,
                'new_quantity': product.quantity,
            },
            message=f"Stock movement recorded successfully"
        )
    
    @transaction.atomic
    def bulk_stock_adjustment(
        self,
        adjustments: List[Dict[str, Any]],
        reason: str = "Bulk stock adjustment"
    ) -> ServiceResult:
        """Perform bulk stock adjustments."""
        results = []
        errors = []
        
        for adj in adjustments:
            result = self.record_stock_movement(
                product_id=adj['product_id'],
                movement_type='adjustment',
                quantity=adj['new_quantity'],
                reason=reason,
                reference_number=adj.get('reference_number'),
            )
            
            if result.success:
                results.append(result.data)
            else:
                errors.append({
                    'product_id': adj['product_id'],
                    'error': result.message
                })
        
        return ServiceResult.ok(
            data={
                'successful': len(results),
                'failed': len(errors),
                'results': results,
                'errors': errors if errors else None,
            },
            message=f"Bulk adjustment completed: {len(results)} successful, {len(errors)} failed"
        )
    
    @transaction.atomic
    def inter_store_transfer(
        self,
        product_id: int,
        from_store_id: int,
        to_store_id: int,
        quantity: int,
        notes: str = None
    ) -> ServiceResult:
        """Transfer stock between stores."""
        try:
            # Get source product
            source_product = Product.objects.select_for_update().get(
                pk=product_id,
                store_id=from_store_id
            )
        except Product.DoesNotExist:
            return ServiceResult.fail("Product not found in source store")
        
        if quantity > source_product.quantity:
            return ServiceResult.fail(
                f"Insufficient stock. Available: {source_product.quantity}"
            )
        
        try:
            to_store = Store.objects.get(pk=to_store_id)
        except Store.DoesNotExist:
            return ServiceResult.fail("Destination store not found")
        
        # Find or create product in destination store
        dest_product, created = Product.objects.get_or_create(
            barcode=source_product.barcode,
            store=to_store,
            defaults={
                'name': source_product.name,
                'description': source_product.description,
                'category': source_product.category,
                'supplier': source_product.supplier,
                'cost_price': source_product.cost_price,
                'selling_price': source_product.selling_price,
                'expiry_date': source_product.expiry_date,
                'min_stock_level': source_product.min_stock_level,
                'reorder_quantity': source_product.reorder_quantity,
                'quantity': 0,
                'created_by': self.user,
            }
        )
        
        # Perform transfer
        source_product.quantity -= quantity
        dest_product.quantity += quantity
        
        source_product.save(update_fields=['quantity', 'updated_at'])
        dest_product.save(update_fields=['quantity', 'updated_at'])
        
        # Record movements
        StockMovement.objects.create(
            product=source_product,
            movement_type='out',
            quantity=quantity,
            reason=f"Transfer to {to_store.name}",
            created_by=self.user,
        )
        
        StockMovement.objects.create(
            product=dest_product,
            movement_type='in',
            quantity=quantity,
            reason=f"Transfer from {source_product.store.name if source_product.store else 'Unknown'}",
            created_by=self.user,
        )
        
        # Dispatch event
        EventDispatcher.dispatch(
            Events.STORE_TRANSFER,
            source_product=source_product,
            dest_product=dest_product,
            quantity=quantity
        )
        
        return ServiceResult.ok(
            data={
                'source_product_id': source_product.id,
                'dest_product_id': dest_product.id,
                'quantity_transferred': quantity,
                'source_remaining': source_product.quantity,
                'dest_new_quantity': dest_product.quantity,
            },
            message=f"Successfully transferred {quantity} units"
        )


class NotificationService(BaseService):
    """
    Service for managing notifications and alerts.
    """
    
    model = Notification
    
    def create_notification(
        self,
        user,
        notification_type: str,
        title: str,
        message: str,
        priority: str = 'medium',
        product=None,
        purchase_order=None,
        action_url: str = None,
        expires_at: datetime = None
    ) -> Notification:
        """Create a new notification."""
        notification = Notification.objects.create(
            user=user,
            notification_type=notification_type,
            title=title,
            message=message,
            priority=priority,
            product=product,
            purchase_order=purchase_order,
            action_url=action_url,
            expires_at=expires_at,
        )
        
        # Could add real-time notification via WebSocket here
        
        return notification
    
    def send_expiry_alerts(self) -> int:
        """Send alerts for expiring products. Returns count of alerts sent."""
        from accounts.models import User
        
        today = timezone.now().date()
        warning_date = today + timedelta(days=7)
        critical_date = today + timedelta(days=3)
        
        alerts_sent = 0
        
        # Get products by store
        expiring_products = Product.objects.filter(
            is_active=True,
            expiry_date__lte=warning_date,
            expiry_date__gte=today
        ).select_related('store', 'category')
        
        # Group by store and send to store managers
        store_products = defaultdict(list)
        for product in expiring_products:
            store_id = product.store_id if product.store else 'no_store'
            store_products[store_id].append(product)
        
        for store_id, products in store_products.items():
            # Get store managers
            if store_id == 'no_store':
                managers = User.objects.filter(role__in=['store_manager', 'head_office'])
            else:
                managers = User.objects.filter(
                    Q(store_id=store_id) | Q(role='head_office'),
                    role__in=['store_manager', 'head_office']
                )
            
            for manager in managers:
                critical_products = [p for p in products if p.expiry_date <= critical_date]
                warning_products = [p for p in products if p.expiry_date > critical_date]
                
                if critical_products:
                    self.create_notification(
                        user=manager,
                        notification_type='expiry_critical',
                        title=f"🚨 {len(critical_products)} Products Expiring Soon!",
                        message=f"Critical: {len(critical_products)} products expire within 3 days. Immediate action required.",
                        priority='critical',
                    )
                    alerts_sent += 1
                
                if warning_products:
                    self.create_notification(
                        user=manager,
                        notification_type='expiry_warning',
                        title=f"⚠️ {len(warning_products)} Products Expiring This Week",
                        message=f"{len(warning_products)} products expire within 7 days. Consider discount or promotion.",
                        priority='high',
                    )
                    alerts_sent += 1
        
        return alerts_sent
    
    def send_low_stock_alerts(self) -> int:
        """Send alerts for low stock products. Returns count of alerts sent."""
        from accounts.models import User
        
        alerts_sent = 0
        
        low_stock_products = Product.objects.filter(
            is_active=True,
            quantity__lte=F('min_stock_level')
        ).select_related('store', 'supplier')
        
        # Group by store
        store_products = defaultdict(list)
        for product in low_stock_products:
            store_id = product.store_id if product.store else 'no_store'
            store_products[store_id].append(product)
        
        for store_id, products in store_products.items():
            out_of_stock = [p for p in products if p.quantity == 0]
            low_stock = [p for p in products if p.quantity > 0]
            
            if store_id == 'no_store':
                managers = User.objects.filter(role__in=['store_manager', 'head_office'])
            else:
                managers = User.objects.filter(
                    Q(store_id=store_id) | Q(role='head_office'),
                    role__in=['store_manager', 'head_office']
                )
            
            for manager in managers:
                if out_of_stock:
                    self.create_notification(
                        user=manager,
                        notification_type='low_stock',
                        title=f"🔴 {len(out_of_stock)} Products Out of Stock",
                        message=f"{len(out_of_stock)} products are completely out of stock. Immediate reorder recommended.",
                        priority='critical',
                    )
                    alerts_sent += 1
                
                if low_stock:
                    self.create_notification(
                        user=manager,
                        notification_type='low_stock',
                        title=f"🟡 {len(low_stock)} Products Low on Stock",
                        message=f"{len(low_stock)} products are below minimum stock level.",
                        priority='high',
                    )
                    alerts_sent += 1
        
        return alerts_sent
    
    def mark_all_as_read(self, user) -> int:
        """Mark all notifications as read for a user."""
        return Notification.objects.filter(
            user=user,
            is_read=False
        ).update(
            is_read=True,
            read_at=timezone.now()
        )
    
    def get_unread_count(self, user) -> Dict[str, int]:
        """Get unread notification counts by priority."""
        notifications = Notification.objects.filter(user=user, is_read=False)
        
        return {
            'total': notifications.count(),
            'critical': notifications.filter(priority='critical').count(),
            'high': notifications.filter(priority='high').count(),
            'medium': notifications.filter(priority='medium').count(),
            'low': notifications.filter(priority='low').count(),
        }
