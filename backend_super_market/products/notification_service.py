"""
Real-time notification service for inventory management.
"""
import logging
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from django.utils import timezone
from typing import Dict

logger = logging.getLogger(__name__)


class InventoryNotificationService:
    """
    Service for sending real-time inventory notifications via WebSocket.
    """
    
    def __init__(self):
        self.channel_layer = get_channel_layer()
    
    def send_inventory_update(self, user_id: int, product_data: Dict):
        """
        Send inventory update notification to a specific user.
        """
        try:
            group_name = f"inventory_user_{user_id}"
            
            async_to_sync(self.channel_layer.group_send)(
                group_name,
                {
                    'type': 'inventory_update',
                    'data': product_data
                }
            )
            
            logger.info(f"Sent inventory update to user {user_id}")
            
        except Exception as e:
            logger.error(f"Error sending inventory update: {e}")
    
    def send_low_stock_alert(self, user_id: int, product_data: Dict, priority: str = 'medium'):
        """
        Send low stock alert to a specific user.
        """
        try:
            group_name = f"inventory_user_{user_id}"
            
            alert_data = {
                'product_id': product_data.get('id'),
                'product_name': product_data.get('name'),
                'current_stock': product_data.get('quantity'),
                'reorder_level': product_data.get('reorder_level', 10),
                'message': f"Low stock alert: {product_data.get('name')} has only {product_data.get('quantity')} units left"
            }
            
            async_to_sync(self.channel_layer.group_send)(
                group_name,
                {
                    'type': 'low_stock_alert',
                    'data': alert_data,
                    'priority': priority
                }
            )
            
            logger.info(f"Sent low stock alert to user {user_id} for product {product_data.get('name')}")
            
        except Exception as e:
            logger.error(f"Error sending low stock alert: {e}")
    
    def send_expiry_alert(self, user_id: int, product_data: Dict, days_until_expiry: int):
        """
        Send expiry alert to a specific user.
        """
        try:
            group_name = f"inventory_user_{user_id}"
            
            priority = 'high' if days_until_expiry <= 3 else 'medium'
            
            alert_data = {
                'product_id': product_data.get('id'),
                'product_name': product_data.get('name'),
                'expiry_date': product_data.get('expiry_date'),
                'days_until_expiry': days_until_expiry,
                'quantity': product_data.get('quantity'),
                'message': f"Expiry alert: {product_data.get('name')} expires in {days_until_expiry} days"
            }
            
            async_to_sync(self.channel_layer.group_send)(
                group_name,
                {
                    'type': 'expiry_alert',
                    'data': alert_data,
                    'priority': priority
                }
            )
            
            logger.info(f"Sent expiry alert to user {user_id} for product {product_data.get('name')}")
            
        except Exception as e:
            logger.error(f"Error sending expiry alert: {e}")
    
    def send_reorder_recommendation(self, user_id: int, recommendation_data: Dict):
        """
        Send reorder recommendation to a specific user.
        """
        try:
            group_name = f"inventory_user_{user_id}"
            
            urgency = self.calculate_urgency(recommendation_data)
            
            async_to_sync(self.channel_layer.group_send)(
                group_name,
                {
                    'type': 'reorder_recommendation',
                    'data': recommendation_data,
                    'urgency': urgency
                }
            )
            
            logger.info(f"Sent reorder recommendation to user {user_id}")
            
        except Exception as e:
            logger.error(f"Error sending reorder recommendation: {e}")
    
    def send_demand_forecast_update(self, user_id: int, forecast_data: Dict):
        """
        Send demand forecast update to a specific user.
        """
        try:
            group_name = f"inventory_user_{user_id}"
            
            async_to_sync(self.channel_layer.group_send)(
                group_name,
                {
                    'type': 'demand_forecast_update',
                    'data': forecast_data
                }
            )
            
            logger.info(f"Sent demand forecast update to user {user_id}")
            
        except Exception as e:
            logger.error(f"Error sending demand forecast update: {e}")
    
    def calculate_urgency(self, recommendation_data: Dict) -> str:
        """
        Calculate urgency level for recommendations.
        """
        try:
            urgency_score = recommendation_data.get('urgency_score', 50)
            
            if urgency_score >= 80:
                return 'critical'
            elif urgency_score >= 60:
                return 'high'
            elif urgency_score >= 40:
                return 'medium'
            else:
                return 'low'
                
        except Exception as e:
            logger.error(f"Error calculating urgency: {e}")
            return 'medium'
    
    def broadcast_to_all_users(self, message_type: str, data: Dict):
        """
        Broadcast a message to all connected users (admin only).
        """
        try:
            # This would typically be used for system-wide announcements
            async_to_sync(self.channel_layer.group_send)(
                "broadcast_all",
                {
                    'type': message_type,
                    'data': data
                }
            )
            
            logger.info(f"Broadcast message of type {message_type}")
            
        except Exception as e:
            logger.error(f"Error broadcasting message: {e}")


