"""
Enhanced barcode generation and processing functionality.
"""
import barcode
from barcode.writer import ImageWriter
import qrcode
from PIL import Image, ImageDraw, ImageFont
import io
import base64
import logging
from typing import Optional, Dict

logger = logging.getLogger(__name__)


class BarcodeGenerator:
    """
    Advanced barcode generator supporting multiple formats and customization.
    """
    
    def __init__(self):
        self.supported_formats = {
            'ean13': 'EAN-13',
            'ean8': 'EAN-8', 
            'upc_a': 'UPC-A',
            'code128': 'Code 128',
            'code39': 'Code 39',
            'qrcode': 'QR Code',
            'datamatrix': 'Data Matrix'
        }
        
        # Default styling options
        self.default_options = {
            'module_width': 0.2,
            'module_height': 15.0,
            'quiet_zone': 6.5,
            'font_size': 11,
            'text_distance': 5.0,
            'background': 'white',
            'foreground': 'black'
        }
    
    def generate_barcode(self, data: str, barcode_format: str = 'code128', 
                        options: Optional[Dict] = None) -> Dict:
        """
        Generate barcode in specified format.
        """
        try:
            if barcode_format not in self.supported_formats:
                raise ValueError(f"Unsupported barcode format: {barcode_format}")
            
            # Merge options with defaults
            render_options = {**self.default_options, **(options or {})}
            
            if barcode_format == 'qrcode':
                return self._generate_qr_code(data, render_options)
            else:
                return self._generate_linear_barcode(data, barcode_format, render_options)
                
        except Exception as e:
            logger.error(f"Error generating barcode: {e}")
            return {
                'success': False,
                'error': str(e),
                'barcode_data': None
            }
    
    def _generate_linear_barcode(self, data: str, barcode_format: str, options: Dict) -> Dict:
        """
        Generate linear barcode (EAN, Code128, etc.).
        """
        try:
            # Get barcode class
            barcode_class = barcode.get_barcode_class(barcode_format)
            
            # Validate data format for specific barcode types
            if barcode_format in ['ean13', 'ean8', 'upc_a']:
                data = self._validate_numeric_barcode(data, barcode_format)
            
            # Create barcode instance
            barcode_instance = barcode_class(data, writer=ImageWriter())
            
            # Configure writer options
            writer_options = {
                'module_width': options.get('module_width', 0.2),
                'module_height': options.get('module_height', 15.0),
                'quiet_zone': options.get('quiet_zone', 6.5),
                'font_size': options.get('font_size', 11),
                'text_distance': options.get('text_distance', 5.0),
                'background': options.get('background', 'white'),
                'foreground': options.get('foreground', 'black')
            }
            
            # Generate barcode image
            buffer = io.BytesIO()
            barcode_instance.write(buffer, options=writer_options)
            buffer.seek(0)
            
            # Convert to base64
            barcode_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
            
            return {
                'success': True,
                'barcode_data': barcode_base64,
                'barcode_format': barcode_format,
                'data': data,
                'image_format': 'PNG',
                'size_info': self._get_barcode_dimensions(barcode_instance, writer_options)
            }
            
        except Exception as e:
            logger.error(f"Error generating linear barcode: {e}")
            raise
    
    def _generate_qr_code(self, data: str, options: Dict) -> Dict:
        """
        Generate QR code.
        """
        try:
            # QR Code configuration
            qr = qrcode.QRCode(
                version=options.get('version', 1),
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=options.get('box_size', 10),
                border=options.get('border', 4)
            )
            
            qr.add_data(data)
            qr.make(fit=True)
            
            # Create QR code image
            qr_image = qr.make_image(
                fill_color=options.get('foreground', 'black'),
                back_color=options.get('background', 'white')
            )
            
            # Convert to base64
            buffer = io.BytesIO()
            qr_image.save(buffer, format='PNG')
            buffer.seek(0)
            qr_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
            
            return {
                'success': True,
                'barcode_data': qr_base64,
                'barcode_format': 'qrcode',
                'data': data,
                'image_format': 'PNG',
                'size_info': {
                    'width': qr_image.width,
                    'height': qr_image.height
                }
            }
            
        except Exception as e:
            logger.error(f"Error generating QR code: {e}")
            raise
    
    def _validate_numeric_barcode(self, data: str, barcode_format: str) -> str:
        """
        Validate and format numeric barcodes (EAN, UPC).
        """
        try:
            # Remove any non-numeric characters
            numeric_data = ''.join(c for c in data if c.isdigit())
            
            if barcode_format == 'ean13':
                if len(numeric_data) == 12:
                    # Calculate check digit
                    numeric_data = self._calculate_ean13_check_digit(numeric_data)
                elif len(numeric_data) == 13:
                    # Validate check digit
                    if not self._validate_ean13_check_digit(numeric_data):
                        raise ValueError("Invalid EAN-13 check digit")
                else:
                    raise ValueError("EAN-13 requires 12 or 13 digits")
                    
            elif barcode_format == 'ean8':
                if len(numeric_data) == 7:
                    numeric_data = self._calculate_ean8_check_digit(numeric_data)
                elif len(numeric_data) == 8:
                    if not self._validate_ean8_check_digit(numeric_data):
                        raise ValueError("Invalid EAN-8 check digit")
                else:
                    raise ValueError("EAN-8 requires 7 or 8 digits")
                    
            elif barcode_format == 'upc_a':
                if len(numeric_data) == 11:
                    numeric_data = self._calculate_upc_a_check_digit(numeric_data)
                elif len(numeric_data) == 12:
                    if not self._validate_upc_a_check_digit(numeric_data):
                        raise ValueError("Invalid UPC-A check digit")
                else:
                    raise ValueError("UPC-A requires 11 or 12 digits")
            
            return numeric_data
            
        except Exception as e:
            logger.error(f"Error validating numeric barcode: {e}")
            raise
    
    def _calculate_ean13_check_digit(self, data: str) -> str:
        """Calculate EAN-13 check digit."""
        if len(data) != 12:
            raise ValueError("EAN-13 data must be 12 digits")
        
        odd_sum = sum(int(data[i]) for i in range(0, 12, 2))
        even_sum = sum(int(data[i]) for i in range(1, 12, 2))
        total = odd_sum + (even_sum * 3)
        check_digit = (10 - (total % 10)) % 10
        
        return data + str(check_digit)
    
    def _validate_ean13_check_digit(self, data: str) -> bool:
        """Validate EAN-13 check digit."""
        if len(data) != 13:
            return False
        
        calculated = self._calculate_ean13_check_digit(data[:12])
        return calculated == data
    
    def _calculate_ean8_check_digit(self, data: str) -> str:
        """Calculate EAN-8 check digit."""
        if len(data) != 7:
            raise ValueError("EAN-8 data must be 7 digits")
        
        odd_sum = sum(int(data[i]) for i in range(0, 7, 2))
        even_sum = sum(int(data[i]) for i in range(1, 7, 2))
        total = (odd_sum * 3) + even_sum
        check_digit = (10 - (total % 10)) % 10
        
        return data + str(check_digit)
    
    def _validate_ean8_check_digit(self, data: str) -> bool:
        """Validate EAN-8 check digit."""
        if len(data) != 8:
            return False
        
        calculated = self._calculate_ean8_check_digit(data[:7])
        return calculated == data
    
    def _calculate_upc_a_check_digit(self, data: str) -> str:
        """Calculate UPC-A check digit."""
        if len(data) != 11:
            raise ValueError("UPC-A data must be 11 digits")
        
        odd_sum = sum(int(data[i]) for i in range(0, 11, 2))
        even_sum = sum(int(data[i]) for i in range(1, 11, 2))
        total = (odd_sum * 3) + even_sum
        check_digit = (10 - (total % 10)) % 10
        
        return data + str(check_digit)
    
    def _validate_upc_a_check_digit(self, data: str) -> bool:
        """Validate UPC-A check digit."""
        if len(data) != 12:
            return False
        
        calculated = self._calculate_upc_a_check_digit(data[:11])
        return calculated == data
    
    def _get_barcode_dimensions(self, barcode_instance, options: Dict) -> Dict:
        """Get estimated barcode dimensions."""
        try:
            # This is an approximation - actual dimensions depend on data length
            estimated_width = len(barcode_instance.code) * options.get('module_width', 0.2) * 10
            estimated_height = options.get('module_height', 15.0) + options.get('text_distance', 5.0) + 20
            
            return {
                'estimated_width': estimated_width,
                'estimated_height': estimated_height,
                'units': 'mm'
            }
            
        except Exception as e:
            logger.error(f"Error calculating barcode dimensions: {e}")
            return {}
    
    def generate_product_barcode(self, product_id: int, product_name: str, 
                                barcode_format: str = 'code128') -> Dict:
        """
        Generate barcode specifically for a product.
        """
        try:
            # Create unique barcode data based on product
            if barcode_format in ['ean13', 'ean8', 'upc_a']:
                # For numeric formats, create a numeric code
                numeric_id = str(product_id).zfill(12)[:12]
                barcode_data = numeric_id
            else:
                # For alphanumeric formats, include product info
                barcode_data = f"PROD-{product_id}"
            
            result = self.generate_barcode(barcode_data, barcode_format)
            
            if result['success']:
                result['product_info'] = {
                    'product_id': product_id,
                    'product_name': product_name,
                    'barcode_data': barcode_data
                }
            
            return result
            
        except Exception as e:
            logger.error(f"Error generating product barcode: {e}")
            return {
                'success': False,
                'error': str(e),
                'product_id': product_id
            }
    
    def create_barcode_label(self, barcode_data: str, product_name: str, 
                           price: str, barcode_format: str = 'code128') -> Dict:
        """
        Create a complete barcode label with product information.
        """
        try:
            # Generate barcode
            barcode_result = self.generate_barcode(barcode_data, barcode_format)
            
            if not barcode_result['success']:
                return barcode_result
            
            # Create label with product info
            label_image = self._create_product_label(
                barcode_result['barcode_data'],
                product_name,
                price,
                barcode_data
            )
            
            return {
                'success': True,
                'label_image': label_image,
                'barcode_data': barcode_data,
                'product_name': product_name,
                'price': price,
                'barcode_format': barcode_format
            }
            
        except Exception as e:
            logger.error(f"Error creating barcode label: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def _create_product_label(self, barcode_base64: str, product_name: str, 
                            price: str, barcode_data: str) -> str:
        """
        Create a product label with barcode and text information.
        """
        try:
            # Decode barcode image
            barcode_image_data = base64.b64decode(barcode_base64)
            barcode_image = Image.open(io.BytesIO(barcode_image_data))
            
            # Create label canvas
            label_width = max(400, barcode_image.width + 40)
            label_height = barcode_image.height + 120
            
            label = Image.new('RGB', (label_width, label_height), 'white')
            draw = ImageDraw.Draw(label)
            
            # Try to load a font
            try:
                font_large = ImageFont.truetype("arial.ttf", 16)
                font_medium = ImageFont.truetype("arial.ttf", 14)
                font_small = ImageFont.truetype("arial.ttf", 12)
            except OSError:
                font_large = ImageFont.load_default()
                font_medium = ImageFont.load_default()
                font_small = ImageFont.load_default()
            
            # Position elements
            y_offset = 10
            
            # Product name (truncate if too long)
            product_name_display = product_name[:30] + "..." if len(product_name) > 30 else product_name
            text_width = draw.textlength(product_name_display, font=font_large)
            x_center = (label_width - text_width) // 2
            draw.text((x_center, y_offset), product_name_display, fill='black', font=font_large)
            y_offset += 30
            
            # Price
            price_text = f"Price: {price}"
            text_width = draw.textlength(price_text, font=font_medium)
            x_center = (label_width - text_width) // 2
            draw.text((x_center, y_offset), price_text, fill='black', font=font_medium)
            y_offset += 25
            
            # Barcode
            barcode_x = (label_width - barcode_image.width) // 2
            label.paste(barcode_image, (barcode_x, y_offset))
            y_offset += barcode_image.height + 10
            
            # Barcode number
            text_width = draw.textlength(barcode_data, font=font_small)
            x_center = (label_width - text_width) // 2
            draw.text((x_center, y_offset), barcode_data, fill='black', font=font_small)
            
            # Convert to base64
            buffer = io.BytesIO()
            label.save(buffer, format='PNG')
            buffer.seek(0)
            label_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
            
            return label_base64
            
        except Exception as e:
            logger.error(f"Error creating product label: {e}")
            raise
    
    def batch_generate_barcodes(self, products_data: list, 
                               barcode_format: str = 'code128') -> Dict:
        """
        Generate barcodes for multiple products in batch.
        """
        try:
            results = []
            successful = 0
            failed = 0
            
            for product_data in products_data:
                try:
                    product_id = product_data.get('id')
                    product_name = product_data.get('name', f'Product {product_id}')
                    
                    result = self.generate_product_barcode(
                        product_id, 
                        product_name, 
                        barcode_format
                    )
                    
                    if result['success']:
                        successful += 1
                    else:
                        failed += 1
                    
                    results.append(result)
                    
                except Exception as e:
                    logger.error(f"Error in batch generation for product {product_data}: {e}")
                    results.append({
                        'success': False,
                        'error': str(e),
                        'product_data': product_data
                    })
                    failed += 1
            
            return {
                'batch_results': results,
                'summary': {
                    'total_processed': len(products_data),
                    'successful': successful,
                    'failed': failed,
                    'success_rate': (successful / len(products_data)) * 100 if products_data else 0
                },
                'barcode_format': barcode_format
            }
            
        except Exception as e:
            logger.error(f"Error in batch barcode generation: {e}")
            return {
                'success': False,
                'error': str(e),
                'batch_results': []
            }


