"""
Django signals for automatic tracking and notifications.
"""
from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver
from django.contrib.auth import get_user_model

from .models import (
    Product, PriceHistory, AuditLog, Notification,
    PurchaseOrder, InventoryAdjustment
)

User = get_user_model()

# Price History Tracking
@receiver(pre_save, sender=Product)
def track_price_changes(sender, instance, **kwargs):
    """
    Automatically track price changes in PriceHistory model.
    """
    if instance.pk:  # Only for existing products
        try:
            old_product = Product.objects.get(pk=instance.pk)
            
            # Check if prices changed
            cost_changed = old_product.cost_price != instance.cost_price
            selling_changed = old_product.selling_price != instance.selling_price
            
            if cost_changed or selling_changed:
                # Create price history record
                PriceHistory.objects.create(
                    product=instance,
                    old_cost_price=old_product.cost_price,
                    new_cost_price=instance.cost_price,
                    old_selling_price=old_product.selling_price,
                    new_selling_price=instance.selling_price,
                    reason="Automatic tracking",
                    changed_by=None  # Can be set from request context if available
                )
                
                # Create notification for price change
                # Get all admin users
                admin_users = User.objects.filter(is_staff=True, is_active=True)
                
                change_info = []
                if cost_changed:
                    change_info.append(f"Cost: ${old_product.cost_price} → ${instance.cost_price}")
                if selling_changed:
                    change_info.append(f"Selling: ${old_product.selling_price} → ${instance.selling_price}")
                
                for user in admin_users:
                    Notification.objects.create(
                        user=user,
                        notification_type='price_change',
                        priority='medium',
                        title=f"Price Changed: {instance.name}",
                        message=f"Price updated for {instance.name}. {', '.join(change_info)}",
                        product=instance,
                        action_url=f"/products/{instance.id}/"
                    )
        except Product.DoesNotExist:
            pass


# Low Stock Alerts
@receiver(post_save, sender=Product)
def check_low_stock(sender, instance, created, **kwargs):
    """
    Send notifications for low stock items.
    """
    if not created and instance.is_low_stock:
        # Get all admin users
        admin_users = User.objects.filter(is_staff=True, is_active=True)
        
        # Check if notification already exists
        existing = Notification.objects.filter(
            product=instance,
            notification_type='low_stock',
            is_read=False
        ).exists()
        
        if not existing:
            for user in admin_users:
                Notification.objects.create(
                    user=user,
                    notification_type='low_stock',
                    priority='high',
                    title=f"Low Stock Alert: {instance.name}",
                    message=f"{instance.name} is running low (Current: {instance.quantity}, Min: {instance.min_stock_level})",
                    product=instance,
                    action_url=f"/products/{instance.id}/"
                )


# Expiry Alerts
@receiver(post_save, sender=Product)
def check_expiry_alerts(sender, instance, created, **kwargs):
    """
    Send notifications for expiring/expired products.
    """
    if not instance.expiry_date:
        return
    
    status = instance.expiry_status
    
    if status in ['expired', 'expiring_soon', 'expiring_this_week']:
        # Get all admin users
        admin_users = User.objects.filter(is_staff=True, is_active=True)
        
        # Map status to notification details
        notification_map = {
            'expired': {
                'type': 'expiry_critical',
                'priority': 'critical',
                'title': f"EXPIRED: {instance.name}",
                'message': f"{instance.name} has expired on {instance.expiry_date}. Remove from inventory immediately!"
            },
            'expiring_this_week': {
                'type': 'expiry_warning',
                'priority': 'high',
                'title': f"Expiring This Week: {instance.name}",
                'message': f"{instance.name} will expire in {instance.days_until_expiry} days ({instance.expiry_date})"
            },
            'expiring_soon': {
                'type': 'expiry_warning',
                'priority': 'medium',
                'title': f"Expiring Soon: {instance.name}",
                'message': f"{instance.name} will expire in {instance.days_until_expiry} days ({instance.expiry_date})"
            }
        }
        
        details = notification_map.get(status)
        if details:
            # Check if notification already exists
            existing = Notification.objects.filter(
                product=instance,
                notification_type=details['type'],
                is_read=False
            ).exists()
            
            if not existing:
                for user in admin_users:
                    Notification.objects.create(
                        user=user,
                        notification_type=details['type'],
                        priority=details['priority'],
                        title=details['title'],
                        message=details['message'],
                        product=instance,
                        action_url=f"/products/{instance.id}/",
                        expires_at=instance.expiry_date if status == 'expired' else None
                    )


