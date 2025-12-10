"""
Utility Functions - Common helper functions used across the application.
Provides reusable utilities for validation, formatting, calculations, etc.
"""
import re
import uuid
import hashlib
import secrets
from decimal import Decimal, ROUND_HALF_UP
from datetime import datetime, date, timedelta
from typing import Any, Dict, List, Optional, Union
from django.utils import timezone
from django.core.validators import validate_email
from django.core.exceptions import ValidationError


# ============================================================
# String Utilities
# ============================================================

def generate_unique_code(prefix: str = '', length: int = 8) -> str:
    """Generate a unique code with optional prefix."""
    unique_part = secrets.token_hex(length // 2).upper()
    return f"{prefix}{unique_part}" if prefix else unique_part


def generate_barcode(product_type: str = 'PROD') -> str:
    """Generate a unique barcode number."""
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    random_part = secrets.token_hex(3).upper()
    return f"{product_type}-{timestamp}-{random_part}"


def generate_order_number(prefix: str = 'PO') -> str:
    """Generate a unique order number."""
    timestamp = datetime.now().strftime('%Y%m%d')
    random_part = secrets.token_hex(4).upper()
    return f"{prefix}-{timestamp}-{random_part}"


def slugify_text(text: str) -> str:
    """Convert text to URL-friendly slug."""
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[-\s]+', '-', text)
    return text


def truncate_text(text: str, max_length: int = 100, suffix: str = '...') -> str:
    """Truncate text to specified length."""
    if len(text) <= max_length:
        return text
    return text[:max_length - len(suffix)] + suffix


def mask_sensitive_data(data: str, visible_chars: int = 4) -> str:
    """Mask sensitive data like credit cards, phone numbers."""
    if len(data) <= visible_chars:
        return '*' * len(data)
    return '*' * (len(data) - visible_chars) + data[-visible_chars:]


# ============================================================
# Validation Utilities
# ============================================================

def validate_barcode_format(barcode: str) -> bool:
    """Validate barcode format."""
    # Support multiple barcode formats
    patterns = [
        r'^[0-9]{8,14}$',  # EAN-8, EAN-13, UPC-A, ITF-14
        r'^[A-Z0-9]{6,20}$',  # Alphanumeric codes
        r'^PROD-\d{14}-[A-F0-9]{6}$',  # Custom format
    ]
    return any(re.match(pattern, barcode) for pattern in patterns)


def validate_phone_number(phone: str) -> bool:
    """Validate phone number format."""
    pattern = r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$'
    return bool(re.match(pattern, phone))


def validate_email_address(email: str) -> bool:
    """Validate email address format."""
    try:
        validate_email(email)
        return True
    except ValidationError:
        return False


def validate_price(price: Union[str, float, Decimal]) -> bool:
    """Validate price value."""
    try:
        decimal_price = Decimal(str(price))
        return decimal_price >= 0
    except (ValueError, TypeError):
        return False


def validate_quantity(quantity: Union[int, str]) -> bool:
    """Validate quantity value."""
    try:
        int_quantity = int(quantity)
        return int_quantity >= 0
    except (ValueError, TypeError):
        return False


def validate_date_range(start_date: date, end_date: date) -> bool:
    """Validate that end_date is after start_date."""
    return end_date >= start_date


# ============================================================
# Calculation Utilities
# ============================================================

def calculate_profit_margin(cost_price: Decimal, selling_price: Decimal) -> Decimal:
    """Calculate profit margin percentage."""
    if cost_price == 0:
        return Decimal('0')
    profit = selling_price - cost_price
    margin = (profit / cost_price) * 100
    return margin.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


def calculate_markup(cost_price: Decimal, markup_percentage: Decimal) -> Decimal:
    """Calculate selling price based on markup percentage."""
    markup_multiplier = 1 + (markup_percentage / 100)
    return (cost_price * markup_multiplier).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


def calculate_discount(original_price: Decimal, discount_percentage: Decimal) -> Decimal:
    """Calculate discounted price."""
    discount_multiplier = 1 - (discount_percentage / 100)
    return (original_price * discount_multiplier).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


def calculate_tax(amount: Decimal, tax_rate: Decimal) -> Decimal:
    """Calculate tax amount."""
    return (amount * tax_rate / 100).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


def round_currency(amount: Decimal) -> Decimal:
    """Round amount to 2 decimal places for currency."""
    return amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


# ============================================================
# Date/Time Utilities
# ============================================================

def get_date_range(period: str) -> tuple:
    """Get start and end dates for common periods."""
    today = timezone.now().date()
    
    if period == 'today':
        return today, today
    elif period == 'yesterday':
        yesterday = today - timedelta(days=1)
        return yesterday, yesterday
    elif period == 'this_week':
        start = today - timedelta(days=today.weekday())
        return start, today
    elif period == 'last_week':
        end = today - timedelta(days=today.weekday() + 1)
        start = end - timedelta(days=6)
        return start, end
    elif period == 'this_month':
        start = today.replace(day=1)
        return start, today
    elif period == 'last_month':
        last_month = today.replace(day=1) - timedelta(days=1)
        start = last_month.replace(day=1)
        return start, last_month
    elif period == 'this_quarter':
        quarter = (today.month - 1) // 3
        start = date(today.year, quarter * 3 + 1, 1)
        return start, today
    elif period == 'this_year':
        start = date(today.year, 1, 1)
        return start, today
    else:
        return today - timedelta(days=30), today


def days_until(target_date: date) -> int:
    """Calculate days until a target date."""
    today = timezone.now().date()
    return (target_date - today).days


def format_date_for_display(dt: Union[datetime, date], format_str: str = '%B %d, %Y') -> str:
    """Format date for display."""
    if isinstance(dt, datetime):
        dt = dt.date()
    return dt.strftime(format_str)


def get_expiry_status(expiry_date: date, warning_days: int = 7) -> str:
    """Get expiry status based on expiry date."""
    if not expiry_date:
        return 'unknown'
    
    days_remaining = days_until(expiry_date)
    
    if days_remaining < 0:
        return 'expired'
    elif days_remaining <= warning_days:
        return 'expiring_soon'
    else:
        return 'fresh'


def get_expiry_color(status: str) -> str:
    """Get color code for expiry status."""
    colors = {
        'expired': '#F44336',  # Red
        'expiring_soon': '#FF9800',  # Orange
        'fresh': '#4CAF50',  # Green
        'unknown': '#9E9E9E',  # Grey
    }
    return colors.get(status, '#9E9E9E')


# ============================================================
# Data Transformation Utilities
# ============================================================

def dict_to_query_string(params: Dict[str, Any]) -> str:
    """Convert dictionary to URL query string."""
    return '&'.join(f"{k}={v}" for k, v in params.items() if v is not None)


def flatten_dict(d: Dict, parent_key: str = '', sep: str = '.') -> Dict:
    """Flatten nested dictionary."""
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)


