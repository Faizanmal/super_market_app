"""
URL patterns for ML and AI endpoints.
"""
from django.urls import path
from .advanced_ml_views import advanced_demand_forecast

app_name = 'ml'

urlpatterns = [
    # Demand forecasting endpoints
    path('demand-forecast/', advanced_demand_forecast, name='demand-forecast'),
    path('demand-forecast/<int:product_id>/', advanced_demand_forecast, name='demand-forecast-detail'),
]