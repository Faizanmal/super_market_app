"""
Enhanced barcode API views for SuperMart Manager.
"""
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
import logging

from .models import Product
from .barcode_utils import barcode_generator, barcode_scanner
from .serializers import ProductSerializer

logger = logging.getLogger(__name__)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_supported_barcode_formats(request):
    """
    Get list of supported barcode formats.
    """
    try:
        return Response({
            'supported_formats': barcode_generator.supported_formats,
            'recommended_formats': {
                'retail': 'ean13',
                'general': 'code128',
                'mobile': 'qrcode',
                'compact': 'ean8'
            },
            'format_descriptions': {
                'ean13': 'International standard for retail products (13 digits)',
                'ean8': 'Compact version of EAN for small products (8 digits)',
                'upc_a': 'North American standard for retail products (12 digits)',
                'code128': 'High-density alphanumeric barcode, very versatile',
                'code39': 'Alphanumeric barcode, widely supported',
                'qrcode': '2D code that can store URLs, text, and other data'
            }
        })
        
    except Exception as e:
        logger.error(f"Error getting supported barcode formats: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_barcode(request):
    """
    Generate a barcode with custom data and format.
    """
    try:
        data = request.data.get('data')
        barcode_format = request.data.get('format', 'code128')
        options = request.data.get('options', {})
        
        # Validation
        if not data:
            return Response({
                'error': 'Barcode data required',
                'message': 'Please provide data to encode in the barcode'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if barcode_format not in barcode_generator.supported_formats:
            return Response({
                'error': 'Unsupported barcode format',
                'message': f'Supported formats: {list(barcode_generator.supported_formats.keys())}',
                'provided_format': barcode_format
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Generate barcode
        result = barcode_generator.generate_barcode(data, barcode_format, options)
        
        if not result['success']:
            return Response({
                'error': 'Barcode generation failed',
                'message': result.get('error', 'Unknown error'),
                'data': data,
                'format': barcode_format
            }, status=status.HTTP_400_BAD_REQUEST)
        
        return Response({
            'barcode_result': result,
            'generation_options': options,
            'format_info': {
                'format_code': barcode_format,
                'format_name': barcode_generator.supported_formats[barcode_format]
            }
        })
        
    except Exception as e:
        logger.error(f"Error generating barcode: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_product_barcode(request, product_id):
    """
    Generate barcode for a specific product.
    """
    try:
        product = get_object_or_404(Product, id=product_id, created_by=request.user)
        barcode_format = request.data.get('format', 'code128')
        
        # Validate format
        if barcode_format not in barcode_generator.supported_formats:
            return Response({
                'error': 'Unsupported barcode format',
                'supported_formats': list(barcode_generator.supported_formats.keys())
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Generate product-specific barcode
        result = barcode_generator.generate_product_barcode(
            product.id, 
            product.name, 
            barcode_format
        )
        
        if not result['success']:
            return Response({
                'error': 'Failed to generate product barcode',
                'message': result.get('error', 'Unknown error'),
                'product_id': product_id
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Optionally save barcode to product
        save_to_product = request.data.get('save_barcode', False)
        if save_to_product and hasattr(product, 'barcode'):
            product.barcode = result['barcode_data']
            product.save()
            result['saved_to_product'] = True
        
        return Response({
            'product_info': ProductSerializer(product).data,
            'barcode_result': result,
            'generation_timestamp': 'current'
        })
        
    except Exception as e:
        logger.error(f"Error generating product barcode: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_barcode_label(request, product_id):
    """
    Create a complete barcode label with product information.
    """
    try:
        product = get_object_or_404(Product, id=product_id, created_by=request.user)
        barcode_format = request.data.get('format', 'code128')
        custom_barcode_data = request.data.get('barcode_data')
        
        # Use custom barcode data or generate from product ID
        if custom_barcode_data:
            barcode_data = custom_barcode_data
        else:
            if barcode_format in ['ean13', 'ean8', 'upc_a']:
                barcode_data = str(product.id).zfill(12)[:12]
            else:
                barcode_data = f"PROD-{product.id}"
        
        # Format price
        from .currency_utils import currency_converter
        product_currency = getattr(product, 'currency', 'USD')
        formatted_price = currency_converter.format_amount(product.price, product_currency)
        
        # Create barcode label
        result = barcode_generator.create_barcode_label(
            barcode_data,
            product.name,
            formatted_price,
            barcode_format
        )
        
        if not result['success']:
            return Response({
                'error': 'Failed to create barcode label',
                'message': result.get('error', 'Unknown error')
            }, status=status.HTTP_400_BAD_REQUEST)
        
        return Response({
            'product_info': ProductSerializer(product).data,
            'label_result': result,
            'label_details': {
                'barcode_data': barcode_data,
                'formatted_price': formatted_price,
                'currency': product_currency
            }
        })
        
    except Exception as e:
        logger.error(f"Error creating barcode label: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def batch_generate_barcodes(request):
    """
    Generate barcodes for multiple products in batch.
    """
    try:
        product_ids = request.data.get('product_ids', [])
        barcode_format = request.data.get('format', 'code128')
        
        if not product_ids:
            return Response({
                'error': 'No product IDs provided',
                'message': 'Please provide a list of product IDs'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if len(product_ids) > 50:
            return Response({
                'error': 'Too many products',
                'message': 'Maximum 50 products allowed per batch',
                'provided_count': len(product_ids)
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get products
        products = Product.objects.filter(
            id__in=product_ids,
            created_by=request.user,
            is_deleted=False
        )
        
        if not products.exists():
            return Response({
                'error': 'No valid products found',
                'message': 'No products found with the provided IDs'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Prepare products data for batch generation
        products_data = []
        for product in products:
            products_data.append({
                'id': product.id,
                'name': product.name,
                'price': float(product.price)
            })
        
        # Generate barcodes in batch
        batch_result = barcode_generator.batch_generate_barcodes(products_data, barcode_format)
        
        return Response({
            'batch_generation_result': batch_result,
            'request_details': {
                'requested_products': len(product_ids),
                'found_products': len(products_data),
                'barcode_format': barcode_format
            }
        })
        
    except Exception as e:
        logger.error(f"Error in batch barcode generation: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def scan_barcode_from_image(request):
    """
    Scan and decode barcode from uploaded image.
    """
    try:
        if 'barcode_image' not in request.FILES:
            return Response({
                'error': 'No image provided',
                'message': 'Please upload a barcode image'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        barcode_image = request.FILES['barcode_image']
        
        # Validate image format
        allowed_formats = ['image/jpeg', 'image/jpg', 'image/png']
        if barcode_image.content_type not in allowed_formats:
            return Response({
                'error': 'Invalid image format',
                'message': 'Please upload a JPEG or PNG image',
                'allowed_formats': allowed_formats
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Read image data
        image_data = barcode_image.read()
        
        # Scan barcode
        scan_result = barcode_scanner.decode_barcode_from_image(image_data)
        
        if not scan_result.get('success'):
            return Response({
                'scan_result': scan_result,
                'suggestions': [
                    'Ensure the barcode is clearly visible and in focus',
                    'Try better lighting conditions',
                    'Make sure the entire barcode is captured',
                    'Try a different angle or distance'
                ]
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Try to find matching product
        barcode_data = scan_result.get('barcode_data')
        matching_product = None
        
        if barcode_data:
            # Search for product with matching barcode
            products = Product.objects.filter(
                created_by=request.user,
                is_deleted=False
            )
            
            # Simple search by barcode data or product ID
            for product in products:
                product_barcode = f"PROD-{product.id}"
                if (hasattr(product, 'barcode') and product.barcode == barcode_data) or product_barcode == barcode_data:
                    matching_product = ProductSerializer(product).data
                    break
        
        return Response({
            'scan_result': scan_result,
            'matching_product': matching_product,
            'image_info': {
                'filename': barcode_image.name,
                'size': barcode_image.size,
                'content_type': barcode_image.content_type
            }
        })
        
    except Exception as e:
        logger.error(f"Error scanning barcode from image: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def validate_barcode(request):
    """
    Validate barcode data against specified format.
    """
    try:
        barcode_data = request.data.get('barcode_data')
        barcode_format = request.data.get('format')
        
        if not all([barcode_data, barcode_format]):
            return Response({
                'error': 'Missing required fields',
                'required_fields': ['barcode_data', 'format']
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate barcode
        validation_result = barcode_scanner.validate_barcode_format(barcode_data, barcode_format)
        
        return Response({
            'validation_result': validation_result,
            'barcode_info': {
                'data': barcode_data,
                'format': barcode_format,
                'length': len(barcode_data)
            }
        })
        
    except Exception as e:
        logger.error(f"Error validating barcode: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_product_by_barcode(request):
    """
    Search for products by barcode data.
    """
    try:
        barcode_query = request.GET.get('barcode', '').strip()
        
        if not barcode_query:
            return Response({
                'error': 'Barcode parameter required',
                'message': 'Please provide a barcode to search for'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Search products
        matching_products = []
        
        products = Product.objects.filter(
            created_by=request.user,
            is_deleted=False
        )
        
        for product in products:
            # Check if product has stored barcode
            if hasattr(product, 'barcode') and product.barcode == barcode_query:
                matching_products.append({
                    'product': ProductSerializer(product).data,
                    'match_type': 'exact_barcode'
                })
                continue
            
            # Check generated barcode patterns
            generated_patterns = [
                f"PROD-{product.id}",
                str(product.id).zfill(12)[:12],
                str(product.id)
            ]
            
            if barcode_query in generated_patterns:
                matching_products.append({
                    'product': ProductSerializer(product).data,
                    'match_type': 'generated_pattern'
                })
        
        return Response({
            'search_query': barcode_query,
            'matching_products': matching_products,
            'total_matches': len(matching_products),
            'search_patterns': [
                'Stored product barcodes',
                'Generated product patterns (PROD-{id})',
                'Numeric product IDs'
            ]
        })
        
    except Exception as e:
        logger.error(f"Error searching product by barcode: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)