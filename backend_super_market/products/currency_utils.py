"""
Multi-currency support for global store management.
"""
import logging
import requests
from decimal import Decimal
from django.core.cache import cache
from django.conf import settings
from typing import Dict, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class CurrencyConverter:
    """
    Advanced currency converter with caching and multiple exchange rate providers.
    """
    
    def __init__(self):
        self.cache_timeout = 3600  # 1 hour
        self.base_currency = getattr(settings, 'BASE_CURRENCY', 'USD')
        
        # Exchange rate providers (in order of preference)
        self.providers = [
            'fixer_io',
            'exchangerate_api',
            'openexchangerates'
        ]
        
        # Common currency symbols and codes
        self.currency_symbols = {
            'USD': '$',
            'EUR': '€',
            'GBP': '£',
            'JPY': '¥',
            'CNY': '¥',
            'INR': '₹',
            'CAD': 'C$',
            'AUD': 'A$',
            'CHF': 'Fr',
            'SEK': 'kr',
            'NOK': 'kr',
            'DKK': 'kr',
            'PLN': 'zł',
            'CZK': 'Kč',
            'HUF': 'Ft',
            'RUB': '₽',
            'BRL': 'R$',
            'MXN': '$',
            'SGD': 'S$',
            'HKD': 'HK$',
            'NZD': 'NZ$',
            'KRW': '₩',
            'TRY': '₺',
            'ZAR': 'R',
            'THB': '฿',
        }
        
        # Popular currencies with names
        self.currency_names = {
            'USD': 'US Dollar',
            'EUR': 'Euro',
            'GBP': 'British Pound',
            'JPY': 'Japanese Yen',
            'CNY': 'Chinese Yuan',
            'INR': 'Indian Rupee',
            'CAD': 'Canadian Dollar',
            'AUD': 'Australian Dollar',
            'CHF': 'Swiss Franc',
            'SEK': 'Swedish Krona',
            'NOK': 'Norwegian Krone',
            'DKK': 'Danish Krone',
            'PLN': 'Polish Zloty',
            'CZK': 'Czech Koruna',
            'HUF': 'Hungarian Forint',
            'RUB': 'Russian Ruble',
            'BRL': 'Brazilian Real',
            'MXN': 'Mexican Peso',
            'SGD': 'Singapore Dollar',
            'HKD': 'Hong Kong Dollar',
            'NZD': 'New Zealand Dollar',
            'KRW': 'South Korean Won',
            'TRY': 'Turkish Lira',
            'ZAR': 'South African Rand',
            'THB': 'Thai Baht',
        }
    
    def convert(self, amount: Decimal, from_currency: str, to_currency: str) -> Decimal:
        """
        Convert amount from one currency to another.
        """
        try:
            if from_currency == to_currency:
                return amount
            
            # Get exchange rate
            rate = self.get_exchange_rate(from_currency, to_currency)
            
            if rate is None:
                logger.error(f"Could not get exchange rate for {from_currency} to {to_currency}")
                return amount  # Return original amount if conversion fails
            
            converted = amount * Decimal(str(rate))
            return converted.quantize(Decimal('0.01'))  # Round to 2 decimal places
            
        except Exception as e:
            logger.error(f"Error converting currency: {e}")
            return amount
    
    def get_exchange_rate(self, from_currency: str, to_currency: str) -> Optional[float]:
        """
        Get exchange rate between two currencies with caching.
        """
        try:
            cache_key = f"exchange_rate_{from_currency}_{to_currency}"
            
            # Check cache first
            cached_rate = cache.get(cache_key)
            if cached_rate is not None:
                return cached_rate
            
            # Try each provider until one succeeds
            for provider in self.providers:
                try:
                    rate = self._fetch_rate_from_provider(provider, from_currency, to_currency)
                    if rate is not None:
                        # Cache the rate
                        cache.set(cache_key, rate, self.cache_timeout)
                        return rate
                except Exception as e:
                    logger.warning(f"Provider {provider} failed: {e}")
                    continue
            
            # If all providers fail, try to get rate via base currency
            return self._get_rate_via_base_currency(from_currency, to_currency)
            
        except Exception as e:
            logger.error(f"Error getting exchange rate: {e}")
            return None
    
    def _fetch_rate_from_provider(self, provider: str, from_currency: str, to_currency: str) -> Optional[float]:
        """
        Fetch exchange rate from a specific provider.
        """
        try:
            if provider == 'fixer_io':
                return self._fetch_from_fixer_io(from_currency, to_currency)
            elif provider == 'exchangerate_api':
                return self._fetch_from_exchangerate_api(from_currency, to_currency)
            elif provider == 'openexchangerates':
                return self._fetch_from_openexchangerates(from_currency, to_currency)
            else:
                return None
                
        except Exception as e:
            logger.error(f"Error fetching from provider {provider}: {e}")
            return None
    
    def _fetch_from_fixer_io(self, from_currency: str, to_currency: str) -> Optional[float]:
        """
        Fetch rate from Fixer.io API.
        """
        try:
            api_key = getattr(settings, 'FIXER_IO_API_KEY', None)
            if not api_key:
                return None
            
            url = "http://data.fixer.io/api/latest"
            params = {
                'access_key': api_key,
                'base': from_currency,
                'symbols': to_currency
            }
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            if data.get('success') and to_currency in data.get('rates', {}):
                return float(data['rates'][to_currency])
            
            return None
            
        except Exception as e:
            logger.error(f"Error fetching from Fixer.io: {e}")
            return None
    
    def _fetch_from_exchangerate_api(self, from_currency: str, to_currency: str) -> Optional[float]:
        """
        Fetch rate from ExchangeRate-API.
        """
        try:
            url = f"https://api.exchangerate-api.com/v4/latest/{from_currency}"
            
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            if to_currency in data.get('rates', {}):
                return float(data['rates'][to_currency])
            
            return None
            
        except Exception as e:
            logger.error(f"Error fetching from ExchangeRate-API: {e}")
            return None
    
    def _fetch_from_openexchangerates(self, from_currency: str, to_currency: str) -> Optional[float]:
        """
        Fetch rate from OpenExchangeRates API.
        """
        try:
            api_key = getattr(settings, 'OPENEXCHANGERATES_API_KEY', None)
            if not api_key:
                return None
            
            url = "https://openexchangerates.org/api/latest.json"
            params = {
                'app_id': api_key,
                'base': from_currency,
                'symbols': to_currency
            }
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            if to_currency in data.get('rates', {}):
                return float(data['rates'][to_currency])
            
            return None
            
        except Exception as e:
            logger.error(f"Error fetching from OpenExchangeRates: {e}")
            return None
    
    def _get_rate_via_base_currency(self, from_currency: str, to_currency: str) -> Optional[float]:
        """
        Get exchange rate via base currency (USD) as intermediary.
        """
        try:
            if from_currency == self.base_currency:
                # Get direct rate to target currency
                return self._get_single_rate(self.base_currency, to_currency)
            elif to_currency == self.base_currency:
                # Get inverse rate
                rate = self._get_single_rate(from_currency, self.base_currency)
                return 1 / rate if rate else None
            else:
                # Convert via base currency: from -> base -> to
                rate_from_to_base = self._get_single_rate(from_currency, self.base_currency)
                rate_base_to_to = self._get_single_rate(self.base_currency, to_currency)
                
                if rate_from_to_base and rate_base_to_to:
                    return rate_from_to_base * rate_base_to_to
                
                return None
                
        except Exception as e:
            logger.error(f"Error getting rate via base currency: {e}")
            return None
    
    def _get_single_rate(self, from_currency: str, to_currency: str) -> Optional[float]:
        """
        Get a single exchange rate using any available provider.
        """
        try:
            for provider in self.providers:
                try:
                    rate = self._fetch_rate_from_provider(provider, from_currency, to_currency)
                    if rate is not None:
                        return rate
                except Exception:
                    continue
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting single rate: {e}")
            return None
    
    def get_supported_currencies(self) -> Dict[str, Dict[str, str]]:
        """
        Get list of supported currencies with their symbols and names.
        """
        currencies = {}
        
        for code, symbol in self.currency_symbols.items():
            currencies[code] = {
                'code': code,
                'symbol': symbol,
                'name': self.currency_names.get(code, code)
            }
        
        return currencies
    
    def format_amount(self, amount: Decimal, currency_code: str) -> str:
        """
        Format amount with currency symbol.
        """
        try:
            symbol = self.currency_symbols.get(currency_code, currency_code)
            
            # Format based on currency
            if currency_code in ['JPY', 'KRW', 'VND']:
                # No decimal places for these currencies
                formatted_amount = f"{amount:.0f}"
            else:
                formatted_amount = f"{amount:.2f}"
            
            # Symbol placement varies by currency
            if currency_code in ['USD', 'CAD', 'AUD', 'HKD', 'NZD', 'SGD', 'MXN']:
                return f"{symbol}{formatted_amount}"
            elif currency_code in ['EUR']:
                return f"{formatted_amount} {symbol}"
            else:
                return f"{symbol} {formatted_amount}"
                
        except Exception as e:
            logger.error(f"Error formatting amount: {e}")
            return f"{amount} {currency_code}"
    
    def get_currency_rates_for_base(self, base_currency: str, target_currencies: list) -> Dict[str, float]:
        """
        Get exchange rates for multiple currencies from a base currency.
        """
        try:
            rates = {}
            
            for target in target_currencies:
                if target == base_currency:
                    rates[target] = 1.0
                else:
                    rate = self.get_exchange_rate(base_currency, target)
                    if rate is not None:
                        rates[target] = rate
            
            return rates
            
        except Exception as e:
            logger.error(f"Error getting currency rates: {e}")
            return {}
    
    def is_valid_currency_code(self, code: str) -> bool:
        """
        Check if currency code is valid and supported.
        """
        return code.upper() in self.currency_symbols
    
    def clear_cache(self):
        """
        Clear all cached exchange rates.
        """
        try:
            # Clear all exchange rate cache keys
            for from_currency in self.currency_symbols:
                for to_currency in self.currency_symbols:
                    cache_key = f"exchange_rate_{from_currency}_{to_currency}"
                    cache.delete(cache_key)
            
            logger.info("Currency cache cleared")
            
        except Exception as e:
            logger.error(f"Error clearing currency cache: {e}")


