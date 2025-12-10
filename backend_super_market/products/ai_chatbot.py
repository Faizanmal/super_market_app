"""
AI Chatbot Service - Natural language shopping assistant
Handles customer queries, product recommendations, and order assistance
"""

import re
import json
from typing import Optional, Dict, List, Any
from datetime import datetime, timedelta
from django.db.models import Q, Avg, Count
from django.conf import settings


class ChatbotIntentClassifier:
    """Classifies user intents from natural language"""
    
    INTENTS = {
        'product_search': [
            r'find\s+(.+)',
            r'search\s+for\s+(.+)',
            r'looking\s+for\s+(.+)',
            r'where\s+(?:can\s+i\s+find|is)\s+(.+)',
            r'do\s+you\s+have\s+(.+)',
            r'show\s+me\s+(.+)',
        ],
        'price_check': [
            r'(?:what(?:\'s|\s+is)\s+the\s+)?price\s+(?:of\s+)?(.+)',
            r'how\s+much\s+(?:is|does|for)\s+(.+)',
            r'cost\s+of\s+(.+)',
        ],
        'availability': [
            r'(?:is|are)\s+(.+)\s+(?:available|in\s+stock)',
            r'do\s+you\s+have\s+(.+)\s+in\s+stock',
            r'stock\s+(?:of|for)\s+(.+)',
        ],
        'recipe_search': [
            r'recipe\s+(?:for|with)\s+(.+)',
            r'how\s+(?:to|do\s+i)\s+(?:make|cook|prepare)\s+(.+)',
            r'what\s+can\s+i\s+(?:make|cook)\s+with\s+(.+)',
        ],
        'store_hours': [
            r'(?:what\s+are\s+(?:your|the)\s+)?(?:store\s+)?hours',
            r'when\s+(?:do\s+you|are\s+you)\s+(?:open|close)',
            r'(?:are\s+you\s+)?open\s+(?:today|now|on\s+\w+)',
        ],
        'order_status': [
            r'(?:where\s+is\s+)?my\s+order',
            r'order\s+status',
            r'track\s+(?:my\s+)?order',
            r'delivery\s+status',
        ],
        'deals': [
            r'(?:any\s+)?(?:deals|discounts|offers|sales)',
            r'(?:what(?:\'s|\s+is)\s+)?on\s+sale',
            r'special\s+(?:offers|deals)',
        ],
        'location': [
            r'where\s+is\s+(.+)',
            r'(?:which\s+)?aisle\s+(?:for|is)\s+(.+)',
            r'find\s+(.+)\s+in\s+store',
        ],
        'nutrition': [
            r'(?:nutrition|nutritional)\s+(?:info|information|facts)\s+(?:for|of)\s+(.+)',
            r'calories\s+in\s+(.+)',
            r'(?:is|are)\s+(.+)\s+(?:healthy|organic|gluten.?free|vegan)',
        ],
        'recommendation': [
            r'(?:what\s+do\s+you\s+)?recommend',
            r'suggest(?:ions)?',
            r'best\s+(.+)',
            r'popular\s+(.+)',
        ],
        'greeting': [
            r'^(?:hi|hello|hey|good\s+(?:morning|afternoon|evening))',
        ],
        'thanks': [
            r'(?:thank(?:s|\s+you)|cheers|appreciated)',
        ],
        'help': [
            r'(?:help|assist(?:ance)?)',
            r'what\s+can\s+you\s+do',
        ],
    }
    
    def classify(self, text: str) -> tuple:
        """Classify intent and extract entities"""
        text = text.lower().strip()
        
        for intent, patterns in self.INTENTS.items():
            for pattern in patterns:
                match = re.search(pattern, text, re.IGNORECASE)
                if match:
                    entities = match.groups() if match.groups() else []
                    return intent, entities
        
        return 'unknown', []


