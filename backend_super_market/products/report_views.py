"""
Advanced reporting and export views.
"""
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import F
from datetime import timedelta
import csv
from io import StringIO
from .models import Product, StockMovement, Supplier

class ReportViewSet(viewsets.ViewSet):
    """Advanced reporting and analytics."""
    
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def inventory_valuation(self, request):
        """Get complete inventory valuation report."""
        user = request.user
        products = Product.objects.filter(created_by=user, is_deleted=False)
        
        total_cost_value = sum(p.cost_price * p.quantity for p in products)
        total_selling_value = sum(p.selling_price * p.quantity for p in products)
        potential_profit = total_selling_value - total_cost_value
        
        # Group by category
        category_breakdown = {}
        for product in products:
            category_name = product.category.name if product.category else 'Uncategorized'
            if category_name not in category_breakdown:
                category_breakdown[category_name] = {
                    'cost_value': 0,
                    'selling_value': 0,
                    'quantity': 0,
                    'product_count': 0
                }
            
            category_breakdown[category_name]['cost_value'] += float(product.cost_price * product.quantity)
            category_breakdown[category_name]['selling_value'] += float(product.selling_price * product.quantity)
            category_breakdown[category_name]['quantity'] += product.quantity
            category_breakdown[category_name]['product_count'] += 1
        
        return Response({
            'total_cost_value': float(total_cost_value),
            'total_selling_value': float(total_selling_value),
            'potential_profit': float(potential_profit),
            'total_products': products.count(),
            'category_breakdown': category_breakdown
        })
    
    @action(detail=False, methods=['get'])
    def sales_report(self, request):
        """Generate sales report for a period."""
        days = int(request.query_params.get('days', 30))
        cutoff_date = timezone.now() - timedelta(days=days)
        
        # Get outbound movements (sales)
        sales = StockMovement.objects.filter(
            created_by=request.user,
            movement_type='out',
            created_at__gte=cutoff_date
        ).select_related('product')
        
        total_revenue = 0
        total_cost = 0
        total_items_sold = 0
        product_sales = {}
        daily_sales = {}
        
        for sale in sales:
            product = sale.product
            quantity = sale.quantity
            revenue = float(product.selling_price * quantity)
            cost = float(product.cost_price * quantity)
            
            total_revenue += revenue
            total_cost += cost
            total_items_sold += quantity
            
            # Per product
            if product.id not in product_sales:
                product_sales[product.id] = {
                    'product_name': product.name,
                    'quantity_sold': 0,
                    'revenue': 0,
                    'profit': 0
                }
            product_sales[product.id]['quantity_sold'] += quantity
            product_sales[product.id]['revenue'] += revenue
            product_sales[product.id]['profit'] += (revenue - cost)
            
            # Daily sales
            date_key = sale.created_at.strftime('%Y-%m-%d')
            if date_key not in daily_sales:
                daily_sales[date_key] = {
                    'revenue': 0,
                    'items_sold': 0
                }
            daily_sales[date_key]['revenue'] += revenue
            daily_sales[date_key]['items_sold'] += quantity
        
        total_profit = total_revenue - total_cost
        
        # Top products
        top_products = sorted(
            product_sales.values(),
            key=lambda x: x['revenue'],
            reverse=True
        )[:10]
        
        return Response({
            'period_days': days,
            'total_revenue': total_revenue,
            'total_cost': total_cost,
            'total_profit': total_profit,
            'profit_margin': (total_profit / total_revenue * 100) if total_revenue > 0 else 0,
            'total_items_sold': total_items_sold,
            'average_daily_revenue': total_revenue / days if days > 0 else 0,
            'top_products': top_products,
            'daily_sales': [
                {'date': k, **v} for k, v in sorted(daily_sales.items())
            ]
        })
    
    @action(detail=False, methods=['get'])
    def expiry_report(self, request):
        """Generate expiry report with detailed breakdown."""
        user = request.user
        products = Product.objects.filter(created_by=user, is_deleted=False)
        
        today = timezone.now().date()
        expired = []
        expiring_soon = []
        fresh = []
        
        for product in products:
            days_until = (product.expiry_date - today).days
            product_data = {
                'id': product.id,
                'name': product.name,
                'expiry_date': product.expiry_date.isoformat(),
                'days_until_expiry': days_until,
                'quantity': product.quantity,
                'value': float(product.cost_price * product.quantity)
            }
            
            if days_until < 0:
                expired.append(product_data)
            elif days_until <= 7:
                expiring_soon.append(product_data)
            else:
                fresh.append(product_data)
        
        expired_value = sum(p['value'] for p in expired)
        expiring_soon_value = sum(p['value'] for p in expiring_soon)
        
        return Response({
            'expired': {
                'count': len(expired),
                'products': sorted(expired, key=lambda x: x['days_until_expiry']),
                'total_value': expired_value
            },
            'expiring_soon': {
                'count': len(expiring_soon),
                'products': sorted(expiring_soon, key=lambda x: x['days_until_expiry']),
                'total_value': expiring_soon_value
            },
            'fresh': {
                'count': len(fresh),
                'total_value': sum(p['value'] for p in fresh)
            },
            'at_risk_value': expired_value + expiring_soon_value
        })
    
    @action(detail=False, methods=['get'])
    def stock_movement_report(self, request):
        """Detailed stock movement analysis."""
        days = int(request.query_params.get('days', 30))
        cutoff_date = timezone.now() - timedelta(days=days)
        
        movements = StockMovement.objects.filter(
            created_by=request.user,
            created_at__gte=cutoff_date
        )
        
        summary = {
            'in': {'count': 0, 'quantity': 0},
            'out': {'count': 0, 'quantity': 0},
            'wastage': {'count': 0, 'quantity': 0},
            'adjustment': {'count': 0, 'quantity': 0}
        }
        
        for movement in movements:
            movement_type = movement.movement_type
            summary[movement_type]['count'] += 1
            summary[movement_type]['quantity'] += movement.quantity
        
        return Response({
            'period_days': days,
            'summary': summary,
            'total_movements': movements.count()
        })
    
    @action(detail=False, methods=['get'])
    def supplier_performance(self, request):
        """Analyze supplier performance."""
        suppliers = Supplier.objects.filter(created_by=request.user)
        
        performance = []
        for supplier in suppliers:
            products = supplier.products.filter(is_deleted=False)
            purchase_orders = supplier.purchase_orders.all()
            
            on_time_deliveries = purchase_orders.filter(
                status='received',
                actual_delivery__lte=F('expected_delivery')
            ).count()
            
            total_completed = purchase_orders.filter(status='received').count()
            
            performance.append({
                'supplier_name': supplier.name,
                'total_products': products.count(),
                'total_orders': purchase_orders.count(),
                'completed_orders': total_completed,
                'on_time_rate': (on_time_deliveries / total_completed * 100) if total_completed > 0 else 0,
                'total_value': sum(po.total_amount for po in purchase_orders.filter(status='received'))
            })
        
        return Response({
            'suppliers': sorted(performance, key=lambda x: x['total_value'], reverse=True)
        })
    
    @action(detail=False, methods=['get'])
    def export_inventory_csv(self, request):
        """Export inventory to CSV format."""
        products = Product.objects.filter(
            created_by=request.user,
            is_deleted=False
        ).select_related('category', 'supplier')
        
        output = StringIO()
        writer = csv.writer(output)
        
        # Header
        writer.writerow([
            'Name', 'Barcode', 'Category', 'Supplier', 'Quantity',
            'Min Stock', 'Cost Price', 'Selling Price', 'Profit Margin %',
            'Expiry Date', 'Status', 'Location', 'Batch Number'
        ])
        
        # Data
        for product in products:
            writer.writerow([
                product.name,
                product.barcode,
                product.category.name if product.category else '',
                product.supplier.name if product.supplier else '',
                product.quantity,
                product.min_stock_level,
                product.cost_price,
                product.selling_price,
                round(product.profit_margin, 2),
                product.expiry_date.isoformat(),
                product.get_expiry_status(),
                product.location or '',
                product.batch_number or ''
            ])
        
        csv_data = output.getvalue()
        output.close()
        
        return Response({
            'csv_data': csv_data,
            'filename': f'inventory_{timezone.now().strftime("%Y%m%d_%H%M%S")}.csv'
        })
    
    @action(detail=False, methods=['get'])
    def dashboard_summary(self, request):
        """Comprehensive dashboard summary."""
        user = request.user
        products = Product.objects.filter(created_by=user, is_deleted=False)
        
        # Stock status
        total_products = products.count()
        low_stock = products.filter(quantity__lte=F('min_stock_level')).count()
        out_of_stock = products.filter(quantity=0).count()
        
        # Expiry status
        today = timezone.now().date()
        expired = products.filter(expiry_date__lt=today).count()
        expiring_soon = products.filter(
            expiry_date__gte=today,
            expiry_date__lte=today + timedelta(days=7)
        ).count()
        
        # Values
        total_cost_value = sum(p.cost_price * p.quantity for p in products)
        total_selling_value = sum(p.selling_price * p.quantity for p in products)
        
        # Recent activity
        recent_movements = StockMovement.objects.filter(
            created_by=user,
            created_at__gte=timezone.now() - timedelta(days=7)
        ).count()
        
        return Response({
            'inventory': {
                'total_products': total_products,
                'low_stock': low_stock,
                'out_of_stock': out_of_stock,
                'healthy_stock': total_products - low_stock - out_of_stock
            },
            'expiry': {
                'expired': expired,
                'expiring_soon': expiring_soon,
                'fresh': total_products - expired - expiring_soon
            },
            'valuation': {
                'total_cost_value': float(total_cost_value),
                'total_selling_value': float(total_selling_value),
                'potential_profit': float(total_selling_value - total_cost_value)
            },
            'activity': {
                'recent_movements': recent_movements
            }
        })
