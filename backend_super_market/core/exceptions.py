"""
Custom Exception Classes - Standardized exception handling across the application.
Provides consistent error responses and logging.
"""
from rest_framework import status
from rest_framework.exceptions import APIException


class SuperMartBaseException(APIException):
    """Base exception for all SuperMart custom exceptions."""
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    default_detail = "An unexpected error occurred."
    default_code = "internal_error"


class ValidationError(SuperMartBaseException):
    """Exception for data validation errors."""
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = "Invalid data provided."
    default_code = "validation_error"


class AuthenticationError(SuperMartBaseException):
    """Exception for authentication failures."""
    status_code = status.HTTP_401_UNAUTHORIZED
    default_detail = "Authentication credentials were not provided or are invalid."
    default_code = "authentication_error"


class AuthorizationError(SuperMartBaseException):
    """Exception for authorization failures."""
    status_code = status.HTTP_403_FORBIDDEN
    default_detail = "You do not have permission to perform this action."
    default_code = "authorization_error"


class ResourceNotFoundError(SuperMartBaseException):
    """Exception when requested resource is not found."""
    status_code = status.HTTP_404_NOT_FOUND
    default_detail = "The requested resource was not found."
    default_code = "not_found"


class ConflictError(SuperMartBaseException):
    """Exception for resource conflicts (e.g., duplicate entries)."""
    status_code = status.HTTP_409_CONFLICT
    default_detail = "A conflict occurred with the current state of the resource."
    default_code = "conflict"


class RateLimitExceededError(SuperMartBaseException):
    """Exception when rate limit is exceeded."""
    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    default_detail = "Rate limit exceeded. Please try again later."
    default_code = "rate_limit_exceeded"


class ServiceUnavailableError(SuperMartBaseException):
    """Exception when a dependent service is unavailable."""
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_detail = "Service temporarily unavailable. Please try again later."
    default_code = "service_unavailable"


# Business Logic Exceptions

class InsufficientStockError(ValidationError):
    """Exception when stock is insufficient for an operation."""
    default_detail = "Insufficient stock available for this operation."
    default_code = "insufficient_stock"


class ProductExpiredError(ValidationError):
    """Exception when trying to process an expired product."""
    default_detail = "Cannot process expired products."
    default_code = "product_expired"


class InvalidBarcodeError(ValidationError):
    """Exception for invalid barcode format."""
    default_detail = "Invalid barcode format provided."
    default_code = "invalid_barcode"


class DuplicateBarcodeError(ConflictError):
    """Exception when barcode already exists."""
    default_detail = "A product with this barcode already exists."
    default_code = "duplicate_barcode"


class PriceValidationError(ValidationError):
    """Exception for price-related validation errors."""
    default_detail = "Invalid price configuration."
    default_code = "price_validation_error"


class StoreTransferError(ValidationError):
    """Exception for inter-store transfer failures."""
    default_detail = "Store transfer operation failed."
    default_code = "transfer_error"


class SupplierConnectionError(ServiceUnavailableError):
    """Exception when supplier integration fails."""
    default_detail = "Unable to connect to supplier system."
    default_code = "supplier_connection_error"


class ReportGenerationError(SuperMartBaseException):
    """Exception when report generation fails."""
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    default_detail = "Failed to generate report."
    default_code = "report_generation_error"


class NotificationDeliveryError(SuperMartBaseException):
    """Exception when notification delivery fails."""
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    default_detail = "Failed to deliver notification."
    default_code = "notification_delivery_error"
