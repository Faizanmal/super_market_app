"""
Receipt OCR and processing functionality for automatic product entry.
"""
import cv2
import pytesseract
import numpy as np
from PIL import Image
import re
import logging
from typing import Dict, List

logger = logging.getLogger(__name__)


class ReceiptOCRProcessor:
    """
    Advanced OCR processor for extracting product information from receipts.
    """
    
    def __init__(self):
        self.price_patterns = [
            r'\$?(\d+\.?\d*)',  # $12.99 or 12.99
            r'(\d+,\d{2})',     # 12,99 (European format)
            r'(\d+\.\d{2})',    # 12.99
        ]
        
        self.quantity_patterns = [
            r'(\d+)x',          # 2x
            r'x(\d+)',          # x2
            r'qty:?\s*(\d+)',   # qty: 2 or qty 2
            r'(\d+)\s*pcs',     # 2 pcs
        ]
        
        # Common product name patterns and filters
        self.product_filters = [
            'total', 'subtotal', 'tax', 'change', 'cash', 'card',
            'visa', 'mastercard', 'amex', 'thank you', 'receipt',
            'store', 'address', 'phone', 'email', 'cashier',
            'transaction', 'invoice', 'date', 'time'
        ]
    
    def preprocess_image(self, image_path: str) -> np.ndarray:
        """
        Preprocess receipt image for better OCR results.
        """
        try:
            # Read image
            image = cv2.imread(image_path)
            
            if image is None:
                raise ValueError(f"Could not read image from {image_path}")
            
            # Convert to grayscale
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Apply Gaussian blur to reduce noise
            blurred = cv2.GaussianBlur(gray, (5, 5), 0)
            
            # Apply adaptive thresholding
            thresh = cv2.adaptiveThreshold(
                blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
            )
            
            # Morphological operations to clean up the image
            kernel = np.ones((1, 1), np.uint8)
            cleaned = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
            cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_OPEN, kernel)
            
            # Deskew the image if needed
            cleaned = self.deskew_image(cleaned)
            
            return cleaned
            
        except Exception as e:
            logger.error(f"Error preprocessing image: {e}")
            raise
    
    def deskew_image(self, image: np.ndarray) -> np.ndarray:
        """
        Detect and correct skew in the image.
        """
        try:
            # Detect skew angle
            coords = np.column_stack(np.where(image > 0))
            angle = cv2.minAreaRect(coords)[-1]
            
            # Correct the angle
            if angle < -45:
                angle = -(90 + angle)
            else:
                angle = -angle
            
            # Rotate the image
            (h, w) = image.shape[:2]
            center = (w // 2, h // 2)
            M = cv2.getRotationMatrix2D(center, angle, 1.0)
            rotated = cv2.warpAffine(image, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
            
            return rotated
            
        except Exception as e:
            logger.error(f"Error deskewing image: {e}")
            return image
    
    def extract_text_from_image(self, image_path: str) -> str:
        """
        Extract text from receipt image using OCR.
        """
        try:
            # Preprocess image
            processed_image = self.preprocess_image(image_path)
            
            # Convert to PIL Image for Tesseract
            pil_image = Image.fromarray(processed_image)
            
            # OCR configuration for receipts
            config = r'--oem 3 --psm 6 -c tessedit_char_whitelist=0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,()-$ '
            
            # Extract text
            text = pytesseract.image_to_string(pil_image, config=config)
            
            return text.strip()
            
        except Exception as e:
            logger.error(f"Error extracting text from image: {e}")
            raise
    
    def parse_receipt_text(self, text: str) -> Dict[str, any]:
        """
        Parse extracted text to identify products, prices, and quantities.
        """
        try:
            lines = text.split('\n')
            items = []
            store_info = {}
            total_amount = 0
            
            # Clean and filter lines
            cleaned_lines = []
            for line in lines:
                line = line.strip()
                if len(line) > 2 and not self.is_header_footer_line(line):
                    cleaned_lines.append(line)
            
            # Extract store information from header
            store_info = self.extract_store_info(cleaned_lines[:5])
            
            # Process each line for product information
            for i, line in enumerate(cleaned_lines):
                # Skip store header/footer lines
                if self.is_header_footer_line(line):
                    continue
                
                # Try to extract item information
                item_info = self.extract_item_from_line(line)
                if item_info:
                    # Look for quantity in previous/next lines if not found
                    if item_info['quantity'] == 1:
                        qty = self.find_quantity_in_context(cleaned_lines, i)
                        if qty:
                            item_info['quantity'] = qty
                    
                    items.append(item_info)
                
                # Extract total amount
                total = self.extract_total_from_line(line)
                if total:
                    total_amount = total
            
            # Clean up and merge similar items
            items = self.merge_similar_items(items)
            
            return {
                'store_info': store_info,
                'items': items,
                'total_amount': total_amount,
                'item_count': len(items),
                'confidence_score': self.calculate_confidence_score(items, text)
            }
            
        except Exception as e:
            logger.error(f"Error parsing receipt text: {e}")
            return {
                'store_info': {},
                'items': [],
                'total_amount': 0,
                'item_count': 0,
                'confidence_score': 0
            }
    
    def extract_item_from_line(self, line: str) -> Dict[str, any]:
        """
        Extract product information from a single line.
        """
        try:
            # Skip lines that are clearly not products
            if self.is_non_product_line(line):
                return None
            
            # Extract price
            price = self.extract_price_from_line(line)
            if not price:
                return None
            
            # Extract quantity
            quantity = self.extract_quantity_from_line(line)
            
            # Extract product name (everything except price and quantity patterns)
            product_name = self.extract_product_name(line, price, quantity)
            
            if len(product_name.strip()) < 2:
                return None
            
            return {
                'name': product_name.strip(),
                'price': float(price),
                'quantity': quantity,
                'line_text': line,
                'total_price': float(price) * quantity
            }
            
        except Exception as e:
            logger.error(f"Error extracting item from line '{line}': {e}")
            return None
    
    def extract_price_from_line(self, line: str) -> float:
        """
        Extract price from a line using various patterns.
        """
        try:
            for pattern in self.price_patterns:
                matches = re.findall(pattern, line)
                if matches:
                    price_str = matches[-1]  # Take the last match (usually the price)
                    # Clean price string
                    price_str = re.sub(r'[,$]', '', price_str)
                    price_str = price_str.replace(',', '.')
                    
                    try:
                        price = float(price_str)
                        # Reasonable price range check
                        if 0.01 <= price <= 9999.99:
                            return price
                    except ValueError:
                        continue
            
            return None
            
        except Exception as e:
            logger.error(f"Error extracting price from line '{line}': {e}")
            return None
    
    def extract_quantity_from_line(self, line: str) -> int:
        """
        Extract quantity from a line.
        """
        try:
            for pattern in self.quantity_patterns:
                match = re.search(pattern, line.lower())
                if match:
                    try:
                        quantity = int(match.group(1))
                        if 1 <= quantity <= 100:  # Reasonable quantity range
                            return quantity
                    except ValueError:
                        continue
            
            return 1  # Default quantity
            
        except Exception as e:
            logger.error(f"Error extracting quantity from line '{line}': {e}")
            return 1
    
    def extract_product_name(self, line: str, price: float, quantity: int) -> str:
        """
        Extract product name by removing price and quantity patterns.
        """
        try:
            # Remove price patterns
            cleaned_line = line
            for pattern in self.price_patterns:
                cleaned_line = re.sub(pattern, '', cleaned_line)
            
            # Remove quantity patterns
            for pattern in self.quantity_patterns:
                cleaned_line = re.sub(pattern, '', cleaned_line, flags=re.IGNORECASE)
            
            # Remove common non-product words
            words = cleaned_line.split()
            filtered_words = []
            
            for word in words:
                word_clean = re.sub(r'[^\w\s]', '', word.lower())
                if (word_clean not in self.product_filters and 
                    len(word.strip()) > 1 and 
                    not word.isdigit()):
                    filtered_words.append(word)
            
            product_name = ' '.join(filtered_words).strip()
            
            # Clean up extra spaces and special characters
            product_name = re.sub(r'\s+', ' ', product_name)
            product_name = product_name.strip('.,()-')
            
            return product_name
            
        except Exception as e:
            logger.error(f"Error extracting product name from line '{line}': {e}")
            return "Unknown Product"
    
    def is_non_product_line(self, line: str) -> bool:
        """
        Check if a line is likely not a product line.
        """
        line_lower = line.lower()
        
        # Check for common non-product patterns
        non_product_patterns = [
            r'total\s*:',
            r'subtotal\s*:',
            r'tax\s*:',
            r'change\s*:',
            r'cash\s*:',
            r'card\s*:',
            r'\d{2}/\d{2}/\d{4}',  # Date
            r'\d{2}:\d{2}',        # Time
            r'thank\s+you',
            r'receipt\s+#',
            r'cashier\s*:',
        ]
        
        for pattern in non_product_patterns:
            if re.search(pattern, line_lower):
                return True
        
        # Check if line contains only special characters or numbers
        if re.match(r'^[\s\-=_*#]+$', line):
            return True
        
        return False
    
    def is_header_footer_line(self, line: str) -> bool:
        """
        Check if line is part of receipt header or footer.
        """
        line_lower = line.lower()
        
        header_footer_keywords = [
            'store', 'market', 'shop', 'address', 'phone', 'email',
            'thank you', 'visit', 'again', 'receipt', 'invoice',
            'transaction', 'cashier', 'register', 'till'
        ]
        
        return any(keyword in line_lower for keyword in header_footer_keywords)
    
    def extract_store_info(self, header_lines: List[str]) -> Dict[str, str]:
        """
        Extract store information from receipt header.
        """
        try:
            store_info = {}
            
            for line in header_lines:
                line = line.strip()
                
                # Store name (usually first line)
                if not store_info.get('name') and len(line) > 3:
                    store_info['name'] = line
                
                # Phone number
                phone_match = re.search(r'(\+?\d{1,3}[-.\s]?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4})', line)
                if phone_match:
                    store_info['phone'] = phone_match.group(1)
                
                # Email
                email_match = re.search(r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})', line)
                if email_match:
                    store_info['email'] = email_match.group(1)
            
            return store_info
            
        except Exception as e:
            logger.error(f"Error extracting store info: {e}")
            return {}
    
    def extract_total_from_line(self, line: str) -> float:
        """
        Extract total amount from receipt.
        """
        try:
            line_lower = line.lower()
            
            if 'total' in line_lower:
                price = self.extract_price_from_line(line)
                if price:
                    return price
            
            return None
            
        except Exception as e:
            logger.error(f"Error extracting total from line '{line}': {e}")
            return None
    
    def find_quantity_in_context(self, lines: List[str], current_index: int) -> int:
        """
        Look for quantity information in surrounding lines.
        """
        try:
            # Check previous and next 2 lines
            search_range = range(max(0, current_index - 2), min(len(lines), current_index + 3))
            
            for i in search_range:
                if i != current_index:
                    quantity = self.extract_quantity_from_line(lines[i])
                    if quantity > 1:
                        return quantity
            
            return 1
            
        except Exception as e:
            logger.error(f"Error finding quantity in context: {e}")
            return 1
    
    def merge_similar_items(self, items: List[Dict]) -> List[Dict]:
        """
        Merge items with similar names.
        """
        try:
            merged_items = []
            used_indices = set()
            
            for i, item in enumerate(items):
                if i in used_indices:
                    continue
                
                merged_item = item.copy()
                
                # Look for similar items
                for j, other_item in enumerate(items[i + 1:], i + 1):
                    if j in used_indices:
                        continue
                    
                    # Simple similarity check
                    if self.are_similar_products(item['name'], other_item['name']):
                        merged_item['quantity'] += other_item['quantity']
                        merged_item['total_price'] += other_item['total_price']
                        used_indices.add(j)
                
                merged_items.append(merged_item)
                used_indices.add(i)
            
            return merged_items
            
        except Exception as e:
            logger.error(f"Error merging similar items: {e}")
            return items
    
    def are_similar_products(self, name1: str, name2: str) -> bool:
        """
        Check if two product names are similar.
        """
        try:
            # Simple similarity check
            name1_clean = re.sub(r'[^\w\s]', '', name1.lower())
            name2_clean = re.sub(r'[^\w\s]', '', name2.lower())
            
            words1 = set(name1_clean.split())
            words2 = set(name2_clean.split())
            
            if not words1 or not words2:
                return False
            
            # Calculate Jaccard similarity
            intersection = len(words1.intersection(words2))
            union = len(words1.union(words2))
            
            similarity = intersection / union if union > 0 else 0
            
            return similarity > 0.6
            
        except Exception as e:
            logger.error(f"Error checking product similarity: {e}")
            return False
    
    def calculate_confidence_score(self, items: List[Dict], original_text: str) -> float:
        """
        Calculate confidence score for the OCR results.
        """
        try:
            if not items:
                return 0.0
            
            score = 0.5  # Base score
            
            # Bonus for having items
            score += min(0.3, len(items) * 0.05)
            
            # Bonus for reasonable prices
            reasonable_prices = sum(1 for item in items if 0.1 <= item['price'] <= 1000)
            score += (reasonable_prices / len(items)) * 0.2
            
            # Penalty for very short product names
            short_names = sum(1 for item in items if len(item['name']) < 3)
            score -= (short_names / len(items)) * 0.2
            
            # Bonus for text clarity (fewer special characters)
            text_clarity = len(re.findall(r'[a-zA-Z0-9\s]', original_text)) / len(original_text)
            score += text_clarity * 0.2
            
            return max(0.0, min(1.0, score))
            
        except Exception as e:
            logger.error(f"Error calculating confidence score: {e}")
            return 0.5
    
    def process_receipt(self, image_path: str) -> Dict[str, any]:
        """
        Complete receipt processing pipeline.
        """
        try:
            # Extract text from image
            extracted_text = self.extract_text_from_image(image_path)
            
            if not extracted_text.strip():
                return {
                    'success': False,
                    'error': 'No text could be extracted from the image',
                    'extracted_text': '',
                    'items': []
                }
            
            # Parse the extracted text
            parsed_data = self.parse_receipt_text(extracted_text)
            
            return {
                'success': True,
                'extracted_text': extracted_text,
                'store_info': parsed_data['store_info'],
                'items': parsed_data['items'],
                'total_amount': parsed_data['total_amount'],
                'item_count': parsed_data['item_count'],
                'confidence_score': parsed_data['confidence_score'],
                'processing_notes': self.generate_processing_notes(parsed_data)
            }
            
        except Exception as e:
            logger.error(f"Error processing receipt: {e}")
            return {
                'success': False,
                'error': str(e),
                'extracted_text': '',
                'items': []
            }
    
    def generate_processing_notes(self, parsed_data: Dict) -> List[str]:
        """
        Generate notes about the processing quality and suggestions.
        """
        notes = []
        
        try:
            confidence = parsed_data.get('confidence_score', 0)
            items = parsed_data.get('items', [])
            
            if confidence < 0.3:
                notes.append("Low confidence score - please review extracted items carefully")
            elif confidence < 0.6:
                notes.append("Medium confidence score - some items may need correction")
            else:
                notes.append("High confidence score - extraction looks good")
            
            if len(items) == 0:
                notes.append("No items detected - try a clearer image or different angle")
            elif len(items) < 3:
                notes.append("Few items detected - some products might have been missed")
            
            # Check for items without reasonable names
            unnamed_items = sum(1 for item in items if len(item.get('name', '')) < 3)
            if unnamed_items > 0:
                notes.append(f"{unnamed_items} items have unclear names and may need manual entry")
            
            return notes
            
        except Exception as e:
            logger.error(f"Error generating processing notes: {e}")
            return ["Error generating processing notes"]