class MultiCurrencyPriceManager:
    """
    Manager for handling product prices in multiple currencies.
    """
    
    def __init__(self):
        self.converter = CurrencyConverter()
    
    def convert_product_price(self, product, target_currency: str) -> Dict:
        """
        Convert a product's price to target currency.
        """
        try:
            original_price = Decimal(str(product.price))
            original_currency = getattr(product, 'currency', 'USD')
            
            if original_currency == target_currency:
                converted_price = original_price
            else:
                converted_price = self.converter.convert(
                    original_price, 
                    original_currency, 
                    target_currency
                )
            
            return {
                'original_price': float(original_price),
                'original_currency': original_currency,
                'converted_price': float(converted_price),
                'target_currency': target_currency,
                'formatted_price': self.converter.format_amount(converted_price, target_currency),
                'exchange_rate': float(converted_price / original_price) if original_price > 0 else 1
            }
            
        except Exception as e:
            logger.error(f"Error converting product price: {e}")
            return {
                'error': 'Price conversion failed',
                'original_price': float(product.price),
                'original_currency': getattr(product, 'currency', 'USD')
            }
    
    def get_inventory_value_in_currency(self, products_queryset, target_currency: str) -> Dict:
        """
        Calculate total inventory value in specified currency.
        """
        try:
            total_value = Decimal('0')
            product_count = 0
            conversion_errors = 0
            
            currency_breakdown = {}
            
            for product in products_queryset:
                try:
                    original_currency = getattr(product, 'currency', 'USD')
                    product_value = Decimal(str(product.price)) * product.quantity
                    
                    # Track by original currency
                    if original_currency not in currency_breakdown:
                        currency_breakdown[original_currency] = {
                            'count': 0,
                            'total_original_value': Decimal('0'),
                            'total_converted_value': Decimal('0')
                        }
                    
                    currency_breakdown[original_currency]['count'] += 1
                    currency_breakdown[original_currency]['total_original_value'] += product_value
                    
                    # Convert to target currency
                    if original_currency == target_currency:
                        converted_value = product_value
                    else:
                        converted_value = self.converter.convert(
                            product_value,
                            original_currency,
                            target_currency
                        )
                    
                    currency_breakdown[original_currency]['total_converted_value'] += converted_value
                    total_value += converted_value
                    product_count += 1
                    
                except Exception as e:
                    logger.error(f"Error converting product {product.id}: {e}")
                    conversion_errors += 1
                    continue
            
            # Format currency breakdown
            formatted_breakdown = {}
            for currency, data in currency_breakdown.items():
                formatted_breakdown[currency] = {
                    'product_count': data['count'],
                    'original_value': float(data['total_original_value']),
                    'converted_value': float(data['total_converted_value']),
                    'formatted_original': self.converter.format_amount(data['total_original_value'], currency),
                    'formatted_converted': self.converter.format_amount(data['total_converted_value'], target_currency)
                }
            
            return {
                'total_value': float(total_value),
                'target_currency': target_currency,
                'formatted_total': self.converter.format_amount(total_value, target_currency),
                'product_count': product_count,
                'conversion_errors': conversion_errors,
                'currency_breakdown': formatted_breakdown,
                'calculation_timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error calculating inventory value: {e}")
            return {
                'error': 'Inventory value calculation failed',
                'total_value': 0,
                'target_currency': target_currency
            }


# Global instances
currency_converter = CurrencyConverter()
price_manager = MultiCurrencyPriceManager()