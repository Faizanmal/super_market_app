"""
Enhanced Celery Background Tasks for Super Market Helper
Comprehensive automated task system for notifications, analytics, and maintenance
"""
from celery import shared_task
from django.utils import timezone
from django.db.models import Q, Sum, F
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.conf import settings
from datetime import timedelta
import logging
import requests
from .models import (
    Product, ProductBatch, ExpiryAlert, Task, 
    AuditReport, InventoryMovement, SmartAlert
)
from .ml_models import DemandForecast, AdvancedAnalytics

logger = logging.getLogger(__name__)
User = get_user_model()

# ================== EXPIRY & ALERT TASKS ==================

@shared_task(bind=True, max_retries=3)
def check_expiry_alerts(self):
    """
    Comprehensive expiry checking with smart alert generation
    Runs every hour to monitor product expiry status
    """
    try:
        logger.info("Starting expiry alert check...")
        
        # Get current time and calculate thresholds
        now = timezone.now()
        critical_threshold = now + timedelta(days=1)  # 1 day
        high_threshold = now + timedelta(days=3)      # 3 days
        medium_threshold = now + timedelta(days=7)    # 1 week
        
        # Find batches at different risk levels
        critical_batches = ProductBatch.objects.filter(
            expiry_date__lte=critical_threshold,
            expiry_date__gt=now,
            quantity__gt=0,
            status='active'
        ).select_related('product', 'shelf_location')
        
        high_batches = ProductBatch.objects.filter(
            expiry_date__lte=high_threshold,
            expiry_date__gt=critical_threshold,
            quantity__gt=0,
            status='active'
        ).select_related('product', 'shelf_location')
        
        medium_batches = ProductBatch.objects.filter(
            expiry_date__lte=medium_threshold,
            expiry_date__gt=high_threshold,
            quantity__gt=0,
            status='active'
        ).select_related('product', 'shelf_location')
        
        alerts_created = 0
        notifications_sent = 0
        
        # Process critical alerts (immediate action required)
        for batch in critical_batches:
            alert, created = ExpiryAlert.objects.get_or_create(
                batch=batch,
                alert_type='critical',
                defaults={
                    'message': f'CRITICAL: {batch.product.name} (Batch: {batch.batch_number}) expires in {(batch.expiry_date - now).days} day(s)',
                    'recommended_action': 'Move to clearance sale or return to supplier immediately',
                    'created_by': None,
                    'is_resolved': False,
                    'severity_score': 100
                }
            )
            
            if created:
                alerts_created += 1
                # Create urgent task
                Task.objects.create(
                    title=f'URGENT: Handle expiring {batch.product.name}',
                    description=f'Batch {batch.batch_number} expires on {batch.expiry_date.strftime("%Y-%m-%d")}',
                    priority='urgent',
                    category='expiry_management',
                    due_date=batch.expiry_date,
                    estimated_duration=30,
                    assigned_to=batch.product.responsible_person
                )
                
                # Send immediate notifications
                send_critical_alert_notification.delay(alert.id)
                notifications_sent += 1
        
        # Process high priority alerts
        for batch in high_batches:
            alert, created = ExpiryAlert.objects.get_or_create(
                batch=batch,
                alert_type='high',
                defaults={
                    'message': f'HIGH PRIORITY: {batch.product.name} (Batch: {batch.batch_number}) expires in {(batch.expiry_date - now).days} days',
                    'recommended_action': 'Plan clearance sale or promotional pricing',
                    'created_by': None,
                    'is_resolved': False,
                    'severity_score': 80
                }
            )
            
            if created:
                alerts_created += 1
                Task.objects.create(
                    title=f'Plan clearance for {batch.product.name}',
                    description=f'Batch {batch.batch_number} expires on {batch.expiry_date.strftime("%Y-%m-%d")}',
                    priority='high',
                    category='expiry_management',
                    due_date=batch.expiry_date - timedelta(days=1),
                    estimated_duration=60,
                    assigned_to=batch.product.responsible_person
                )
        
        # Process medium priority alerts
        for batch in medium_batches:
            alert, created = ExpiryAlert.objects.get_or_create(
                batch=batch,
                alert_type='medium',
                defaults={
                    'message': f'MEDIUM: {batch.product.name} (Batch: {batch.batch_number}) expires in {(batch.expiry_date - now).days} days',
                    'recommended_action': 'Monitor closely and plan promotional activities',
                    'created_by': None,
                    'is_resolved': False,
                    'severity_score': 60
                }
            )
            
            if created:
                alerts_created += 1
        
        # Update inventory health scores
        update_inventory_health_scores.delay()
        
        logger.info(f"Expiry check completed: {alerts_created} new alerts, {notifications_sent} notifications sent")
        
        return {
            'status': 'success',
            'alerts_created': alerts_created,
            'notifications_sent': notifications_sent,
            'critical_batches': critical_batches.count(),
            'high_batches': high_batches.count(),
            'medium_batches': medium_batches.count(),
            'timestamp': now.isoformat()
        }
        
    except Exception as exc:
        logger.error(f"Error in expiry alert check: {exc}")
        raise self.retry(exc=exc, countdown=60)

