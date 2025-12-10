"""
Production-ready Django settings with environment-based configuration.
Split settings for development, staging, and production environments.
"""

import os
from pathlib import Path
from datetime import timedelta
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Environment configuration
ENVIRONMENT = os.environ.get('DJANGO_ENV', 'development')
DEBUG = ENVIRONMENT == 'development'

# Security Settings
SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-change-this-in-production-immediately')

ALLOWED_HOSTS = [
    host.strip() 
    for host in os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1,.localhost').split(',') 
    if host.strip()
]

# CSRF and CORS settings
CSRF_TRUSTED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get('CSRF_TRUSTED_ORIGINS', 'http://localhost:3000,http://127.0.0.1:3000').split(',')
    if origin.strip()
]

CORS_ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get('CORS_ALLOWED_ORIGINS', 'http://localhost:3000,http://127.0.0.1:3000').split(',')
    if origin.strip()
]

CORS_ALLOW_CREDENTIALS = True

# Application definition
DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

THIRD_PARTY_APPS = [
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    'django_filters',
    'drf_spectacular',
]

LOCAL_APPS = [
    'core',
    'accounts',
    'products',
    'analytics',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

# Middleware configuration
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # Static files
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'products.security_middleware.SecurityMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'backend_super_market.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'backend_super_market.wsgi.application'

# Database configuration
DATABASES = {
    'default': {
        'ENGINE': os.environ.get('DB_ENGINE', 'django.db.backends.postgresql'),
        'NAME': os.environ.get('DB_NAME', 'supermart_db'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'postgres'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
        'CONN_MAX_AGE': 60,
        'OPTIONS': {
            'connect_timeout': 10,
        },
    }
}

# Use SQLite for development if not configured
if ENVIRONMENT == 'development' and not os.environ.get('DB_NAME'):
    DATABASES['default'] = {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }

# Cache configuration
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': os.environ.get('REDIS_URL', 'redis://localhost:6379/0'),
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        },
        'KEY_PREFIX': 'supermart',
        'TIMEOUT': 300,
    }
}

# Use local memory cache for development if Redis not available
if ENVIRONMENT == 'development' and not os.environ.get('REDIS_URL'):
    CACHES['default'] = {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
    }

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {'min_length': 10},
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Custom User Model
AUTH_USER_MODEL = 'accounts.User'

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'core.pagination.StandardResultsPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PARSER_CLASSES': [
        'rest_framework.parsers.JSONParser',
        'rest_framework.parsers.FormParser',
        'rest_framework.parsers.MultiPartParser',
    ],
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour',
        'login': '5/minute',
    },
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'EXCEPTION_HANDLER': 'core.exceptions.custom_exception_handler',
    'DATETIME_FORMAT': '%Y-%m-%dT%H:%M:%S.%fZ',
    'DATE_FORMAT': '%Y-%m-%d',
    'NON_FIELD_ERRORS_KEY': 'general',
}

# JWT Settings
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=int(os.environ.get('JWT_ACCESS_LIFETIME_HOURS', 1))),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=int(os.environ.get('JWT_REFRESH_LIFETIME_DAYS', 7))),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',
}

# DRF Spectacular (API Documentation)
SPECTACULAR_SETTINGS = {
    'TITLE': 'SuperMart Pro API',
    'DESCRIPTION': '''
    ## SuperMart Pro - Enterprise Inventory Management System
    
    A comprehensive, AI-powered inventory management platform designed for modern retail operations.
    
    ### Key Features
    - **Inventory Management**: Real-time stock tracking and automated reordering
    - **Expiry Tracking**: AI-powered expiry prediction and waste reduction
    - **Multi-Store Support**: Centralized management across multiple locations
    - **Smart Pricing**: Dynamic pricing based on demand and expiry
    - **Analytics**: Advanced reporting and predictive analytics
    - **IoT Integration**: Support for smart shelves and sensors
    
    ### Authentication
    All API endpoints require JWT authentication. Obtain tokens via `/api/auth/login/`.
    
    ### Rate Limiting
    - Anonymous: 100 requests/hour
    - Authenticated: 1000 requests/hour
    ''',
    'VERSION': '2.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
    'COMPONENT_SPLIT_REQUEST': True,
    'TAGS': [
        {'name': 'Authentication', 'description': 'User authentication and authorization'},
        {'name': 'Products', 'description': 'Product management operations'},
        {'name': 'Inventory', 'description': 'Stock and inventory operations'},
        {'name': 'Orders', 'description': 'Purchase order management'},
        {'name': 'Analytics', 'description': 'Reports and analytics'},
        {'name': 'Stores', 'description': 'Multi-store management'},
        {'name': 'Notifications', 'description': 'Alert and notification system'},
    ],
}

