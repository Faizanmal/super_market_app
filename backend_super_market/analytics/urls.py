"""
URL patterns for analytics endpoints.
"""
from django.urls import path

from .views import (
    dashboard_summary,
    stock_summary,
    expiry_summary,
    category_distribution,
    top_products,
    stock_movements_summary,
    profit_analysis,
    alerts,
)
 
app_name = 'analytics'

urlpatterns = [
    path('dashboard/', dashboard_summary, name='dashboard_summary'),
    path('stock-summary/', stock_summary, name='stock_summary'),
    path('expiry-summary/', expiry_summary, name='expiry_summary'),
    path('category-distribution/', category_distribution, name='category_distribution'),
    path('top-products/', top_products, name='top_products'),
    path('stock-movements-summary/', stock_movements_summary, name='stock_movements_summary'),
    path('profit-analysis/', profit_analysis, name='profit_analysis'),
    path('alerts/', alerts, name='alerts'),
]