def group_by(items: List[Dict], key: str) -> Dict[str, List[Dict]]:
    """Group list of dictionaries by a key."""
    result = {}
    for item in items:
        group_key = item.get(key)
        if group_key not in result:
            result[group_key] = []
        result[group_key].append(item)
    return result


def chunk_list(lst: List, chunk_size: int) -> List[List]:
    """Split list into chunks of specified size."""
    return [lst[i:i + chunk_size] for i in range(0, len(lst), chunk_size)]


# ============================================================
# Hash Utilities
# ============================================================

def generate_hash(data: str) -> str:
    """Generate SHA-256 hash of data."""
    return hashlib.sha256(data.encode()).hexdigest()


def generate_checksum(file_content: bytes) -> str:
    """Generate MD5 checksum for file content."""
    return hashlib.md5(file_content).hexdigest()


def generate_secure_token(length: int = 32) -> str:
    """Generate a secure random token."""
    return secrets.token_urlsafe(length)


# ============================================================
# Stock Utilities
# ============================================================

def calculate_reorder_point(
    average_daily_sales: Decimal,
    lead_time_days: int,
    safety_stock_days: int = 3
) -> int:
    """Calculate reorder point for a product."""
    reorder_point = average_daily_sales * (lead_time_days + safety_stock_days)
    return int(reorder_point.quantize(Decimal('1'), rounding=ROUND_HALF_UP))


def calculate_economic_order_quantity(
    annual_demand: int,
    ordering_cost: Decimal,
    holding_cost_per_unit: Decimal
) -> int:
    """Calculate Economic Order Quantity (EOQ)."""
    if holding_cost_per_unit <= 0:
        return annual_demand
    
    eoq = ((2 * annual_demand * float(ordering_cost)) / float(holding_cost_per_unit)) ** 0.5
    return int(round(eoq))


def get_stock_status(quantity: int, min_level: int, reorder_level: int) -> str:
    """Get stock status based on quantity and thresholds."""
    if quantity <= 0:
        return 'out_of_stock'
    elif quantity <= min_level:
        return 'critical'
    elif quantity <= reorder_level:
        return 'low'
    else:
        return 'adequate'


def get_stock_color(status: str) -> str:
    """Get color code for stock status."""
    colors = {
        'out_of_stock': '#F44336',  # Red
        'critical': '#FF5722',  # Deep Orange
        'low': '#FF9800',  # Orange
        'adequate': '#4CAF50',  # Green
    }
    return colors.get(status, '#9E9E9E')
