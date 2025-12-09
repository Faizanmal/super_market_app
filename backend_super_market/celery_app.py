"""
Enhanced Celery Application Configuration
Handles background tasks for notifications, analytics, and automated processes
"""
import os
from celery import Celery
from celery.signals import task_prerun, task_postrun, task_failure

# Set the default Django settings module for the 'celery' program
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend_super_market.settings')

app = Celery('backend_super_market')
 
# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django app configs
app.autodiscover_tasks()

# Configure Celery with comprehensive task routing
app.conf.update(
    # Task routing configuration
    task_routes={
        'products.tasks.check_expiry_alerts': {'queue': 'alerts'},
        'products.tasks.send_push_notification': {'queue': 'notifications'},
        'products.tasks.generate_analytics_report': {'queue': 'analytics'},
        'products.tasks.cleanup_expired_products': {'queue': 'maintenance'},
        'products.tasks.update_demand_forecasts': {'queue': 'analytics'},
        'products.tasks.audit_inventory_health': {'queue': 'audits'},
        'products.tasks.backup_critical_data': {'queue': 'maintenance'},
        'products.tasks.optimize_shelf_locations': {'queue': 'optimization'},
    },
    
    # Task serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    
    # Task execution settings
    task_always_eager=False,  # Set to True for testing
    task_eager_propagates=True,
    task_ignore_result=False,
    
    # Result backend configuration
    result_backend='redis://localhost:6379/0',
    result_expires=3600,  # 1 hour
    
    # Task retry configuration
    task_default_retry_delay=60,  # 1 minute
    task_max_retries=3,
    
    # Worker configuration
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=1000,
    
    # Beat schedule for periodic tasks
    beat_schedule={
        'check-expiry-alerts-every-hour': {
            'task': 'products.tasks.check_expiry_alerts',
            'schedule': 3600.0,  # Every hour
            'options': {'queue': 'alerts'}
        },
        'generate-daily-analytics': {
            'task': 'products.tasks.generate_analytics_report',
            'schedule': 86400.0,  # Every day
            'args': ('daily',),
            'options': {'queue': 'analytics'}
        },
        'update-demand-forecasts-daily': {
            'task': 'products.tasks.update_demand_forecasts',
            'schedule': 86400.0,  # Every day
            'options': {'queue': 'analytics'}
        },
        'cleanup-expired-products-weekly': {
            'task': 'products.tasks.cleanup_expired_products',
            'schedule': 604800.0,  # Every week
            'options': {'queue': 'maintenance'}
        },
        'audit-inventory-health-daily': {
            'task': 'products.tasks.audit_inventory_health',
            'schedule': 86400.0,  # Every day
            'options': {'queue': 'audits'}
        },
        'backup-critical-data-daily': {
            'task': 'products.tasks.backup_critical_data',
            'schedule': 86400.0,  # Every day at midnight
            'options': {'queue': 'maintenance'}
        },
        'optimize-shelf-locations-weekly': {
            'task': 'products.tasks.optimize_shelf_locations',
            'schedule': 604800.0,  # Every week
            'options': {'queue': 'optimization'}
        },
        'send-weekly-summary-reports': {
            'task': 'products.tasks.send_weekly_summary_report',
            'schedule': 604800.0,  # Every week
            'options': {'queue': 'notifications'}
        },
    },
)

@app.task(bind=True)
def debug_task(self):
    """Debug task for testing Celery configuration"""
    print(f'Request: {self.request!r}')
    return f'Debug task executed successfully at {self.request.id}'

@app.task(bind=True)
def health_check(self):
    """Health check task for monitoring"""
    return {
        'status': 'healthy',
        'worker_id': self.request.id,
        'timestamp': self.request.utc,
        'queue_info': {
            'alerts': 'active',
            'notifications': 'active',
            'analytics': 'active',
            'maintenance': 'active',
            'audits': 'active',
            'optimization': 'active'
        }
    }

# Signal handlers for task lifecycle

@task_prerun.connect
def task_prerun_handler(sender=None, task_id=None, task=None, args=None, kwargs=None, **kwds):
    """Pre-run task handler for logging and monitoring"""
    print(f'Task {task.__name__} (ID: {task_id}) started with args: {args}, kwargs: {kwargs}')

@task_postrun.connect
def task_postrun_handler(sender=None, task_id=None, task=None, args=None, kwargs=None, retval=None, state=None, **kwds):
    """Post-run task handler for cleanup and logging"""
    print(f'Task {task.__name__} (ID: {task_id}) completed with state: {state}')

@task_failure.connect
def task_failure_handler(sender=None, task_id=None, exception=None, traceback=None, einfo=None, **kwds):
    """Task failure handler for error reporting"""
    print(f'Task {sender.__name__} (ID: {task_id}) failed: {exception}')
    # Here you could integrate with error reporting services like Sentry