@shared_task(bind=True, max_retries=3)
def send_critical_alert_notification(self, alert_id):
    """Send immediate notifications for critical alerts"""
    try:
        alert = ExpiryAlert.objects.get(id=alert_id)
        
        # Get users who should receive critical alerts
        users_to_notify = User.objects.filter(
            Q(user_type__in=['admin', 'manager']) |
            Q(id=alert.batch.product.responsible_person_id)
        ).distinct()
        
        for user in users_to_notify:
            # Check user notification preferences
            prefs = getattr(user, 'notification_preferences', None)
            if prefs and not prefs.critical_alerts_enabled:
                continue
            
            # Send push notification
            send_push_notification.delay(
                user_id=user.id,
                title="🚨 CRITICAL EXPIRY ALERT",
                message=alert.message,
                data={
                    'type': 'critical_expiry',
                    'alert_id': alert.id,
                    'batch_id': alert.batch.id,
                    'product_name': alert.batch.product.name,
                    'days_until_expiry': (alert.batch.expiry_date - timezone.now()).days
                },
                priority='high'
            )
            
            # Send email if enabled
            if prefs and prefs.email_notifications_enabled:
                send_expiry_email.delay(user.id, alert.id)
        
        return {'status': 'success', 'users_notified': users_to_notify.count()}
        
    except ExpiryAlert.DoesNotExist:
        logger.error(f"ExpiryAlert {alert_id} not found")
        return {'status': 'error', 'message': 'Alert not found'}
    except Exception as exc:
        logger.error(f"Error sending critical alert notification: {exc}")
        raise self.retry(exc=exc, countdown=30)

# ================== NOTIFICATION TASKS ==================

