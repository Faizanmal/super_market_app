"""
Views for analytics and dashboard data.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.utils import timezone
from django.db.models import Sum, Count, Q, F
from datetime import timedelta

from products.models import Product, Category, StockMovement

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_summary(request):
    """
    Get dashboard summary statistics.
    
    GET /api/analytics/dashboard/
    
    Returns:
        - Total products
        - Total inventory value
        - Low stock count
        - Expiring soon count
        - Expired products count
        - Total categories
        - Total suppliers
    """
    user = request.user
    today = timezone.now().date()
    seven_days_later = today + timedelta(days=7)
    
    # Get all active products for user
    products = Product.objects.filter(created_by=user, is_active=True)
    
    # Calculate statistics
    total_products = products.count()
    
    # Total inventory value
    total_value = products.aggregate(
        total=Sum(F('quantity') * F('cost_price'))
    )['total'] or 0
    
    # Low stock products
    low_stock_count = products.filter(
        quantity__lte=F('min_stock_level')
    ).count()
    
    # Expiring soon (within 7 days)
    expiring_soon_count = products.filter(
        expiry_date__gte=today,
        expiry_date__lte=seven_days_later
    ).count()
    
    # Expired products
    expired_count = products.filter(expiry_date__lt=today).count()
    
    # Categories and suppliers
    total_categories = Category.objects.filter(created_by=user).count()
    total_suppliers = user.suppliers.count()
    
    # Out of stock
    out_of_stock = products.filter(quantity=0).count()
    
    return Response({
        'total_products': total_products,
        'total_inventory_value': float(total_value),
        'low_stock_count': low_stock_count,
        'expiring_soon_count': expiring_soon_count,
        'expired_count': expired_count,
        'out_of_stock': out_of_stock,
        'total_categories': total_categories,
        'total_suppliers': total_suppliers,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def stock_summary(request):
    """
    Get stock level summary.
    
    GET /api/analytics/stock-summary/
    
    Returns stock distribution by status.
    """
    user = request.user
    products = Product.objects.filter(created_by=user, is_active=True)
    
    # Stock levels
    out_of_stock = products.filter(quantity=0).count()
    low_stock = products.filter(
        quantity__gt=0,
        quantity__lte=F('min_stock_level')
    ).count()
    adequate_stock = products.filter(
        quantity__gt=F('min_stock_level')
    ).count()
    
    return Response({
        'out_of_stock': out_of_stock,
        'low_stock': low_stock,
        'adequate_stock': adequate_stock,
        'total': products.count(),
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def expiry_summary(request):
    """
    Get expiry status summary.
    
    GET /api/analytics/expiry-summary/
    
    Returns product distribution by expiry status.
    """
    user = request.user
    today = timezone.now().date()
    seven_days_later = today + timedelta(days=7)
    
    products = Product.objects.filter(created_by=user, is_active=True)
    
    expired = products.filter(expiry_date__lt=today).count()
    expiring_soon = products.filter(
        expiry_date__gte=today,
        expiry_date__lte=seven_days_later
    ).count()
    fresh = products.filter(expiry_date__gt=seven_days_later).count()
    
    return Response({
        'expired': expired,
        'expiring_soon': expiring_soon,
        'fresh': fresh,
        'total': products.count(),
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def category_distribution(request):
    """
    Get product distribution by category.
    
    GET /api/analytics/category-distribution/
    
    Returns count and value of products per category.
    """
    user = request.user
    
    categories = Category.objects.filter(created_by=user).annotate(
        product_count=Count('products', filter=Q(products__is_active=True)),
        total_value=Sum(
            F('products__quantity') * F('products__cost_price'),
            filter=Q(products__is_active=True)
        )
    ).order_by('-product_count')
    
    data = []
    for category in categories:
        data.append({
            'id': category.id,
            'name': category.name,
            'color': category.color,
            'product_count': category.product_count,
            'total_value': float(category.total_value or 0),
        })
    
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def top_products(request):
    """
    Get top products by value.
    
    GET /api/analytics/top-products/?limit=10
    
    Returns top products sorted by inventory value.
    """
    user = request.user
    limit = int(request.query_params.get('limit', 10))
    
    products = Product.objects.filter(
        created_by=user,
        is_active=True
    ).annotate(
        inventory_value=F('quantity') * F('cost_price')
    ).order_by('-inventory_value')[:limit]
    
    data = []
    for product in products:
        data.append({
            'id': product.id,
            'name': product.name,
            'barcode': product.barcode,
            'quantity': product.quantity,
            'cost_price': float(product.cost_price),
            'inventory_value': float(product.quantity * product.cost_price),
        })
    
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def stock_movements_summary(request):
    """
    Get stock movements summary for the last 30 days.
    
    GET /api/analytics/stock-movements-summary/
    
    Returns summary of stock movements by type.
    """
    user = request.user
    thirty_days_ago = timezone.now() - timedelta(days=30)
    
    movements = StockMovement.objects.filter(
        created_by=user,
        created_at__gte=thirty_days_ago
    )
    
    # Group by movement type
    stock_in = movements.filter(movement_type='in').aggregate(
        count=Count('id'),
        total_quantity=Sum('quantity')
    )
    
    stock_out = movements.filter(movement_type='out').aggregate(
        count=Count('id'),
        total_quantity=Sum('quantity')
    )
    
    wastage = movements.filter(movement_type='wastage').aggregate(
        count=Count('id'),
        total_quantity=Sum('quantity')
    )
    
    adjustments = movements.filter(movement_type='adjustment').aggregate(
        count=Count('id'),
        total_quantity=Sum('quantity')
    )
    
    return Response({
        'period_days': 30,
        'stock_in': {
            'count': stock_in['count'] or 0,
            'total_quantity': stock_in['total_quantity'] or 0,
        },
        'stock_out': {
            'count': stock_out['count'] or 0,
            'total_quantity': stock_out['total_quantity'] or 0,
        },
        'wastage': {
            'count': wastage['count'] or 0,
            'total_quantity': wastage['total_quantity'] or 0,
        },
        'adjustments': {
            'count': adjustments['count'] or 0,
            'total_quantity': adjustments['total_quantity'] or 0,
        },
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profit_analysis(request):
    """
    Get profit analysis.
    
    GET /api/analytics/profit-analysis/
    
    Returns profit margin statistics.
    """
    user = request.user
    
    products = Product.objects.filter(
        created_by=user,
        is_active=True
    ).exclude(cost_price=0)
    
    # Calculate profit margins
    total_cost = products.aggregate(
        total=Sum(F('quantity') * F('cost_price'))
    )['total'] or 0
    
    total_potential_revenue = products.aggregate(
        total=Sum(F('quantity') * F('selling_price'))
    )['total'] or 0
    
    potential_profit = total_potential_revenue - total_cost
    
    # Average profit margin
    if total_cost > 0:
        avg_margin = ((total_potential_revenue - total_cost) / total_cost) * 100
    else:
        avg_margin = 0
    
    return Response({
        'total_cost_value': float(total_cost),
        'total_potential_revenue': float(total_potential_revenue),
        'potential_profit': float(potential_profit),
        'average_profit_margin': float(avg_margin),
        'product_count': products.count(),
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def alerts(request):
    """
    Get all alerts (low stock + expiry).
    
    GET /api/analytics/alerts/
    
    Returns combined alerts for dashboard.
    """
    user = request.user
    today = timezone.now().date()
    seven_days_later = today + timedelta(days=7)
    
    products = Product.objects.filter(created_by=user, is_active=True)
    
    # Low stock alerts
    low_stock_products = products.filter(
        quantity__lte=F('min_stock_level')
    ).values('id', 'name', 'barcode', 'quantity', 'min_stock_level')
    
    # Expiring soon alerts
    expiring_soon_products = products.filter(
        expiry_date__gte=today,
        expiry_date__lte=seven_days_later
    ).values('id', 'name', 'barcode', 'expiry_date')
    
    # Expired alerts
    expired_products = products.filter(
        expiry_date__lt=today
    ).values('id', 'name', 'barcode', 'expiry_date')
    
    return Response({
        'low_stock': list(low_stock_products),
        'expiring_soon': list(expiring_soon_products),
        'expired': list(expired_products),
    })
