"""
AI Chatbot API Views
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .ai_chatbot import chatbot, conversation_manager
from .visual_recognition import recognition_service, freshness_detector


class ChatbotViewSet(viewsets.ViewSet):
    """AI Shopping Assistant API"""
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['post'])
    def message(self, request):
        """Send message to chatbot"""
        message = request.data.get('message', '')
        store_id = request.data.get('store_id')
        
        if not message:
            return Response({'error': 'Message required'}, status=400)
        
        user_id = str(request.user.id)
        
        # Add to conversation history
        conversation_manager.add_message(user_id, 'user', message)
        
        # Get response
        response = chatbot.process_message(user_id, message, store_id)
        
        # Add to history
        conversation_manager.add_message(user_id, 'assistant', response['message'])
        
        return Response(response)

    @action(detail=False, methods=['get'])
    def history(self, request):
        """Get conversation history"""
        user_id = str(request.user.id)
        history = conversation_manager.get_history(user_id)
        return Response({'history': history})

    @action(detail=False, methods=['post'])
    def clear(self, request):
        """Clear conversation history"""
        user_id = str(request.user.id)
        conversation_manager.clear_history(user_id)
        return Response({'cleared': True})

    @action(detail=False, methods=['get'])
    def suggestions(self, request):
        """Get conversation starters"""
        return Response({
            'suggestions': [
                'What\'s on sale today?',
                'Find organic products',
                'Show me recipe ideas',
                'Where is the bread aisle?',
                'Check my order status',
                'Help me find a product',
            ]
        })


class VisualRecognitionViewSet(viewsets.ViewSet):
    """Visual Product Recognition API"""
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['post'])
    def recognize(self, request):
        """Recognize products from image"""
        image_data = request.data.get('image')
        store_id = request.data.get('store_id')
        
        if not image_data:
            return Response({'error': 'Image data required'}, status=400)
        
        result = recognition_service.recognize_product(image_data, store_id)
        return Response(result)

    @action(detail=False, methods=['post'])
    def freshness(self, request):
        """Check freshness of produce"""
        image_data = request.data.get('image')
        product_type = request.data.get('product_type', 'produce')
        
        if not image_data:
            return Response({'error': 'Image data required'}, status=400)
        
        result = freshness_detector.analyze_freshness(image_data, product_type)
        return Response(result)

    @action(detail=False, methods=['get'])
    def similar(self, request):
        """Find similar products"""
        product_id = request.query_params.get('product_id')
        
        if not product_id:
            return Response({'error': 'product_id required'}, status=400)
        
        similar = recognition_service.find_similar_products(product_id)
        return Response({'products': similar})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def quick_search(request):
    """Quick voice/text search endpoint"""
    query = request.data.get('query', '')
    search_type = request.data.get('type', 'product')  # product, recipe, aisle
    store_id = request.data.get('store_id')
    
    from .models import Product
    from .customer_app_models import Recipe, StoreAisle
    
    results = []
    
    if search_type == 'product':
        products = Product.objects.filter(name__icontains=query)[:10]
        results = [{
            'id': str(p.id),
            'name': p.name,
            'price': float(p.price),
            'type': 'product'
        } for p in products]
    
    elif search_type == 'recipe':
        recipes = Recipe.objects.filter(title__icontains=query)[:10]
        results = [{
            'id': str(r.id),
            'name': r.title,
            'time': r.prep_time + r.cook_time,
            'type': 'recipe'
        } for r in recipes]
    
    elif search_type == 'aisle' and store_id:
        aisles = StoreAisle.objects.filter(
            store_id=store_id,
            name__icontains=query
        )[:10]
        results = [{
            'id': str(a.id),
            'name': a.name,
            'number': a.aisle_number,
            'type': 'aisle'
        } for a in aisles]
    
    return Response({'results': results, 'query': query})