@shared_task(bind=True, max_retries=3)
def send_push_notification(self, user_id, title, message, data=None, priority='normal'):
    """
    Send push notification using Firebase Cloud Messaging
    Supports both Android and iOS devices
    """
    try:
        user = User.objects.get(id=user_id)
        profile = getattr(user, 'profile', None)
        
        if not profile or not profile.fcm_token:
            logger.warning(f"No FCM token for user {user_id}")
            return {'status': 'skipped', 'reason': 'no_fcm_token'}
        
        # Firebase Cloud Messaging payload
        payload = {
            'notification': {
                'title': title,
                'body': message,
                'icon': 'ic_notification',
                'sound': 'default',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK'
            },
            'data': data or {},
            'to': profile.fcm_token,
            'priority': 'high' if priority == 'high' else 'normal'
        }
        
        # Add custom sound for critical alerts
        if priority == 'high':
            payload['notification']['sound'] = 'alert_sound.mp3'
            payload['android'] = {
                'notification': {
                    'channel_id': 'critical_alerts',
                    'priority': 'high',
                    'visibility': 'public'
                }
            }
        
        # Send to Firebase
        headers = {
            'Authorization': f'key={settings.FCM_SERVER_KEY}',
            'Content-Type': 'application/json'
        }
        
        response = requests.post(
            'https://fcm.googleapis.com/fcm/send',
            json=payload,
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success', 0) > 0:
                logger.info(f"Push notification sent successfully to user {user_id}")
                return {'status': 'success', 'message_id': result.get('results', [{}])[0].get('message_id')}
            else:
                error = result.get('results', [{}])[0].get('error')
                logger.error(f"FCM error for user {user_id}: {error}")
                
                # Handle invalid registration tokens
                if error in ['InvalidRegistration', 'NotRegistered']:
                    profile.fcm_token = None
                    profile.save()
                
                return {'status': 'error', 'error': error}
        else:
            logger.error(f"FCM request failed: {response.status_code} - {response.text}")
            return {'status': 'error', 'http_status': response.status_code}
        
    except User.DoesNotExist:
        logger.error(f"User {user_id} not found")
        return {'status': 'error', 'message': 'User not found'}
    except Exception as exc:
        logger.error(f"Error sending push notification to user {user_id}: {exc}")
        raise self.retry(exc=exc, countdown=30)

@shared_task(bind=True, max_retries=2)
def send_expiry_email(self, user_id, alert_id):
    """Send detailed expiry alert email"""
    try:
        user = User.objects.get(id=user_id)
        alert = ExpiryAlert.objects.get(id=alert_id)
        
        subject = f"🚨 Expiry Alert: {alert.batch.product.name}"
        
        message = f"""
        Dear {user.first_name or user.username},
        
        CRITICAL EXPIRY ALERT
        
        Product: {alert.batch.product.name}
        Batch Number: {alert.batch.batch_number}
        Quantity: {alert.batch.quantity} {alert.batch.product.unit}
        Expiry Date: {alert.batch.expiry_date.strftime('%Y-%m-%d %H:%M')}
        Days Until Expiry: {(alert.batch.expiry_date - timezone.now()).days}
        Location: {alert.batch.shelf_location.name if alert.batch.shelf_location else 'Not assigned'}
        
        RECOMMENDED ACTION:
        {alert.recommended_action}
        
        Please take immediate action to prevent wastage.
        
        Best regards,
        Super Market Helper System
        """
        
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False
        )
        
        logger.info(f"Expiry email sent to {user.email}")
        return {'status': 'success'}
        
    except Exception as exc:
        logger.error(f"Error sending expiry email: {exc}")
        raise self.retry(exc=exc, countdown=60)

# ================== ANALYTICS & REPORTING TASKS ==================


@shared_task(bind=True, max_retries=2)
def generate_analytics_report(self, report_type='daily'):
    """
    Generate comprehensive analytics reports
    Types: daily, weekly, monthly
    """
    try:
        logger.info(f"Generating {report_type} analytics report...")
        
        now = timezone.now()
        
        if report_type == 'daily':
            start_date = now - timedelta(days=1)
        elif report_type == 'weekly':
            start_date = now - timedelta(days=7)
        elif report_type == 'monthly':
            start_date = now - timedelta(days=30)
        else:
            start_date = now - timedelta(days=1)
        
        # Initialize analytics engine
        analytics = AdvancedAnalytics()
        
        # Generate various analytics
        results = {
            'report_type': report_type,
            'period': f"{start_date.strftime('%Y-%m-%d')} to {now.strftime('%Y-%m-%d')}",
            'generated_at': now.isoformat(),
            'expiry_analysis': analytics.analyze_expiry_patterns(),
            'stock_health': analytics.calculate_stock_health(),
            'wastage_analysis': analytics.analyze_wastage_patterns(),
            'profit_analysis': analytics.analyze_profit_trends(),
            'abc_analysis': analytics.perform_abc_analysis(),
            'movement_analysis': analytics.analyze_inventory_movements(start_date, now),
            'alerts_summary': _get_alerts_summary(start_date, now),
            'top_products': _get_top_performing_products(start_date, now),
            'recommendations': _generate_recommendations()
        }
        
        # Send report to managers if it's a weekly/monthly report
        if report_type in ['weekly', 'monthly']:
            send_analytics_report_email.delay(results)
        logger.info(f"{report_type.capitalize()} analytics report generated successfully")
        return results
    except Exception as exc:
        logger.error(f"Error generating analytics report: {exc}")
        raise self.retry(exc=exc, countdown=300)  # 5 minutes
 
