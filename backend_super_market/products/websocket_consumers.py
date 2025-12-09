"""
WebSocket consumers for real-time notifications and updates.
"""
import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from datetime import timedelta
from django.utils import timezone

logger = logging.getLogger(__name__)


class InventoryConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time inventory updates.
    """
    
    async def connect(self):
        """
        Handle WebSocket connection.
        """
        try:
            # Get user from scope
            self.user = self.scope["user"]
            
            if isinstance(self.user, AnonymousUser):
                await self.close(code=4001)
                return
            
            # Create user-specific group
            self.group_name = f"inventory_user_{self.user.id}"
            
            # Join group
            await self.channel_layer.group_add(
                self.group_name,
                self.channel_name
            )
            
            await self.accept()
            
            # Send initial connection confirmation
            await self.send(text_data=json.dumps({
                'type': 'connection_established',
                'message': 'Real-time inventory updates enabled',
                'timestamp': timezone.now().isoformat(),
                'user_id': self.user.id
            }))
            
            logger.info(f"WebSocket connected for user {self.user.id}")
            
        except Exception as e:
            logger.error(f"Error in WebSocket connect: {e}")
            await self.close(code=4000)
    
    async def disconnect(self, close_code):
        """
        Handle WebSocket disconnection.
        """
        try:
            if hasattr(self, 'group_name'):
                await self.channel_layer.group_discard(
                    self.group_name,
                    self.channel_name
                )
            
            logger.info(f"WebSocket disconnected for user {getattr(self.user, 'id', 'unknown')} with code {close_code}")
            
        except Exception as e:
            logger.error(f"Error in WebSocket disconnect: {e}")
    
    async def receive(self, text_data):
        """
        Handle WebSocket messages from client.
        """
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'ping':
                await self.send(text_data=json.dumps({
                    'type': 'pong',
                    'timestamp': timezone.now().isoformat()
                }))
                
            elif message_type == 'subscribe_to_alerts':
                # Subscribe to specific alert types
                alert_types = data.get('alert_types', [])
                await self.handle_alert_subscription(alert_types)
                
            elif message_type == 'get_current_stats':
                # Send current inventory stats
                stats = await self.get_inventory_stats()
                await self.send(text_data=json.dumps({
                    'type': 'inventory_stats',
                    'data': stats,
                    'timestamp': timezone.now().isoformat()
                }))
                
        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Invalid JSON format'
            }))
        except Exception as e:
            logger.error(f"Error in WebSocket receive: {e}")
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Internal server error'
            }))
    
    async def handle_alert_subscription(self, alert_types):
        """
        Handle subscription to specific alert types.
        """
        try:
            # Store alert preferences (you might want to save this to database)
            await self.send(text_data=json.dumps({
                'type': 'subscription_confirmed',
                'alert_types': alert_types,
                'message': f'Subscribed to {len(alert_types)} alert types'
            }))
            
        except Exception as e:
            logger.error(f"Error handling alert subscription: {e}")
    
    # Group message handlers
    async def inventory_update(self, event):
        """
        Handle inventory update messages.
        """
        await self.send(text_data=json.dumps({
            'type': 'inventory_update',
            'data': event['data'],
            'timestamp': timezone.now().isoformat()
        }))
    
    async def low_stock_alert(self, event):
        """
        Handle low stock alert messages.
        """
        await self.send(text_data=json.dumps({
            'type': 'low_stock_alert',
            'data': event['data'],
            'priority': event.get('priority', 'medium'),
            'timestamp': timezone.now().isoformat()
        }))
    
    async def expiry_alert(self, event):
        """
        Handle expiry alert messages.
        """
        await self.send(text_data=json.dumps({
            'type': 'expiry_alert',
            'data': event['data'],
            'priority': event.get('priority', 'high'),
            'timestamp': timezone.now().isoformat()
        }))
    
    async def demand_forecast_update(self, event):
        """
        Handle demand forecast update messages.
        """
        await self.send(text_data=json.dumps({
            'type': 'demand_forecast_update',
            'data': event['data'],
            'timestamp': timezone.now().isoformat()
        }))
    
    async def reorder_recommendation(self, event):
        """
        Handle reorder recommendation messages.
        """
        await self.send(text_data=json.dumps({
            'type': 'reorder_recommendation',
            'data': event['data'],
            'urgency': event.get('urgency', 'medium'),
            'timestamp': timezone.now().isoformat()
        }))
    
    @database_sync_to_async
    def get_inventory_stats(self):
        """
        Get current inventory statistics.
        """
        try:
            from .models import Product
            
            products = Product.objects.filter(created_by=self.user, is_deleted=False)
            
            total_products = products.count()
            low_stock_count = products.filter(quantity__lte=10).count()
            
            # Calculate expiring soon (next 7 days)
            expiry_threshold = timezone.now() + timedelta(days=7)
            expiring_soon = products.filter(
                expiry_date__lte=expiry_threshold,
                expiry_date__gte=timezone.now()
            ).count()
            
            # Calculate total inventory value
            total_value = sum(float(p.price) * p.quantity for p in products)
            
            return {
                'total_products': total_products,
                'low_stock_count': low_stock_count,
                'expiring_soon_count': expiring_soon,
                'total_inventory_value': round(total_value, 2),
                'last_updated': timezone.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting inventory stats: {e}")
            return {
                'error': 'Failed to load stats'
            }


class NotificationConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for general notifications.
    """
    
    async def connect(self):
        """
        Handle WebSocket connection for notifications.
        """
        try:
            self.user = self.scope["user"]
            
            if isinstance(self.user, AnonymousUser):
                await self.close(code=4001)
                return
            
            self.group_name = f"notifications_user_{self.user.id}"
            
            await self.channel_layer.group_add(
                self.group_name,
                self.channel_name
            )
            
            await self.accept()
            
            # Send welcome message with recent notifications
            recent_notifications = await self.get_recent_notifications()
            
            await self.send(text_data=json.dumps({
                'type': 'connection_established',
                'recent_notifications': recent_notifications,
                'timestamp': timezone.now().isoformat()
            }))
            
        except Exception as e:
            logger.error(f"Error in notification WebSocket connect: {e}")
            await self.close(code=4000)
    
    async def disconnect(self, close_code):
        """
        Handle WebSocket disconnection for notifications.
        """
        try:
            if hasattr(self, 'group_name'):
                await self.channel_layer.group_discard(
                    self.group_name,
                    self.channel_name
                )
                
        except Exception as e:
            logger.error(f"Error in notification WebSocket disconnect: {e}")
    
    async def receive(self, text_data):
        """
        Handle messages from client.
        """
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'mark_notification_read':
                notification_id = data.get('notification_id')
                await self.mark_notification_read(notification_id)
                
            elif message_type == 'get_notification_count':
                count = await self.get_unread_notification_count()
                await self.send(text_data=json.dumps({
                    'type': 'notification_count',
                    'count': count,
                    'timestamp': timezone.now().isoformat()
                }))
                
        except Exception as e:
            logger.error(f"Error in notification receive: {e}")
    
    # Group message handlers
    async def new_notification(self, event):
        """
        Handle new notification messages.
        """
        await self.send(text_data=json.dumps({
            'type': 'new_notification',
            'notification': event['notification'],
            'timestamp': timezone.now().isoformat()
        }))
    
    async def notification_update(self, event):
        """
        Handle notification update messages.
        """
        await self.send(text_data=json.dumps({
            'type': 'notification_update',
            'notification': event['notification'],
            'timestamp': timezone.now().isoformat()
        }))
    
    @database_sync_to_async
    def get_recent_notifications(self):
        """
        Get recent notifications for the user.
        """
        try:
            # This would typically query a notifications model
            # For now, return mock data
            return [
                {
                    'id': 1,
                    'type': 'low_stock',
                    'message': 'Low stock alert for 3 products',
                    'read': False,
                    'created_at': timezone.now().isoformat()
                }
            ]
            
        except Exception as e:
            logger.error(f"Error getting recent notifications: {e}")
            return []
    
    @database_sync_to_async
    def mark_notification_read(self, notification_id):
        """
        Mark a notification as read.
        """
        try:
            # Implementation would mark notification as read in database
            pass
        except Exception as e:
            logger.error(f"Error marking notification read: {e}")
    
    @database_sync_to_async
    def get_unread_notification_count(self):
        """
        Get count of unread notifications.
        """
        try:
            # Implementation would count unread notifications
            return 0
        except Exception as e:
            logger.error(f"Error getting unread count: {e}")
            return 0