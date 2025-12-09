"""
URL patterns for currency exchange endpoints.
"""
from django.urls import path
from .currency_views import (
    get_supported_currencies,
    convert_currency,
    get_exchange_rates,
    convert_product_price,
    get_inventory_value_by_currency,
    get_products_by_currency,
    clear_currency_cache,
    update_product_currency,
)

app_name = 'currency'

urlpatterns = [
    # Currency information
    path('supported/', get_supported_currencies, name='supported-currencies'),
    path('convert/', convert_currency, name='convert-currency'),
    path('rates/', get_exchange_rates, name='exchange-rates'),

    # Product currency operations
    path('products/<int:product_id>/convert/', convert_product_price, name='convert-product-price'),
    path('products/<int:product_id>/update/', update_product_currency, name='update-product-currency'),

    # Inventory by currency
    path('inventory/value/', get_inventory_value_by_currency, name='inventory-value-by-currency'),
    path('inventory/products/', get_products_by_currency, name='products-by-currency'),

    # Cache management
    path('cache/clear/', clear_currency_cache, name='clear-currency-cache'),
]