@shared_task(bind=True, max_retries=2)
def send_analytics_report_email(self, results):
        """
        Send analytics report to managers via email.
        Expects 'results' dict produced by generate_analytics_report.
        """
        try:
            manager_emails = User.objects.filter(is_staff=True, is_active=True).values_list('email', flat=True)
            if not manager_emails:
                logger.info("No manager emails configured; skipping analytics report email")
                return {'status': 'skipped', 'reason': 'no_recipients'}
            
            subject = f"Analytics Report: {results.get('report_type', 'report').capitalize()} - {results.get('generated_at', '')}"
            # Create a simple plain-text summary
            summary_lines = [
                f"Report Type: {results.get('report_type')}",
                f"Period: {results.get('period')}",
                f"Generated At: {results.get('generated_at')}",
                "",
                "Key Metrics:",
                f"- Total Alerts: {results.get('alerts_summary', {}).get('total_alerts', 'N/A')}",
                f"- Critical Alerts: {results.get('alerts_summary', {}).get('critical_count', 'N/A')}",
                f"- High Alerts: {results.get('alerts_summary', {}).get('high_count', 'N/A')}",
                f"- Medium Alerts: {results.get('alerts_summary', {}).get('medium_count', 'N/A')}",
                f"- Recommendations: {len(results.get('recommendations', []))}",
                ""
            ]
            message = "\n".join(summary_lines)
            
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=list(manager_emails),
                fail_silently=False
            )
            logger.info(f"Analytics report emailed to {len(manager_emails)} managers")
            return {'status': 'success', 'emailed_to': len(manager_emails)}
        except Exception as exc:
            logger.error(f"Error sending analytics report email: {exc}")
            return {'status': 'error', 'error': str(exc)}

@shared_task(bind=True, max_retries=2)
def update_demand_forecasts(self):
    """Update demand forecasts for all active products"""
    try:
        logger.info("Updating demand forecasts...")
        
        active_products = Product.objects.filter(is_active=True)
        forecasts_updated = 0
        
        for product in active_products:
            try:
                # Get historical data for the product
                movements = InventoryMovement.objects.filter(
                    product=product,
                    movement_type='out',
                    created_at__gte=timezone.now() - timedelta(days=90)
                ).order_by('created_at')
                
                if movements.count() < 5:  # Need at least 5 data points
                    continue
                
                # Initialize demand forecast model
                forecast_model = DemandForecast(product.id, product.name)
                
                # Prepare data for forecasting
                sales_data = []
                for movement in movements:
                    sales_data.append({
                        'date': movement.created_at.date(),
                        'quantity': movement.quantity,
                        'price': movement.unit_price or product.selling_price
                    })
                
                # Generate forecast
                forecast_model.calculate_reorder_point(
                    current_stock=product.current_stock,
                    sales_data=sales_data
                )
                
                forecasts_updated += 1
                
            except Exception as e:
                logger.warning(f"Failed to update forecast for product {product.id}: {e}")
                continue
        
        logger.info(f"Demand forecasts updated for {forecasts_updated} products")
        return {'status': 'success', 'forecasts_updated': forecasts_updated}
        
    except Exception as exc:
        logger.error(f"Error updating demand forecasts: {exc}")
        raise self.retry(exc=exc, countdown=300)