# Purchase Order Notifications
@receiver(post_save, sender=PurchaseOrder)
def notify_purchase_order_status(sender, instance, created, **kwargs):
    """
    Notify users about purchase order status changes.
    """
    # Get all admin users
    admin_users = User.objects.filter(is_staff=True, is_active=True)
    
    if created:
        # New order created
        for user in admin_users:
            Notification.objects.create(
                user=user,
                notification_type='new_order',
                priority='medium',
                title=f"New Purchase Order: {instance.order_number}",
                message=f"New purchase order created for {instance.supplier.name} with {instance.total_items} items (${instance.total_amount})",
                purchase_order=instance,
                action_url=f"/purchase-orders/{instance.id}/"
            )
    elif instance.status == 'received':
        # Order received
        for user in admin_users:
            Notification.objects.create(
                user=user,
                notification_type='order_received',
                priority='low',
                title=f"Order Received: {instance.order_number}",
                message=f"Purchase order {instance.order_number} from {instance.supplier.name} has been received",
                purchase_order=instance,
                action_url=f"/purchase-orders/{instance.id}/"
            )


# Inventory Adjustment Notifications
@receiver(post_save, sender=InventoryAdjustment)
def notify_inventory_adjustment(sender, instance, created, **kwargs):
    """
    Notify about inventory adjustments requiring approval.
    """
    if created and instance.status == 'pending':
        # Get all admin users
        admin_users = User.objects.filter(is_staff=True, is_active=True)
        
        for user in admin_users:
            if user != instance.created_by:  # Don't notify the creator
                Notification.objects.create(
                    user=user,
                    notification_type='system',
                    priority='high',
                    title=f"Adjustment Pending: {instance.product.name}",
                    message=f"{instance.created_by.get_full_name()} created an adjustment for {instance.product.name} ({instance.adjustment_quantity:+d} units). Approval required.",
                    product=instance.product,
                    action_url=f"/inventory-adjustments/{instance.id}/"
                )


# Audit Logging Utility
def create_audit_log(user, action, model_name, instance, changes=None, request=None):
    """
    Create an audit log entry.
    
    Args:
        user: User performing the action
        action: Action type (create, update, delete, etc.)
        model_name: Name of the model
        instance: Model instance
        changes: Dict of changes made
        request: HTTP request object (optional)
    """
    ip_address = None
    user_agent = None
    
    if request:
        # Extract IP address
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(',')[0]
        else:
            ip_address = request.META.get('REMOTE_ADDR')
        
        # Extract user agent
        user_agent = request.META.get('HTTP_USER_AGENT', '')[:500]
    
    AuditLog.objects.create(
        user=user,
        action=action,
        model_name=model_name,
        object_id=str(instance.pk) if instance.pk else None,
        object_repr=str(instance)[:500],
        changes=changes or {},
        ip_address=ip_address,
        user_agent=user_agent,
        success=True
    )


# Auto Audit Logging for Products
@receiver(post_save, sender=Product)
def audit_product_changes(sender, instance, created, **kwargs):
    """
    Automatically create audit logs for product changes.
    """
    action = 'create' if created else 'update'
    
    changes = {}
    if not created and instance.pk:
        try:
            old_product = Product.objects.get(pk=instance.pk)
            
            # Track important field changes
            fields_to_track = ['name', 'quantity', 'cost_price', 'selling_price', 
                             'is_active', 'min_stock_level', 'expiry_date']
            
            for field in fields_to_track:
                old_value = getattr(old_product, field, None)
                new_value = getattr(instance, field, None)
                if old_value != new_value:
                    changes[field] = {
                        'old': str(old_value),
                        'new': str(new_value)
                    }
        except Product.DoesNotExist:
            pass
    
    # Note: User context should be passed from view
    # This is a simplified version
    AuditLog.objects.create(
        user=None,  # Should be set from request context
        action=action,
        model_name='Product',
        object_id=str(instance.pk) if instance.pk else None,
        object_repr=str(instance)[:500],
        changes=changes,
        success=True
    )


@receiver(post_delete, sender=Product)
def audit_product_deletion(sender, instance, **kwargs):
    """
    Audit product deletions.
    """
    AuditLog.objects.create(
        user=None,  # Should be set from request context
        action='delete',
        model_name='Product',
        object_id=str(instance.pk),
        object_repr=str(instance)[:500],
        changes={'deleted': True},
        success=True
    )


# Reorder Suggestions
@receiver(post_save, sender=Product)
def suggest_reorder(sender, instance, created, **kwargs):
    """
    Create reorder suggestions based on reorder levels.
    """
    if not created and instance.reorder_level and instance.reorder_quantity:
        if instance.quantity <= instance.reorder_level:
            # Get all admin users
            admin_users = User.objects.filter(is_staff=True, is_active=True)
            
            # Check if notification already exists
            existing = Notification.objects.filter(
                product=instance,
                notification_type='reorder_suggestion',
                is_read=False
            ).exists()
            
            if not existing:
                for user in admin_users:
                    Notification.objects.create(
                        user=user,
                        notification_type='reorder_suggestion',
                        priority='medium',
                        title=f"Reorder Needed: {instance.name}",
                        message=f"Stock level ({instance.quantity}) is at or below reorder point ({instance.reorder_level}). Suggested reorder quantity: {instance.reorder_quantity} units.",
                        product=instance,
                        action_url=f"/products/{instance.id}/"
                    )
