"""
API views for receipt OCR processing.
"""
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
import os
import re
import logging
import tempfile

from .models import Product, Category
from .receipt_ocr import ReceiptOCRProcessor
from .serializers import ProductSerializer

logger = logging.getLogger(__name__)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def process_receipt_ocr(request):
    """
    Process receipt image using OCR to extract product information.
    """
    try:
        if 'receipt_image' not in request.FILES:
            return Response({
                'error': 'No receipt image provided',
                'message': 'Please upload a receipt image'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        receipt_image = request.FILES['receipt_image']
        
        # Validate image format
        allowed_formats = ['image/jpeg', 'image/jpg', 'image/png']
        if receipt_image.content_type not in allowed_formats:
            return Response({
                'error': 'Invalid image format',
                'message': 'Please upload a JPEG or PNG image',
                'allowed_formats': allowed_formats
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate image size (max 10MB)
        if receipt_image.size > 10 * 1024 * 1024:
            return Response({
                'error': 'Image too large',
                'message': 'Please upload an image smaller than 10MB'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Save image temporarily
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as temp_file:
            for chunk in receipt_image.chunks():
                temp_file.write(chunk)
            temp_image_path = temp_file.name
        
        try:
            # Process the receipt
            processor = ReceiptOCRProcessor()
            result = processor.process_receipt(temp_image_path)
            
            if not result['success']:
                return Response({
                    'error': 'OCR processing failed',
                    'message': result.get('error', 'Unknown error occurred'),
                    'suggestions': [
                        'Ensure the receipt is clearly visible',
                        'Use good lighting',
                        'Keep the image straight and in focus',
                        'Try a different angle or distance'
                    ]
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Process extracted items for database matching
            processed_items = process_extracted_items(result['items'], request.user)
            
            return Response({
                'success': True,
                'extraction_results': {
                    'store_info': result['store_info'],
                    'extracted_text': result['extracted_text'],
                    'raw_items': result['items'],
                    'total_amount': result['total_amount'],
                    'confidence_score': result['confidence_score'],
                    'processing_notes': result['processing_notes']
                },
                'processed_items': processed_items,
                'summary': {
                    'total_items_detected': len(result['items']),
                    'items_matched_to_existing': len([item for item in processed_items if item.get('existing_product_id')]),
                    'new_items_to_create': len([item for item in processed_items if not item.get('existing_product_id')]),
                    'confidence_level': get_confidence_level(result['confidence_score'])
                }
            })
            
        finally:
            # Clean up temporary file
            if os.path.exists(temp_image_path):
                os.unlink(temp_image_path)
                
    except Exception as e:
        logger.error(f"Error processing receipt OCR: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_products_from_receipt(request):
    """
    Create products based on processed receipt data.
    """
    try:
        receipt_items = request.data.get('items', [])
        
        if not receipt_items:
            return Response({
                'error': 'No items provided',
                'message': 'Please provide items to create'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        created_products = []
        updated_products = []
        errors = []
        
        for item in receipt_items:
            try:
                product_data = item.get('product_data', {})
                action = item.get('action', 'create')  # 'create', 'update', or 'skip'
                
                if action == 'skip':
                    continue
                
                if action == 'update' and item.get('existing_product_id'):
                    # Update existing product
                    product = Product.objects.get(
                        id=item['existing_product_id'],
                        created_by=request.user
                    )
                    
                    # Update quantity if provided
                    quantity_change = product_data.get('quantity', 0)
                    if quantity_change > 0:
                        product.quantity += quantity_change
                        product.save()
                        
                        updated_products.append({
                            'id': product.id,
                            'name': product.name,
                            'quantity_added': quantity_change,
                            'new_quantity': product.quantity
                        })
                
                elif action == 'create':
                    # Create new product
                    product = create_product_from_receipt_data(product_data, request.user)
                    if product:
                        created_products.append(ProductSerializer(product).data)
                    else:
                        errors.append(f"Failed to create product: {product_data.get('name', 'Unknown')}")
                        
            except Product.DoesNotExist:
                errors.append(f"Product not found: {item.get('existing_product_id')}")
            except Exception as e:
                logger.error(f"Error processing item {item}: {e}")
                errors.append(f"Error processing item: {str(e)}")
        
        return Response({
            'success': True,
            'results': {
                'created_products': created_products,
                'updated_products': updated_products,
                'errors': errors
            },
            'summary': {
                'total_processed': len(receipt_items),
                'created_count': len(created_products),
                'updated_count': len(updated_products),
                'error_count': len(errors)
            }
        })
        
    except Exception as e:
        logger.error(f"Error creating products from receipt: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_existing_products(request):
    """
    Search for existing products by name for receipt matching.
    """
    try:
        query = request.GET.get('q', '').strip()
        
        if len(query) < 2:
            return Response({
                'error': 'Query too short',
                'message': 'Please provide at least 2 characters'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Search products by name
        products = Product.objects.filter(
            created_by=request.user,
            is_deleted=False,
            name__icontains=query
        ).order_by('name')[:10]  # Limit to 10 results
        
        results = []
        for product in products:
            results.append({
                'id': product.id,
                'name': product.name,
                'price': float(product.price),
                'quantity': product.quantity,
                'category': product.category.name if product.category else None,
                'similarity_score': calculate_name_similarity(query, product.name)
            })
        
        # Sort by similarity score
        results.sort(key=lambda x: x['similarity_score'], reverse=True)
        
        return Response({
            'query': query,
            'results': results,
            'total_found': len(results)
        })
        
    except Exception as e:
        logger.error(f"Error searching existing products: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def process_extracted_items(raw_items: list, user) -> list:
    """
    Process extracted items to match with existing products and prepare for creation.
    """
    processed_items = []
    
    try:
        for item in raw_items:
            # Search for existing products with similar names
            similar_products = find_similar_products(item['name'], user)
            
            processed_item = {
                'raw_data': item,
                'suggested_name': clean_product_name(item['name']),
                'suggested_price': item['price'],
                'suggested_quantity': item['quantity'],
                'similar_products': similar_products,
                'confidence_score': calculate_item_confidence(item),
                'recommended_action': determine_recommended_action(item, similar_products)
            }
            
            # If we found a very similar product, suggest updating it
            if similar_products and similar_products[0]['similarity_score'] > 0.8:
                processed_item['existing_product_id'] = similar_products[0]['id']
                processed_item['recommended_action'] = 'update'
            
            processed_items.append(processed_item)
            
    except Exception as e:
        logger.error(f"Error processing extracted items: {e}")
    
    return processed_items


def find_similar_products(product_name: str, user) -> list:
    """
    Find existing products with similar names.
    """
    try:
        # Clean the product name
        clean_name = clean_product_name(product_name)
        
        if len(clean_name) < 2:
            return []
        
        # Search for products with similar names
        products = Product.objects.filter(
            created_by=user,
            is_deleted=False,
            name__icontains=clean_name[:10]  # Use first 10 characters for broad search
        )
        
        similar_products = []
        for product in products:
            similarity = calculate_name_similarity(clean_name, product.name)
            if similarity > 0.3:  # Minimum similarity threshold
                similar_products.append({
                    'id': product.id,
                    'name': product.name,
                    'price': float(product.price),
                    'quantity': product.quantity,
                    'category': product.category.name if product.category else None,
                    'similarity_score': similarity
                })
        
        # Sort by similarity
        similar_products.sort(key=lambda x: x['similarity_score'], reverse=True)
        
        return similar_products[:5]  # Return top 5 matches
        
    except Exception as e:
        logger.error(f"Error finding similar products: {e}")
        return []


def calculate_name_similarity(name1: str, name2: str) -> float:
    """
    Calculate similarity between two product names using a simple algorithm.
    """
    try:
        # Convert to lowercase and remove special characters
        clean1 = re.sub(r'[^\w\s]', '', name1.lower())
        clean2 = re.sub(r'[^\w\s]', '', name2.lower())
        
        words1 = set(clean1.split())
        words2 = set(clean2.split())
        
        if not words1 or not words2:
            return 0.0
        
        # Jaccard similarity
        intersection = len(words1.intersection(words2))
        union = len(words1.union(words2))
        
        jaccard = intersection / union if union > 0 else 0
        
        # Also consider substring matching
        substring_score = 0
        for word1 in words1:
            for word2 in words2:
                if len(word1) >= 3 and len(word2) >= 3:
                    if word1 in word2 or word2 in word1:
                        substring_score += 0.1
        
        return min(1.0, jaccard + substring_score)
        
    except Exception as e:
        logger.error(f"Error calculating name similarity: {e}")
        return 0.0


def clean_product_name(name: str) -> str:
    """
    Clean and standardize product name.
    """
    try:
        # Remove extra spaces and special characters
        cleaned = re.sub(r'\s+', ' ', name)
        cleaned = cleaned.strip()
        
        # Capitalize first letter of each word
        cleaned = ' '.join(word.capitalize() for word in cleaned.split())
        
        return cleaned
        
    except Exception as e:
        logger.error(f"Error cleaning product name: {e}")
        return name


def calculate_item_confidence(item: dict) -> float:
    """
    Calculate confidence score for an extracted item.
    """
    try:
        score = 0.5  # Base score
        
        # Name quality
        name_length = len(item.get('name', ''))
        if name_length >= 5:
            score += 0.2
        elif name_length >= 3:
            score += 0.1
        
        # Price reasonableness
        price = item.get('price', 0)
        if 0.1 <= price <= 1000:
            score += 0.2
        
        # Quantity reasonableness
        quantity = item.get('quantity', 0)
        if 1 <= quantity <= 50:
            score += 0.1
        
        return min(1.0, max(0.0, score))
        
    except Exception as e:
        logger.error(f"Error calculating item confidence: {e}")
        return 0.5


def determine_recommended_action(item: dict, similar_products: list) -> str:
    """
    Determine recommended action for an extracted item.
    """
    try:
        if not similar_products:
            return 'create'
        
        best_match = similar_products[0]
        
        if best_match['similarity_score'] > 0.8:
            return 'update'
        elif best_match['similarity_score'] > 0.5:
            return 'review'  # User should review before deciding
        else:
            return 'create'
            
    except Exception as e:
        logger.error(f"Error determining recommended action: {e}")
        return 'create'


def create_product_from_receipt_data(product_data: dict, user) -> Product:
    """
    Create a new product from receipt data.
    """
    try:
        # Get or create default category
        category, _ = Category.objects.get_or_create(
            name='Receipt Items',
            created_by=user,
            defaults={
                'description': 'Items imported from receipts',
                'color': '#FF9800'
            }
        )
        
        # Create product
        product = Product.objects.create(
            name=clean_product_name(product_data.get('name', 'Unknown Item')),
            price=max(0, float(product_data.get('price', 0))),
            quantity=max(0, int(product_data.get('quantity', 1))),
            category=category,
            created_by=user,
            description='Imported from receipt scan'
        )
        
        return product
        
    except Exception as e:
        logger.error(f"Error creating product from receipt data: {e}")
        return None


def get_confidence_level(score: float) -> str:
    """
    Convert confidence score to human-readable level.
    """
    if score >= 0.8:
        return 'high'
    elif score >= 0.6:
        return 'medium'
    elif score >= 0.4:
        return 'low'
    else:
        return 'very_low'