@shared_task(bind=True, max_retries=2)
def audit_inventory_health(self):
    """Comprehensive inventory health audit"""
    try:
        logger.info("Starting inventory health audit...")
        
        # Analyze various health metrics
        health_issues = []
        
        # 1. Check for overstocked items
        overstocked = Product.objects.filter(
            current_stock__gt=F('max_stock_level')
        ).count()
        
        if overstocked > 0:
            health_issues.append({
                'category': 'overstock',
                'count': overstocked,
                'severity': 'medium',
                'description': f'{overstocked} products are overstocked'
            })
        
        # 2. Check for understocked items
        understocked = Product.objects.filter(
            current_stock__lt=F('min_stock_level')
        ).count()
        
        if understocked > 0:
            health_issues.append({
                'category': 'understock',
                'count': understocked,
                'severity': 'high',
                'description': f'{understocked} products are understocked'
            })
        
        # 3. Check for expired items still in inventory
        expired_batches = ProductBatch.objects.filter(
            expiry_date__lt=timezone.now(),
            quantity__gt=0,
            status='active'
        ).count()
        
        if expired_batches > 0:
            health_issues.append({
                'category': 'expired',
                'count': expired_batches,
                'severity': 'critical',
                'description': f'{expired_batches} expired batches still in inventory'
            })
        
        # Create audit report
        audit_report = AuditReport.objects.create(
            audit_type='health_check',
            scope='inventory',
            conducted_by=None,  # Automated audit
            items_checked=Product.objects.count(),
            items_expired=expired_batches,
            items_near_expiry=ProductBatch.objects.filter(
                expiry_date__lte=timezone.now() + timedelta(days=7),
                expiry_date__gt=timezone.now(),
                quantity__gt=0
            ).count(),
            notes=f"Automated health audit: {len(health_issues)} issues found"
        )
        
        # Generate smart alerts for critical issues
        for issue in health_issues:
            if issue['severity'] == 'critical':
                SmartAlert.objects.create(
                    alert_type='system',
                    priority='critical',
                    title=f"Critical Inventory Issue: {issue['category'].title()}",
                    message=issue['description'],
                    recommendation="Immediate action required",
                    is_resolved=False,
                    created_by=None
                )
        
        logger.info(f"Inventory health audit completed: {len(health_issues)} issues found")
        
        return {
            'status': 'success',
            'audit_id': audit_report.id,
            'issues_found': len(health_issues),
            'health_issues': health_issues,
            'timestamp': timezone.now().isoformat()
        }
        
    except Exception as exc:
        logger.error(f"Error in inventory health audit: {exc}")
        raise self.retry(exc=exc, countdown=300)

@shared_task(bind=True, max_retries=2)
def update_inventory_health_scores(self):
    """Update health scores for all products based on multiple factors"""
    try:
        logger.info("Updating inventory health scores...")
        
        products = Product.objects.filter(is_active=True)
        scores_updated = 0
        
        for product in products:
            try:
                # Calculate health score based on multiple factors
                score = 100  # Start with perfect score
                
                # Factor 1: Stock level (30% weight)
                if product.current_stock <= 0:
                    score -= 30
                elif product.current_stock < product.min_stock_level:
                    score -= 20
                elif product.current_stock > product.max_stock_level:
                    score -= 10
                
                # Factor 2: Expiry proximity (40% weight)
                nearest_expiry = ProductBatch.objects.filter(
                    product=product,
                    quantity__gt=0,
                    status='active'
                ).order_by('expiry_date').first()
                
                if nearest_expiry:
                    days_to_expiry = (nearest_expiry.expiry_date - timezone.now()).days
                    if days_to_expiry < 0:
                        score -= 40  # Expired
                    elif days_to_expiry <= 3:
                        score -= 30  # Critical
                    elif days_to_expiry <= 7:
                        score -= 20  # High risk
                    elif days_to_expiry <= 14:
                        score -= 10  # Medium risk
                
                # Factor 3: Movement activity (20% weight)
                recent_movements = InventoryMovement.objects.filter(
                    product=product,
                    created_at__gte=timezone.now() - timedelta(days=14)
                ).count()
                
                if recent_movements == 0:
                    score -= 20  # No recent activity
                elif recent_movements < 3:
                    score -= 10  # Low activity
                
                # Factor 4: Alert frequency (10% weight)
                recent_alerts = ExpiryAlert.objects.filter(
                    batch__product=product,
                    created_at__gte=timezone.now() - timedelta(days=7)
                ).count()
                
                if recent_alerts > 5:
                    score -= 10
                elif recent_alerts > 2:
                    score -= 5
                
                # Ensure score is within bounds
                score = max(0, min(100, score))
                
                scores_updated += 1
                
            except Exception as e:
                logger.warning(f"Failed to update health score for product {product.id}: {e}")
                continue
        
        logger.info(f"Health scores updated for {scores_updated} products")
        return {'status': 'success', 'scores_updated': scores_updated}
        
    except Exception as exc:
        logger.error(f"Error updating health scores: {exc}")
        raise self.retry(exc=exc, countdown=300)