class BarcodeScanner:
    """
    Enhanced barcode scanning and recognition functionality.
    """
    
    def __init__(self):
        self.supported_formats = [
            'EAN13', 'EAN8', 'UPC_A', 'UPC_E',
            'CODE128', 'CODE39', 'CODE93',
            'CODABAR', 'ITF', 'QR_CODE'
        ]
    
    def decode_barcode_from_image(self, image_data: bytes) -> Dict:
        """
        Decode barcode from image data.
        Note: This is a placeholder - actual implementation would use
        libraries like pyzbar or similar for barcode detection.
        """
        try:
            # Placeholder implementation
            # In real implementation, you would use:
            # from pyzbar import pyzbar
            # import cv2
            # import numpy as np
            
            return {
                'success': False,
                'error': 'Barcode scanning not implemented in this demo',
                'suggestion': 'Use pyzbar library for actual barcode scanning'
            }
            
        except Exception as e:
            logger.error(f"Error decoding barcode: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def validate_barcode_format(self, barcode_data: str, expected_format: str) -> Dict:
        """
        Validate barcode data against expected format.
        """
        try:
            validation_result = {
                'is_valid': False,
                'format': expected_format,
                'data': barcode_data,
                'errors': []
            }
            
            if expected_format.upper() in ['EAN13', 'EAN-13']:
                validation_result['is_valid'] = self._validate_ean13(barcode_data)
                if not validation_result['is_valid']:
                    validation_result['errors'].append('Invalid EAN-13 format or check digit')
                    
            elif expected_format.upper() in ['EAN8', 'EAN-8']:
                validation_result['is_valid'] = self._validate_ean8(barcode_data)
                if not validation_result['is_valid']:
                    validation_result['errors'].append('Invalid EAN-8 format or check digit')
                    
            elif expected_format.upper() in ['UPC_A', 'UPC-A']:
                validation_result['is_valid'] = self._validate_upc_a(barcode_data)
                if not validation_result['is_valid']:
                    validation_result['errors'].append('Invalid UPC-A format or check digit')
                    
            else:
                validation_result['is_valid'] = len(barcode_data.strip()) > 0
                if not validation_result['is_valid']:
                    validation_result['errors'].append('Barcode data cannot be empty')
            
            return validation_result
            
        except Exception as e:
            logger.error(f"Error validating barcode format: {e}")
            return {
                'is_valid': False,
                'format': expected_format,
                'data': barcode_data,
                'errors': [str(e)]
            }
    
    def _validate_ean13(self, data: str) -> bool:
        """Validate EAN-13 barcode."""
        try:
            if len(data) != 13 or not data.isdigit():
                return False
            
            generator = BarcodeGenerator()
            calculated = generator._calculate_ean13_check_digit(data[:12])
            return calculated == data
            
        except Exception:
            return False
    
    def _validate_ean8(self, data: str) -> bool:
        """Validate EAN-8 barcode."""
        try:
            if len(data) != 8 or not data.isdigit():
                return False
            
            generator = BarcodeGenerator()
            calculated = generator._calculate_ean8_check_digit(data[:7])
            return calculated == data
            
        except Exception:
            return False
    
    def _validate_upc_a(self, data: str) -> bool:
        """Validate UPC-A barcode."""
        try:
            if len(data) != 12 or not data.isdigit():
                return False
            
            generator = BarcodeGenerator()
            calculated = generator._calculate_upc_a_check_digit(data[:11])
            return calculated == data
            
        except Exception:
            return False


# Global instances
barcode_generator = BarcodeGenerator()
barcode_scanner = BarcodeScanner()