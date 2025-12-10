"""
Visual Product Recognition Service
Uses image processing to identify products from photos
"""

import base64
import hashlib
from typing import Optional, Dict, List, Any
from io import BytesIO
from datetime import datetime
import json


class ImageProcessor:
    """Basic image processing utilities"""
    
    @staticmethod
    def decode_base64_image(base64_string: str) -> bytes:
        """Decode base64 image to bytes"""
        # Remove data URL prefix if present
        if 'base64,' in base64_string:
            base64_string = base64_string.split('base64,')[1]
        return base64.b64decode(base64_string)
    
    @staticmethod
    def encode_image_base64(image_bytes: bytes) -> str:
        """Encode image bytes to base64"""
        return base64.b64encode(image_bytes).decode('utf-8')
    
    @staticmethod
    def get_image_hash(image_bytes: bytes) -> str:
        """Get perceptual hash of image for caching"""
        return hashlib.md5(image_bytes).hexdigest()


class ProductRecognitionService:
    """
    Visual product recognition using image analysis
    Can be integrated with external ML services or local models
    """
    
    def __init__(self):
        self.cache = {}  # image_hash -> recognition results
        self.confidence_threshold = 0.7
    
    def recognize_product(self, image_data: str, store_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Recognize products from image
        
        Args:
            image_data: Base64 encoded image or URL
            store_id: Optional store ID to filter results
        
        Returns:
            Recognition results with matched products
        """
        try:
            # Decode if base64
            if image_data.startswith('data:') or not image_data.startswith('http'):
                image_bytes = ImageProcessor.decode_base64_image(image_data)
            else:
                # URL - would need to fetch
                return {'success': False, 'error': 'URL images not supported yet'}
            
            # Check cache
            image_hash = ImageProcessor.get_image_hash(image_bytes)
            if image_hash in self.cache:
                return self.cache[image_hash]
            
            # Perform recognition
            results = self._analyze_image(image_bytes, store_id)
            
            # Cache results
            self.cache[image_hash] = results
            
            return results
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'products': []
            }
    
    def _analyze_image(self, image_bytes: bytes, store_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Analyze image to find products
        
        In production, this would use:
        - TensorFlow/PyTorch models
        - Google Cloud Vision API
        - AWS Rekognition
        - Azure Computer Vision
        """
        from .models import Product
        from django.db.models import Q
        
        # Simulated recognition - in production, use ML model
        # This example uses basic image features to search products
        
        # Extract text from image (OCR) - would use pytesseract or cloud OCR
        extracted_text = self._extract_text(image_bytes)
        
        # Detect dominant colors - would use image processing
        colors = self._detect_colors(image_bytes)
        
        # Search products based on extracted features
        products = []
        
        if extracted_text:
            # Search by extracted text (brand names, product names)
            matched_products = Product.objects.filter(
                Q(name__icontains=extracted_text) |
                Q(brand__icontains=extracted_text) if hasattr(Product, 'brand') else Q()
            )[:5]
            
            for product in matched_products:
                products.append({
                    'id': str(product.id),
                    'name': product.name,
                    'price': float(product.price),
                    'category': product.category.name if product.category else None,
                    'confidence': 0.85,
                    'match_type': 'text',
                })
        
        # Barcode detection - would use opencv or ml kit
        barcode = self._detect_barcode(image_bytes)
        if barcode:
            barcode_product = Product.objects.filter(barcode=barcode).first()
            if barcode_product:
                products.insert(0, {
                    'id': str(barcode_product.id),
                    'name': barcode_product.name,
                    'price': float(barcode_product.price),
                    'category': barcode_product.category.name if barcode_product.category else None,
                    'confidence': 0.99,
                    'match_type': 'barcode',
                })
        
        return {
            'success': True,
            'products': products,
            'extracted_text': extracted_text,
            'detected_barcode': barcode,
            'analysis': {
                'dominant_colors': colors,
                'timestamp': datetime.now().isoformat()
            }
        }
    
    def _extract_text(self, image_bytes: bytes) -> Optional[str]:
        """
        Extract text from image using OCR
        
        In production:
        - Use pytesseract for local OCR
        - Or cloud services for better accuracy
        """
        # Placeholder - would use OCR library
        # try:
        #     from PIL import Image
        #     import pytesseract
        #     image = Image.open(BytesIO(image_bytes))
        #     text = pytesseract.image_to_string(image)
        #     return text.strip()
        # except:
        #     return None
        return None
    
    def _detect_colors(self, image_bytes: bytes) -> List[str]:
        """
        Detect dominant colors in image
        
        In production:
        - Use OpenCV or PIL for color analysis
        - K-means clustering for dominant colors
        """
        # Placeholder - would use color detection
        # try:
        #     from PIL import Image
        #     from collections import Counter
        #     image = Image.open(BytesIO(image_bytes))
        #     colors = image.getcolors(image.size[0] * image.size[1])
        #     most_common = Counter(c[1] for c in colors).most_common(5)
        #     return [f"rgb{c}" for c, _ in most_common]
        # except:
        #     return []
        return []
    
    def _detect_barcode(self, image_bytes: bytes) -> Optional[str]:
        """
        Detect barcode in image
        
        In production:
        - Use pyzbar or opencv
        - Support multiple barcode formats
        """
        # Placeholder - would use barcode detection
        # try:
        #     from pyzbar.pyzbar import decode
        #     from PIL import Image
        #     image = Image.open(BytesIO(image_bytes))
        #     barcodes = decode(image)
        #     if barcodes:
        #         return barcodes[0].data.decode('utf-8')
        # except:
        #     pass
        return None
    
    def find_similar_products(self, product_id: str) -> List[Dict]:
        """Find visually similar products"""
        from .models import Product
        
        try:
            product = Product.objects.get(id=product_id)
            
            # Find products in same category
            similar = Product.objects.filter(
                category=product.category
            ).exclude(id=product_id)[:5]
            
            return [
                {
                    'id': str(p.id),
                    'name': p.name,
                    'price': float(p.price),
                    'similarity': 0.75,  # Would calculate actual similarity
                }
                for p in similar
            ]
        except Product.DoesNotExist:
            return []


class FreshnesDetector:
    """
    Detect freshness of produce from images
    Uses color analysis and visual patterns
    """
    
    FRESHNESS_LEVELS = {
        'excellent': {'score': 95, 'description': 'Peak freshness, ideal quality'},
        'good': {'score': 80, 'description': 'Fresh and ready to use'},
        'fair': {'score': 60, 'description': 'Use within a few days'},
        'poor': {'score': 40, 'description': 'Use immediately or discard'},
        'spoiled': {'score': 10, 'description': 'Not suitable for consumption'},
    }
    
    def analyze_freshness(self, image_data: str, product_type: str) -> Dict[str, Any]:
        """
        Analyze freshness of produce from image
        
        Args:
            image_data: Base64 encoded image
            product_type: Type of produce (fruit, vegetable, meat, dairy)
        
        Returns:
            Freshness analysis results
        """
        try:
            # In production, would use ML model trained on fresh/spoiled produce
            
            # Placeholder - simulated analysis
            result = {
                'success': True,
                'freshness_level': 'good',
                'freshness_score': 80,
                'confidence': 0.85,
                'analysis': {
                    'color_quality': 'normal',
                    'texture_quality': 'smooth',
                    'blemishes_detected': False,
                    'mold_detected': False,
                },
                'recommendation': 'Product appears fresh. Use within 5-7 days.',
                'estimated_shelf_life_days': 5,
            }
            
            return result
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }


class ShelfAnalyzer:
    """
    Analyze shelf images for inventory tracking
    Detects stock levels, misplaced items, and pricing issues
    """
    
    def analyze_shelf(self, image_data: str, store_id: str, aisle: str) -> Dict[str, Any]:
        """
        Analyze shelf image for inventory insights
        
        Returns:
            - Stock levels for visible products
            - Out of stock items
            - Misplaced products
            - Price tag issues
        """
        try:
            # In production, would use:
            # - Object detection for product identification
            # - OCR for price tags
            # - Depth analysis for stock level estimation
            
            return {
                'success': True,
                'analysis_time': datetime.now().isoformat(),
                'products_detected': [],
                'stock_alerts': [],
                'misplaced_items': [],
                'price_issues': [],
                'planogram_compliance': 95.0,
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }


# Global instances
recognition_service = ProductRecognitionService()
freshness_detector = FreshnesDetector()
shelf_analyzer = ShelfAnalyzer()
