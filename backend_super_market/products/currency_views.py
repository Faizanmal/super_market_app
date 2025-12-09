"""
Multi-currency API views for SuperMart Manager.
"""
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
import logging

from .models import Product
from .currency_utils import currency_converter, price_manager
from .serializers import ProductSerializer

logger = logging.getLogger(__name__)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_supported_currencies(request):
    """
    Get list of all supported currencies with their symbols and names.
    """
    try:
        currencies = currency_converter.get_supported_currencies()
        
        # Sort by currency code
        sorted_currencies = dict(sorted(currencies.items()))
        
        return Response({
            'supported_currencies': sorted_currencies,
            'total_count': len(currencies),
            'base_currency': currency_converter.base_currency
        })
        
    except Exception as e:
        logger.error(f"Error getting supported currencies: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def convert_currency(request):
    """
    Convert amount between currencies.
    """
    try:
        amount = request.data.get('amount')
        from_currency = request.data.get('from_currency')
        to_currency = request.data.get('to_currency')
        
        # Validation
        if not all([amount, from_currency, to_currency]):
            return Response({
                'error': 'Missing required fields',
                'required_fields': ['amount', 'from_currency', 'to_currency']
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            amount_decimal = float(amount)
            if amount_decimal < 0:
                return Response({
                    'error': 'Amount must be positive',
                    'message': 'Please provide a positive amount'
                }, status=status.HTTP_400_BAD_REQUEST)
        except (ValueError, TypeError):
            return Response({
                'error': 'Invalid amount format',
                'message': 'Amount must be a valid number'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate currency codes
        if not currency_converter.is_valid_currency_code(from_currency):
            return Response({
                'error': 'Invalid source currency',
                'message': f'Currency {from_currency} is not supported'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not currency_converter.is_valid_currency_code(to_currency):
            return Response({
                'error': 'Invalid target currency',
                'message': f'Currency {to_currency} is not supported'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Perform conversion
        from decimal import Decimal
        original_amount = Decimal(str(amount_decimal))
        converted_amount = currency_converter.convert(original_amount, from_currency, to_currency)
        
        # Get exchange rate
        exchange_rate = currency_converter.get_exchange_rate(from_currency, to_currency)
        
        return Response({
            'conversion_result': {
                'original_amount': float(original_amount),
                'converted_amount': float(converted_amount),
                'from_currency': from_currency,
                'to_currency': to_currency,
                'exchange_rate': exchange_rate,
                'formatted_original': currency_converter.format_amount(original_amount, from_currency),
                'formatted_converted': currency_converter.format_amount(converted_amount, to_currency)
            },
            'conversion_timestamp': currency_converter.cache_timeout
        })
        
    except Exception as e:
        logger.error(f"Error converting currency: {e}")
        return Response({
            'error': 'Currency conversion failed',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_exchange_rates(request):
    """
    Get current exchange rates for a base currency.
    """
    try:
        base_currency = request.GET.get('base_currency', 'USD')
        target_currencies = request.GET.getlist('currencies')
        
        # If no target currencies specified, use popular ones
        if not target_currencies:
            target_currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR']
        
        # Validate base currency
        if not currency_converter.is_valid_currency_code(base_currency):
            return Response({
                'error': 'Invalid base currency',
                'message': f'Currency {base_currency} is not supported'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get exchange rates
        rates = currency_converter.get_currency_rates_for_base(base_currency, target_currencies)
        
        # Format response
        formatted_rates = {}
        for currency, rate in rates.items():
            formatted_rates[currency] = {
                'rate': rate,
                'currency_info': currency_converter.get_supported_currencies().get(currency, {}),
                'formatted_rate': f"1 {base_currency} = {rate:.4f} {currency}" if rate != 1 else f"1 {base_currency} = 1 {currency}"
            }
        
        return Response({
            'base_currency': base_currency,
            'exchange_rates': formatted_rates,
            'total_currencies': len(rates),
            'cache_timeout': currency_converter.cache_timeout,
            'rates_timestamp': 'current'  # In production, you might want to track actual timestamp
        })
        
    except Exception as e:
        logger.error(f"Error getting exchange rates: {e}")
        return Response({
            'error': 'Failed to get exchange rates',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def convert_product_price(request, product_id):
    """
    Convert a specific product's price to target currency.
    """
    try:
        product = get_object_or_404(Product, id=product_id, created_by=request.user)
        target_currency = request.GET.get('currency', 'USD')
        
        # Validate target currency
        if not currency_converter.is_valid_currency_code(target_currency):
            return Response({
                'error': 'Invalid target currency',
                'message': f'Currency {target_currency} is not supported'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Convert price
        price_info = price_manager.convert_product_price(product, target_currency)
        
        # Include product information
        product_data = ProductSerializer(product).data
        
        return Response({
            'product_info': product_data,
            'price_conversion': price_info,
            'conversion_timestamp': 'current'
        })
        
    except Exception as e:
        logger.error(f"Error converting product price: {e}")
        return Response({
            'error': 'Failed to convert product price',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_inventory_value_by_currency(request):
    """
    Get total inventory value converted to specified currency.
    """
    try:
        target_currency = request.GET.get('currency', 'USD')
        category_id = request.GET.get('category_id')
        
        # Validate target currency
        if not currency_converter.is_valid_currency_code(target_currency):
            return Response({
                'error': 'Invalid target currency',
                'message': f'Currency {target_currency} is not supported'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get products queryset
        products = Product.objects.filter(created_by=request.user, is_deleted=False)
        
        # Filter by category if specified
        if category_id:
            try:
                category_id = int(category_id)
                products = products.filter(category_id=category_id)
            except (ValueError, TypeError):
                return Response({
                    'error': 'Invalid category ID',
                    'message': 'Category ID must be a valid number'
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Calculate inventory value
        inventory_value = price_manager.get_inventory_value_in_currency(products, target_currency)
        
        return Response({
            'inventory_valuation': inventory_value,
            'filter_applied': {
                'category_id': category_id,
                'total_products_analyzed': inventory_value.get('product_count', 0)
            }
        })
        
    except Exception as e:
        logger.error(f"Error getting inventory value by currency: {e}")
        return Response({
            'error': 'Failed to calculate inventory value',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_products_by_currency(request):
    """
    Get products grouped by their currency.
    """
    try:
        products = Product.objects.filter(created_by=request.user, is_deleted=False)
        
        currency_groups = {}
        total_products = 0
        
        for product in products:
            product_currency = getattr(product, 'currency', 'USD')
            
            if product_currency not in currency_groups:
                currency_groups[product_currency] = {
                    'currency_info': currency_converter.get_supported_currencies().get(product_currency, {}),
                    'products': [],
                    'total_count': 0,
                    'total_value': 0
                }
            
            product_data = ProductSerializer(product).data
            product_value = float(product.price) * product.quantity
            
            currency_groups[product_currency]['products'].append(product_data)
            currency_groups[product_currency]['total_count'] += 1
            currency_groups[product_currency]['total_value'] += product_value
            
            total_products += 1
        
        # Format currency values
        for currency, group in currency_groups.items():
            group['formatted_total_value'] = currency_converter.format_amount(
                group['total_value'], currency
            )
        
        return Response({
            'currency_groups': currency_groups,
            'summary': {
                'total_products': total_products,
                'currencies_used': len(currency_groups),
                'currency_list': list(currency_groups.keys())
            }
        })
        
    except Exception as e:
        logger.error(f"Error getting products by currency: {e}")
        return Response({
            'error': 'Failed to group products by currency',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def clear_currency_cache(request):
    """
    Clear cached exchange rates (admin function).
    """
    try:
        currency_converter.clear_cache()
        
        return Response({
            'message': 'Currency cache cleared successfully',
            'cache_timeout': currency_converter.cache_timeout,
            'next_cache_refresh': 'immediate'
        })
        
    except Exception as e:
        logger.error(f"Error clearing currency cache: {e}")
        return Response({
            'error': 'Failed to clear currency cache',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_product_currency(request, product_id):
    """
    Update a product's currency and optionally convert the price.
    """
    try:
        product = get_object_or_404(Product, id=product_id, created_by=request.user)
        new_currency = request.data.get('currency')
        convert_price = request.data.get('convert_price', False)
        
        if not new_currency:
            return Response({
                'error': 'Currency required',
                'message': 'Please provide a currency code'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate currency
        if not currency_converter.is_valid_currency_code(new_currency):
            return Response({
                'error': 'Invalid currency',
                'message': f'Currency {new_currency} is not supported'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        old_currency = getattr(product, 'currency', 'USD')
        old_price = product.price
        
        # Update currency
        if hasattr(product, 'currency'):
            product.currency = new_currency
        
        # Convert price if requested
        if convert_price and old_currency != new_currency:
            from decimal import Decimal
            converted_price = currency_converter.convert(
                Decimal(str(old_price)), 
                old_currency, 
                new_currency
            )
            product.price = converted_price
        
        product.save()
        
        return Response({
            'message': 'Product currency updated successfully',
            'product_id': product.id,
            'changes': {
                'old_currency': old_currency,
                'new_currency': new_currency,
                'old_price': float(old_price),
                'new_price': float(product.price),
                'price_converted': convert_price and old_currency != new_currency
            },
            'updated_product': ProductSerializer(product).data
        })
        
    except Exception as e:
        logger.error(f"Error updating product currency: {e}")
        return Response({
            'error': 'Failed to update product currency',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)