class ChatbotResponseGenerator:
    """Generates contextual responses for the chatbot"""
    
    GREETINGS = [
        "Hello! 👋 Welcome to SuperMart. How can I help you today?",
        "Hi there! I'm your shopping assistant. What can I help you find?",
        "Hey! Ready to help you shop smarter. What are you looking for?",
    ]
    
    THANKS_RESPONSES = [
        "You're welcome! Happy shopping! 🛒",
        "Glad I could help! Let me know if you need anything else.",
        "Anytime! Enjoy your shopping experience!",
    ]
    
    HELP_TEXT = """
I can help you with:
🔍 **Finding Products** - "Find organic milk" or "Where is bread?"
💰 **Price Checks** - "How much is olive oil?"
📦 **Stock Info** - "Is chicken available?"
🍳 **Recipes** - "Recipe with chicken and rice"
🏷️ **Deals** - "What's on sale today?"
📍 **Store Navigation** - "Which aisle for pasta?"
📊 **Nutrition** - "Calories in apple"
📦 **Order Tracking** - "Where is my order?"

Just ask naturally, I'll understand! 😊
"""
    
    def __init__(self):
        import random
        self.random = random
    
    def greeting(self) -> str:
        return self.random.choice(self.GREETINGS)
    
    def thanks(self) -> str:
        return self.random.choice(self.THANKS_RESPONSES)
    
    def help_response(self) -> str:
        return self.HELP_TEXT
    
    def unknown(self) -> str:
        return (
            "I'm not sure I understood that. 🤔\n\n"
            "Try asking things like:\n"
            "• \"Find organic eggs\"\n"
            "• \"Price of milk\"\n"
            "• \"What's on sale?\"\n\n"
            "Type 'help' for more options!"
        )