# Celery Configuration
CELERY_BROKER_URL = os.environ.get('CELERY_BROKER_URL', 'redis://localhost:6379/1')
CELERY_RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND', 'redis://localhost:6379/2')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_TIME_LIMIT = 30 * 60  # 30 minutes

# Celery Beat Schedule
CELERY_BEAT_SCHEDULE = {
    'check-expiring-products': {
        'task': 'products.tasks.check_expiring_products',
        'schedule': timedelta(hours=6),
    },
    'update-stock-alerts': {
        'task': 'products.tasks.update_stock_alerts',
        'schedule': timedelta(hours=1),
    },
    'generate-daily-reports': {
        'task': 'analytics.tasks.generate_daily_reports',
        'schedule': timedelta(days=1),
    },
    'sync-multi-store-inventory': {
        'task': 'products.tasks.sync_multi_store_inventory',
        'schedule': timedelta(minutes=30),
    },
    'cleanup-old-notifications': {
        'task': 'products.tasks.cleanup_old_notifications',
        'schedule': timedelta(days=1),
    },
}

# Email Configuration
EMAIL_BACKEND = os.environ.get(
    'EMAIL_BACKEND',
    'django.core.mail.backends.console.EmailBackend' if DEBUG else 'django.core.mail.backends.smtp.EmailBackend'
)
EMAIL_HOST = os.environ.get('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', 587))
EMAIL_USE_TLS = os.environ.get('EMAIL_USE_TLS', 'True').lower() == 'true'
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', 'noreply@supermart.pro')

# Logging Configuration
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {asctime} {message}',
            'style': '{',
        },
        'json': {
            'format': '{"timestamp": "%(asctime)s", "level": "%(levelname)s", "module": "%(module)s", "message": "%(message)s"}',
        },
    },
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse',
        },
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue',
        },
    },
    'handlers': {
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
        'file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': BASE_DIR / 'logs' / 'supermart.log',
            'maxBytes': 10 * 1024 * 1024,  # 10MB
            'backupCount': 5,
            'formatter': 'verbose',
        },
        'security_file': {
            'level': 'WARNING',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': BASE_DIR / 'logs' / 'security.log',
            'maxBytes': 10 * 1024 * 1024,
            'backupCount': 10,
            'formatter': 'json',
        },
        'mail_admins': {
            'level': 'ERROR',
            'filters': ['require_debug_false'],
            'class': 'django.utils.log.AdminEmailHandler',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
        'django.security': {
            'handlers': ['security_file', 'mail_admins'],
            'level': 'WARNING',
            'propagate': False,
        },
        'products.security': {
            'handlers': ['security_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'celery': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}

# Create logs directory if it doesn't exist
(BASE_DIR / 'logs').mkdir(exist_ok=True)

# Security Settings for Production
if not DEBUG:
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_SSL_REDIRECT = os.environ.get('SECURE_SSL_REDIRECT', 'True').lower() == 'true'

# File Upload Settings
FILE_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB
DATA_UPLOAD_MAX_NUMBER_FIELDS = 1000

# SuperMart Pro Custom Settings
SUPERMART_SETTINGS = {
    'EXPIRY_WARNING_DAYS': int(os.environ.get('EXPIRY_WARNING_DAYS', 7)),
    'CRITICAL_EXPIRY_DAYS': int(os.environ.get('CRITICAL_EXPIRY_DAYS', 3)),
    'LOW_STOCK_THRESHOLD_PERCENTAGE': int(os.environ.get('LOW_STOCK_THRESHOLD', 20)),
    'AUTO_REORDER_ENABLED': os.environ.get('AUTO_REORDER_ENABLED', 'True').lower() == 'true',
    'MAX_PRODUCTS_PER_STORE': int(os.environ.get('MAX_PRODUCTS_PER_STORE', 100000)),
    'ENABLE_AI_PREDICTIONS': os.environ.get('ENABLE_AI_PREDICTIONS', 'True').lower() == 'true',
    'DEFAULT_CURRENCY': os.environ.get('DEFAULT_CURRENCY', 'USD'),
    'SUPPORTED_CURRENCIES': ['USD', 'EUR', 'GBP', 'INR', 'PKR', 'AED'],
}