# ================== UTILITY FUNCTIONS ==================

def _get_alerts_summary(start_date, end_date):
    """Get summary of alerts for the given period"""
    alerts = ExpiryAlert.objects.filter(
        created_at__range=[start_date, end_date]
    )
    
    return {
        'total_alerts': alerts.count(),
        'critical_count': alerts.filter(alert_type='critical').count(),
        'high_count': alerts.filter(alert_type='high').count(),
        'medium_count': alerts.filter(alert_type='medium').count(),
        'resolved_count': alerts.filter(is_resolved=True).count(),
        'active_alerts': list(alerts.filter(is_resolved=False).values(
            'id', 'alert_type', 'message', 'created_at'
        ))
    }

def _get_top_performing_products(start_date, end_date):
    """Get top performing products by movement"""
    movements = InventoryMovement.objects.filter(
        created_at__range=[start_date, end_date],
        movement_type='out'
    ).values(
        'product__name'
    ).annotate(
        total_movement=Sum('quantity')
    ).order_by('-total_movement')[:10]
    
    return [
        {
            'name': movement['product__name'],
            'movement': movement['total_movement']
        }
        for movement in movements
    ]

def _generate_recommendations():
    """Generate smart recommendations based on current data"""
    recommendations = []
    
    # Check for products with no recent movement
    stale_products = Product.objects.filter(
        inventorymovement__created_at__lt=timezone.now() - timedelta(days=30)
    ).distinct()[:5]
    
    if stale_products.exists():
        recommendations.append(
            f"Consider promotional pricing for {stale_products.count()} slow-moving products"
        )
    
    # Check for overstocked items
    overstocked = Product.objects.filter(
        current_stock__gt=F('max_stock_level')
    )[:3]
    
    if overstocked.exists():
        recommendations.append(
            f"Review order quantities for {overstocked.count()} overstocked products"
        )
    
    # Check for items approaching expiry
    expiring_soon = ProductBatch.objects.filter(
        expiry_date__lte=timezone.now() + timedelta(days=14),
        expiry_date__gt=timezone.now(),
        quantity__gt=0
    ).count()
    
    if expiring_soon > 0:
        recommendations.append(
            f"Plan clearance sales for {expiring_soon} batches expiring within 2 weeks"
        )
    
    return recommendations

# ================== LEGACY TASK COMPATIBILITY ==================

# Keep existing task names for backward compatibility
check_expiring_products = check_expiry_alerts