class AIShoppingAssistant:
    """Main AI chatbot for customer assistance"""
    
    def __init__(self):
        self.classifier = ChatbotIntentClassifier()
        self.generator = ChatbotResponseGenerator()
        self.conversation_context = {}
    
    def process_message(self, user_id: str, message: str, store_id: Optional[str] = None) -> Dict[str, Any]:
        """Process user message and generate response"""
        from .models import Product, Category
        from .customer_app_models import Recipe, CustomerOrder, PersonalizedOffer, ProductLocation
        
        intent, entities = self.classifier.classify(message)
        
        response = {
            'intent': intent,
            'message': '',
            'products': [],
            'recipes': [],
            'suggestions': [],
            'actions': [],
        }
        
        if intent == 'greeting':
            response['message'] = self.generator.greeting()
            response['suggestions'] = ['Show deals', 'Find products', 'Check my orders']
        
        elif intent == 'thanks':
            response['message'] = self.generator.thanks()
        
        elif intent == 'help':
            response['message'] = self.generator.help_response()
        
        elif intent == 'product_search':
            query = entities[0] if entities else message
            products = self._search_products(query)
            response['products'] = products[:5]
            if products:
                response['message'] = f"I found {len(products)} products matching '{query}':"
            else:
                response['message'] = f"Sorry, I couldn't find any products matching '{query}'. Try a different search term."
                response['suggestions'] = ['Show popular products', 'Browse categories']
        
        elif intent == 'price_check':
            query = entities[0] if entities else message
            products = self._search_products(query)
            if products:
                product = products[0]
                response['message'] = f"💰 **{product['name']}**\n\nPrice: ${product['price']:.2f}"
                if product.get('sale_price'):
                    response['message'] += f" ~~${product['original_price']:.2f}~~ (On Sale!)"
                response['products'] = [product]
            else:
                response['message'] = f"I couldn't find '{query}' in our catalog. Try searching for something similar."
        
        elif intent == 'availability':
            query = entities[0] if entities else message
            products = self._search_products(query)
            if products:
                product = products[0]
                stock = product.get('stock_quantity', 0)
                if stock > 10:
                    response['message'] = f"✅ **{product['name']}** is well stocked ({stock} available)"
                elif stock > 0:
                    response['message'] = f"⚠️ **{product['name']}** is running low ({stock} left)"
                else:
                    response['message'] = f"❌ **{product['name']}** is currently out of stock"
                    response['actions'] = [{'type': 'notify_restock', 'product_id': product['id']}]
                response['products'] = [product]
            else:
                response['message'] = "I couldn't find that product. Could you be more specific?"
        
        elif intent == 'recipe_search':
            query = entities[0] if entities else message
            recipes = self._search_recipes(query)
            response['recipes'] = recipes[:3]
            if recipes:
                response['message'] = f"Found {len(recipes)} recipes for you! 🍳"
            else:
                response['message'] = "No recipes found. Try searching for specific ingredients or dish names."
        
        elif intent == 'store_hours':
            response['message'] = self._get_store_hours(store_id)
        
        elif intent == 'order_status':
            orders = self._get_user_orders(user_id)
            if orders:
                order = orders[0]
                response['message'] = f"📦 **Order #{order['order_number']}**\n\nStatus: {order['status']}\nUpdated: {order['updated_at']}"
                if order['status'] == 'out_for_delivery':
                    response['message'] += "\n\n🚚 Your order is on its way!"
            else:
                response['message'] = "You don't have any recent orders. Start shopping to place your first order!"
        
        elif intent == 'deals':
            deals = self._get_current_deals(user_id)
            if deals:
                response['message'] = f"🏷️ **Today's Best Deals**\n\n"
                for deal in deals[:5]:
                    response['message'] += f"• {deal['title']}: {deal['description']}\n"
                response['products'] = [d['product'] for d in deals if d.get('product')]
            else:
                response['message'] = "No special deals right now, but check back soon!"
        
        elif intent == 'location':
            query = entities[0] if entities else message
            location = self._find_product_location(query, store_id)
            if location:
                response['message'] = f"📍 **{location['product_name']}**\n\nAisle: {location['aisle']}\nSection: {location['section']}"
                response['actions'] = [{'type': 'show_map', 'aisle': location['aisle']}]
            else:
                response['message'] = "I couldn't find the location for that product. Ask a staff member for help."
        
        elif intent == 'nutrition':
            query = entities[0] if entities else message
            nutrition = self._get_nutrition_info(query)
            if nutrition:
                response['message'] = f"📊 **Nutrition Facts: {nutrition['name']}**\n\n"
                response['message'] += f"Calories: {nutrition.get('calories', 'N/A')}\n"
                response['message'] += f"Protein: {nutrition.get('protein', 'N/A')}g\n"
                response['message'] += f"Carbs: {nutrition.get('carbs', 'N/A')}g\n"
                response['message'] += f"Fat: {nutrition.get('fat', 'N/A')}g"
            else:
                response['message'] = "Nutrition information not available for this product."
        
        elif intent == 'recommendation':
            recommendations = self._get_recommendations(user_id, entities)
            response['products'] = recommendations[:5]
            response['message'] = "Based on your preferences, I recommend these products:"
        
        else:
            response['message'] = self.generator.unknown()
            response['suggestions'] = ['Help', 'Browse products', 'Today\'s deals']
        
        return response
    
    def _search_products(self, query: str) -> List[Dict]:
        """Search products by name, category, or barcode"""
        from .models import Product
        
        products = Product.objects.filter(
            Q(name__icontains=query) |
            Q(description__icontains=query) |
            Q(barcode__icontains=query) |
            Q(category__name__icontains=query)
        ).select_related('category')[:10]
        
        return [
            {
                'id': str(p.id),
                'name': p.name,
                'price': float(p.price),
                'original_price': float(p.original_price) if hasattr(p, 'original_price') else None,
                'sale_price': float(p.sale_price) if hasattr(p, 'sale_price') and p.sale_price else None,
                'category': p.category.name if p.category else 'Uncategorized',
                'stock_quantity': p.quantity if hasattr(p, 'quantity') else 0,
                'image_url': p.image_url if hasattr(p, 'image_url') else None,
            }
            for p in products
        ]
    
    def _search_recipes(self, query: str) -> List[Dict]:
        """Search recipes by name or ingredients"""
        from .customer_app_models import Recipe
        
        try:
            recipes = Recipe.objects.filter(
                Q(title__icontains=query) |
                Q(description__icontains=query) |
                Q(cuisine__icontains=query)
            )[:5]
            
            return [
                {
                    'id': str(r.id),
                    'title': r.title,
                    'description': r.description,
                    'prep_time': r.prep_time,
                    'cook_time': r.cook_time,
                    'difficulty': r.difficulty,
                    'image_url': r.image_url,
                }
                for r in recipes
            ]
        except Exception:
            return []
    
    def _get_store_hours(self, store_id: Optional[str]) -> str:
        """Get store operating hours"""
        # Default hours - can be customized per store
        return (
            "🏪 **Store Hours**\n\n"
            "Monday - Friday: 7:00 AM - 10:00 PM\n"
            "Saturday: 8:00 AM - 10:00 PM\n"
            "Sunday: 9:00 AM - 8:00 PM\n\n"
            "📍 We're currently OPEN!"
        )
    
    def _get_user_orders(self, user_id: str) -> List[Dict]:
        """Get user's recent orders"""
        from .customer_app_models import CustomerOrder, CustomerProfile
        
        try:
            profile = CustomerProfile.objects.get(user_id=user_id)
            orders = CustomerOrder.objects.filter(customer=profile).order_by('-created_at')[:5]
            
            return [
                {
                    'order_number': o.order_number,
                    'status': o.get_status_display(),
                    'total': float(o.total_amount),
                    'updated_at': o.updated_at.strftime('%b %d, %Y at %I:%M %p'),
                }
                for o in orders
            ]
        except Exception:
            return []
    
    def _get_current_deals(self, user_id: str) -> List[Dict]:
        """Get current deals and personalized offers"""
        from .customer_app_models import PersonalizedOffer, CustomerProfile
        from django.utils import timezone
        
        deals = []
        now = timezone.now()
        
        try:
            profile = CustomerProfile.objects.get(user_id=user_id)
            offers = PersonalizedOffer.objects.filter(
                customer=profile,
                is_active=True,
                valid_from__lte=now,
                valid_until__gte=now
            )[:5]
            
            for offer in offers:
                deals.append({
                    'title': offer.title,
                    'description': offer.description,
                    'code': offer.code,
                    'product': None,  # Add product details if linked
                })
        except Exception:
            pass
        
        return deals
    
    def _find_product_location(self, query: str, store_id: Optional[str]) -> Optional[Dict]:
        """Find product location in store"""
        from .customer_app_models import ProductLocation
        from .models import Product
        
        try:
            product = Product.objects.filter(
                Q(name__icontains=query) | Q(category__name__icontains=query)
            ).first()
            
            if product and store_id:
                location = ProductLocation.objects.filter(
                    product=product,
                    store_id=store_id
                ).select_related('aisle').first()
                
                if location:
                    return {
                        'product_name': product.name,
                        'aisle': location.aisle.aisle_number,
                        'aisle_name': location.aisle.name,
                        'section': location.section or 'Center',
                        'shelf': location.shelf_number,
                    }
        except Exception:
            pass
        
        return None
    
    def _get_nutrition_info(self, query: str) -> Optional[Dict]:
        """Get nutrition information for a product"""
        from .models import Product
        
        try:
            product = Product.objects.filter(name__icontains=query).first()
            if product and hasattr(product, 'nutrition_info') and product.nutrition_info:
                return {
                    'name': product.name,
                    **product.nutrition_info
                }
        except Exception:
            pass
        
        return None
    
    def _get_recommendations(self, user_id: str, entities: tuple) -> List[Dict]:
        """Get personalized product recommendations"""
        from .models import Product
        
        # Simple popularity-based recommendations
        # Can be enhanced with ML-based recommendations
        products = Product.objects.annotate(
            review_count=Count('reviews'),
            avg_rating=Avg('reviews__rating')
        ).order_by('-review_count', '-avg_rating')[:10]
        
        return [
            {
                'id': str(p.id),
                'name': p.name,
                'price': float(p.price),
                'category': p.category.name if p.category else 'Uncategorized',
            }
            for p in products
        ]


class ConversationManager:
    """Manages conversation context and history"""
    
    def __init__(self):
        self.conversations = {}  # user_id -> conversation history
        self.max_history = 10
    
    def add_message(self, user_id: str, role: str, content: str):
        """Add message to conversation history"""
        if user_id not in self.conversations:
            self.conversations[user_id] = []
        
        self.conversations[user_id].append({
            'role': role,
            'content': content,
            'timestamp': datetime.now().isoformat()
        })
        
        # Keep only recent messages
        if len(self.conversations[user_id]) > self.max_history:
            self.conversations[user_id] = self.conversations[user_id][-self.max_history:]
    
    def get_history(self, user_id: str) -> List[Dict]:
        """Get conversation history for user"""
        return self.conversations.get(user_id, [])
    
    def clear_history(self, user_id: str):
        """Clear conversation history"""
        if user_id in self.conversations:
            del self.conversations[user_id]


# Global instances
chatbot = AIShoppingAssistant()
conversation_manager = ConversationManager()
