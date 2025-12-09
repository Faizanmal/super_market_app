"""
Real-time notifications using Django Channels for WebSocket support.
"""
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model

User = get_user_model()

class NotificationConsumer(AsyncJsonWebsocketConsumer):
    """WebSocket consumer for real-time notifications."""
    
    async def connect(self):
        """Handle WebSocket connection."""
        self.user = self.scope['user']
        
        if self.user.is_anonymous:
            await self.close()
            return
        
        # Create user-specific group
        self.notification_group = f'notifications_{self.user.id}'
        
        # Join notification group
        await self.channel_layer.group_add(
            self.notification_group,
            self.channel_name
        )
        
        await self.accept()
        
        # Send connection success message
        await self.send_json({
            'type': 'connection_established',
            'message': 'Connected to notification service'
        })
    
    async def disconnect(self, close_code):
        """Handle WebSocket disconnection."""
        if hasattr(self, 'notification_group'):
            await self.channel_layer.group_discard(
                self.notification_group,
                self.channel_name
            )
    
    async def receive_json(self, content):
        """Handle incoming WebSocket messages."""
        message_type = content.get('type')
        
        if message_type == 'ping':
            await self.send_json({'type': 'pong'})
        elif message_type == 'mark_read':
            notification_id = content.get('notification_id')
            await self.mark_notification_read(notification_id)
    
    async def notification_message(self, event):
        """Send notification to WebSocket."""
        await self.send_json(event['message'])
    
    @database_sync_to_async
    def mark_notification_read(self, notification_id):
        """Mark notification as read."""
        from .models import Notification
        try:
            notification = Notification.objects.get(
                id=notification_id,
                user=self.user
            )
            notification.is_read = True
            notification.save()
        except Notification.DoesNotExist:
            pass


class InventoryAlertConsumer(AsyncJsonWebsocketConsumer):
    """WebSocket consumer for inventory alerts."""
    
    async def connect(self):
        """Handle connection for inventory alerts."""
        self.user = self.scope['user']
        
        if self.user.is_anonymous:
            await self.close()
            return
        
        # Join inventory alerts group
        self.alerts_group = 'inventory_alerts'
        
        await self.channel_layer.group_add(
            self.alerts_group,
            self.channel_name
        )
        
        await self.accept()
    
    async def disconnect(self, close_code):
        """Handle disconnection."""
        if hasattr(self, 'alerts_group'):
            await self.channel_layer.group_discard(
                self.alerts_group,
                self.channel_name
            )
    
    async def inventory_alert(self, event):
        """Send inventory alert to WebSocket."""
        await self.send_json(event['data'])


async def send_notification_to_user(user_id, notification_data):
    """
    Send notification to specific user via WebSocket.
    Call this from views or signals.
    """
    from channels.layers import get_channel_layer
    
    channel_layer = get_channel_layer()
    await channel_layer.group_send(
        f'notifications_{user_id}',
        {
            'type': 'notification_message',
            'message': notification_data
        }
    )


async def broadcast_inventory_alert(alert_data):
    """
    Broadcast inventory alert to all connected users.
    """
    from channels.layers import get_channel_layer
    
    channel_layer = get_channel_layer()
    await channel_layer.group_send(
        'inventory_alerts',
        {
            'type': 'inventory_alert',
            'data': alert_data
        }
    )