# Legacy helper: notify about expiring products using ProductBatch (keeps compatibility with older behavior)
def notify_expiring_products_legacy():
    from .models import Notification, ProductBatch
    admin_users = User.objects.filter(is_staff=True, is_active=True)
    now = timezone.now()

    # Batches expiring within a week
    expiring_this_week = ProductBatch.objects.filter(
        expiry_date__gt=now,
        expiry_date__lte=now + timedelta(days=7),
        quantity__gt=0,
        status='active'
    ).select_related('product')

    # Already expired batches
    expired = ProductBatch.objects.filter(
        expiry_date__lt=now,
        quantity__gt=0,
        status='active'
    )

    # Notify about expiring products
    for batch in expiring_this_week:
        product = batch.product
        for user in admin_users:
            Notification.objects.get_or_create(
                user=user,
                product=product,
                notification_type='expiry_warning',
                is_read=False,
                defaults={
                    'priority': 'high',
                    'title': f'Expiring Soon: {product.name}',
                    'message': f'{product.name} (Batch {batch.batch_number}) expires on {batch.expiry_date} ({(batch.expiry_date - now).days} days)',
                    'action_url': f'/products/{product.id}/'
                }
            )

    logger.info(f'Checked expiring products: {expired.count()} expired, {expiring_this_week.count()} expiring soon')
    return {
        'expired': expired.count(),
        'expiring_this_week': expiring_this_week.count()
    }


@shared_task
def check_low_stock_items():
    """
    Check for low stock items and create notifications.
    """
    from .models import Product, Notification
    from django.db import models
    
    low_stock_products = Product.objects.filter(
        quantity__lte=models.F('min_stock_level'),
        is_active=True
    )
    
    admin_users = User.objects.filter(is_staff=True, is_active=True)
    
    for product in low_stock_products:
        for user in admin_users:
            Notification.objects.get_or_create(
                user=user,
                product=product,
                notification_type='low_stock',
                is_read=False,
                defaults={
                    'priority': 'high',
                    'title': f'Low Stock: {product.name}',
                    'message': f'{product.name} is running low (Current: {product.quantity}, Min: {product.min_stock_level})',
                    'action_url': f'/products/{product.id}/'
                }
            )
    
    logger.info(f'Checked low stock items: {low_stock_products.count()} items found')
    return {'low_stock_count': low_stock_products.count()}


@shared_task
def generate_daily_reports():
    """
    Generate daily inventory reports and email to admins.
    """
    from .models import Product, StockMovement
    from django.core.mail import send_mail
    from django.conf import settings
    from django.db import models
    
    today = timezone.now().date()
    yesterday = today - timedelta(days=1)
    
    # Get statistics
    total_products = Product.objects.filter(is_active=True).count()
    low_stock = Product.objects.filter(
        quantity__lte=models.F('min_stock_level'),
        is_active=True
    ).count()
    
    stock_movements = StockMovement.objects.filter(
        movement_date__date=yesterday
    )
    
    stock_in = stock_movements.filter(movement_type='in').aggregate(
        total=models.Sum('quantity')
    )['total'] or 0
    
    stock_out = stock_movements.filter(movement_type='out').aggregate(
        total=models.Sum('quantity')
    )['total'] or 0
    
    # Create report
    report = f"""
    Daily Inventory Report - {yesterday}
    ===================================
    
    Summary:
    - Total Active Products: {total_products}
    - Low Stock Items: {low_stock}
    - Stock Received: {stock_in} units
    - Stock Dispatched: {stock_out} units
    - Net Change: {stock_in - stock_out} units
    
    """
    
    # Email to admins
    admin_emails = User.objects.filter(
        is_staff=True,
        is_active=True
    ).values_list('email', flat=True)
    
    if admin_emails:
        send_mail(
            subject=f'Daily Inventory Report - {yesterday}',
            message=report,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=list(admin_emails),
            fail_silently=True
        )
    
    logger.info(f'Generated daily report for {yesterday}')
    return {'report_date': str(yesterday), 'emailed_to': len(admin_emails)}


@shared_task
def update_currency_rates():
    """
    Update currency exchange rates from external API.
    Note: This is a placeholder. Implement actual API integration.
    """
    from .models import Currency
    
    # In production, integrate with currency API like:
    # - exchangerate-api.com
    # - currencyapi.com
    # - fixer.io
    
    currencies = Currency.objects.filter(is_active=True, is_base_currency=False)
    
    # Placeholder: This would make actual API calls
    updated_count = 0
    for currency in currencies:
        # currency.exchange_rate = fetch_from_api(currency.code)
        # currency.save()
        updated_count += 1
    
    logger.info(f'Updated {updated_count} currency rates')
    return {'updated_count': updated_count}


