"""
Filters for product model.
"""
from django_filters import rest_framework as filters
from .models import Product


class ProductFilter(filters.FilterSet):
    """Custom filter for Product model."""
 
    name = filters.CharFilter(lookup_expr='icontains')
    category = filters.NumberFilter(field_name='category__id')
    supplier = filters.NumberFilter(field_name='supplier__id')
    min_quantity = filters.NumberFilter(field_name='quantity', lookup_expr='gte')
    max_quantity = filters.NumberFilter(field_name='quantity', lookup_expr='lte')
    min_price = filters.NumberFilter(field_name='selling_price', lookup_expr='gte')
    max_price = filters.NumberFilter(field_name='selling_price', lookup_expr='lte')
    expiry_from = filters.DateFilter(field_name='expiry_date', lookup_expr='gte')
    expiry_to = filters.DateFilter(field_name='expiry_date', lookup_expr='lte')
    
    class Meta:
        model = Product
        fields = [
            'name', 'category', 'supplier', 'barcode',
            'min_quantity', 'max_quantity', 'min_price', 'max_price',
            'expiry_from', 'expiry_to', 'is_active'
        ]
