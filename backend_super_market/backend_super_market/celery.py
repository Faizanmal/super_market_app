"""
Celery configuration for background tasks.
"""
import os
from celery import Celery
from celery.schedules import crontab

# Set the default Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend_super_market.settings')

app = Celery('backend_super_market')
 
# Load config from Django settings with CELERY_ prefix
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks from all installed apps
app.autodiscover_tasks()

# Periodic tasks configuration
app.conf.beat_schedule = {
    # Check for expiring products every day at 8 AM
    'check-expiring-products': {
        'task': 'products.tasks.check_expiring_products',
        'schedule': crontab(hour=8, minute=0),
    },
    # Check for low stock items every 6 hours
    'check-low-stock': {
        'task': 'products.tasks.check_low_stock_items',
        'schedule': crontab(minute=0, hour='*/6'),
    },
    # Generate daily reports at midnight
    'generate-daily-reports': {
        'task': 'products.tasks.generate_daily_reports',
        'schedule': crontab(hour=0, minute=0),
    },
    # Update currency exchange rates every 12 hours
    'update-currency-rates': {
        'task': 'products.tasks.update_currency_rates',
        'schedule': crontab(minute=0, hour='*/12'),
    },
    # Clean old notifications every week
    'clean-old-notifications': {
        'task': 'products.tasks.clean_old_notifications',
        'schedule': crontab(day_of_week=0, hour=0, minute=0),
    },
    # Backup database every day at 2 AM
    'backup-database': {
        'task': 'products.tasks.backup_database',
        'schedule': crontab(hour=2, minute=0),
    },
}

@app.task(bind=True)
def debug_task(self):
    """Debug task for testing."""
    print(f'Request: {self.request!r}')