@shared_task
def clean_old_notifications():
    """
    Delete read notifications older than 30 days.
    """
    from .models import Notification
    
    cutoff_date = timezone.now() - timedelta(days=30)
    
    deleted_count, _ = Notification.objects.filter(
        is_read=True,
        created_at__lt=cutoff_date
    ).delete()
    
    logger.info(f'Deleted {deleted_count} old notifications')
    return {'deleted_count': deleted_count}


@shared_task
def backup_database():
    """
    Create database backup.
    Note: This is a placeholder for production backup implementation.
    """
    from django.conf import settings
    
    try:
        backup_dir = settings.BASE_DIR / 'backups'
        backup_dir.mkdir(exist_ok=True)
        
        timestamp = timezone.now().strftime('%Y%m%d_%H%M%S')
        backup_file = backup_dir / f'backup_{timestamp}.sql'
        
        # For PostgreSQL
        # This would need proper implementation based on database type
        # Example for PostgreSQL:
        # subprocess.run([
        #     'pg_dump',
        #     '-h', settings.DATABASES['default']['HOST'],
        #     '-U', db['USER'],
        #     '-d', db['NAME'],
        #     '-f', str(backup_file)
        # ])
        
        logger.info(f'Database backup created: {backup_file}')
        return {'backup_file': str(backup_file), 'success': True}
        
    except Exception as e:
        logger.error(f'Backup failed: {str(e)}')
        return {'success': False, 'error': str(e)}


@shared_task
def send_email_notification(user_id, notification_id):
    """
    Send email for important notifications.
    """
    from .models import Notification
    from django.core.mail import send_mail
    from django.conf import settings
    
    try:
        notification = Notification.objects.get(id=notification_id)
        user = notification.user
        
        subject = f'[SuperMart] {notification.title}'
        message = f"""
        {notification.title}
        
        {notification.message}
        
        Priority: {notification.get_priority_display()}
        Type: {notification.get_notification_type_display()}
        
        Login to view details: {settings.FRONTEND_URL or 'your-domain.com'}
        """
        
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False
        )
        
        logger.info(f'Email sent to {user.email} for notification {notification_id}')
        return {'success': True, 'email': user.email}
        
    except Exception as e:
        logger.error(f'Email send failed: {str(e)}')
        return {'success': False, 'error': str(e)}


@shared_task
def generate_product_barcodes(product_ids=None):
    """
    Generate barcodes for products that don't have them.
    """
    from .models import Product
    try:
        import barcode
        from barcode import writer
    except ImportError:
        barcode = None
        writer = None
    
    if barcode is None or writer is None:
        logger.warning("Barcode library not available, skipping barcode generation")
        return {'generated_count': 0}
    from io import BytesIO
    
    if product_ids:
        products = Product.objects.filter(id__in=product_ids, barcode='')
    else:
        products = Product.objects.filter(barcode='', is_active=True)
    
    generated_count = 0
    
    for product in products:
        try:
            # Generate EAN13 barcode
            ean = barcode.get_barcode_class('ean13')
            
            # Generate unique code based on product ID
            code = f'{product.id:012d}'
            
            # Generate barcode image
            rv = BytesIO()
            ean_code = ean(code, writer=writer.ImageWriter())
            ean_code.write(rv)
            
            # Save to product
            product.barcode = code
            # Optionally save barcode image
            # product.barcode_image.save(f'{code}.png', File(rv), save=False)
            product.save()
            
            generated_count += 1
            
        except Exception as e:
            logger.error(f'Barcode generation failed for product {product.id}: {str(e)}')
    
    logger.info(f'Generated {generated_count} barcodes')
    return {'generated_count': generated_count}