class NotificationScheduler:
    """
    Scheduler for periodic inventory checks and notifications.
    """
    
    def __init__(self):
        self.notification_service = InventoryNotificationService()
    
    def check_and_send_alerts(self):
        """
        Check inventory and send appropriate alerts to users.
        """
        try:
            from django.contrib.auth import get_user_model
            
            User = get_user_model()
            
            for user in User.objects.filter(is_active=True):
                try:
                    self.check_user_inventory(user)
                except Exception as e:
                    logger.error(f"Error checking inventory for user {user.id}: {e}")
                    
        except Exception as e:
            logger.error(f"Error in check_and_send_alerts: {e}")
    
    def check_user_inventory(self, user):
        """
        Check inventory for a specific user and send alerts.
        """
        try:
            from .models import Product
            
            products = Product.objects.filter(created_by=user, is_deleted=False)
            
            for product in products:
                self.check_product_alerts(user, product)
                
        except Exception as e:
            logger.error(f"Error checking user inventory: {e}")
    
    def check_product_alerts(self, user, product):
        """
        Check a specific product for alerts.
        """
        try:
            product_data = {
                'id': product.id,
                'name': product.name,
                'quantity': product.quantity,
                'price': float(product.price),
                'expiry_date': product.expiry_date.isoformat() if product.expiry_date else None,
                'category': product.category.name if product.category else None
            }
            
            # Check low stock
            reorder_level = getattr(product, 'reorder_level', 10)
            if product.quantity <= reorder_level:
                priority = 'high' if product.quantity <= reorder_level * 0.5 else 'medium'
                self.notification_service.send_low_stock_alert(user.id, product_data, priority)
            
            # Check expiry
            if product.expiry_date:
                today = timezone.now().date()
                days_until_expiry = (product.expiry_date - today).days
                
                if 0 <= days_until_expiry <= 7:  # Expiring in next 7 days
                    self.notification_service.send_expiry_alert(user.id, product_data, days_until_expiry)
            
        except Exception as e:
            logger.error(f"Error checking product alerts: {e}")
    
    def schedule_ml_predictions(self):
        """
        Schedule ML-based predictions and send updates.
        """
        try:
            from django.contrib.auth import get_user_model
            
            User = get_user_model()
            
            for user in User.objects.filter(is_active=True):
                try:
                    from .models import Product
                    products = Product.objects.filter(created_by=user, is_deleted=False)
                    
                    if products.count() >= 5:  # Only run for users with sufficient data
                        self.generate_user_predictions(user, products)
                        
                except Exception as e:
                    logger.error(f"Error generating predictions for user {user.id}: {e}")
                    
        except Exception as e:
            logger.error(f"Error in schedule_ml_predictions: {e}")
    
    def generate_user_predictions(self, user, products):
        """
        Generate ML predictions for a user's inventory.
        """
        try:
            from .advanced_ml_views import get_product_historical_data
            from .advanced_ml_models import DemandForecastingEngine
            
            engine = DemandForecastingEngine()
            recommendations = []
            
            for product in products[:10]:  # Limit to 10 products per batch
                try:
                    historical_data = get_product_historical_data(product)
                    
                    if len(historical_data) >= 10:
                        # Train and predict
                        engine.train_models(historical_data)
                        predictions = engine.predict_demand(historical_data, 7)
                        insights = engine.get_demand_insights(historical_data)
                        reorder_info = engine.calculate_reorder_point(historical_data)
                        
                        # Check if reorder is recommended
                        if product.quantity <= reorder_info.get('reorder_point', 0):
                            recommendation = {
                                'product_id': product.id,
                                'product_name': product.name,
                                'current_stock': product.quantity,
                                'recommended_reorder': reorder_info.get('reorder_point', 0),
                                'predicted_demand_7days': sum(predictions.get('ensemble', [])),
                                'urgency_score': self.calculate_ml_urgency(insights),
                                'message': f"ML recommendation: Reorder {product.name}"
                            }
                            
                            recommendations.append(recommendation)
                            
                            # Send individual recommendation
                            self.notification_service.send_reorder_recommendation(
                                user.id, recommendation
                            )
                            
                except Exception as e:
                    logger.error(f"Error generating prediction for product {product.id}: {e}")
                    continue
            
            # Send batch forecast update if there are recommendations
            if recommendations:
                forecast_data = {
                    'total_recommendations': len(recommendations),
                    'recommendations': recommendations,
                    'generated_at': timezone.now().isoformat()
                }
                
                self.notification_service.send_demand_forecast_update(user.id, forecast_data)
                
        except Exception as e:
            logger.error(f"Error generating user predictions: {e}")
    
    def calculate_ml_urgency(self, insights: Dict) -> float:
        """
        Calculate ML-based urgency score.
        """
        try:
            base_score = 50
            
            # Factor in days of stock
            days_of_stock = insights.get('days_of_stock', 30)
            if days_of_stock < 3:
                base_score += 40
            elif days_of_stock < 7:
                base_score += 25
            elif days_of_stock < 14:
                base_score += 10
            
            # Factor in demand trend
            trend = insights.get('demand_trend', 'stable')
            if trend == 'increasing':
                base_score += 20
            elif trend == 'decreasing':
                base_score -= 10
            
            # Factor in volatility
            volatility = insights.get('demand_volatility', 0)
            base_score += min(20, volatility * 40)
            
            return min(100, max(0, base_score))
            
        except Exception as e:
            logger.error(f"Error calculating ML urgency: {e}")
            return 50


# Service instance
notification_service = InventoryNotificationService()
notification_scheduler = NotificationScheduler()