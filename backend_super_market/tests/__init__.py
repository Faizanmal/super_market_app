"""
SuperMart Pro - Test Configuration
"""

import os
import django
from django.conf import settings

# Configure Django settings for tests
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend_super_market.settings')

# Ensure Django is set up
django.setup()

# Test configuration
TEST_DATABASE = {
    'ENGINE': 'django.db.backends.sqlite3',
    'NAME': ':memory:',
}

# Pytest configuration
pytest_plugins = [
    'pytest_django',
]

# Fixtures directory
FIXTURES_DIR = os.path.join(os.path.dirname(__file__), 'fixtures')


def pytest_configure():
    """Configure pytest settings"""
    settings.DEBUG = False
    settings.DATABASES['default'] = TEST_DATABASE
    settings.PASSWORD_HASHERS = [
        'django.contrib.auth.hashers.MD5PasswordHasher',
    ]
    # Disable migrations for faster tests
    settings.MIGRATION_MODULES = {
        app: None for app in settings.INSTALLED_APPS
    }
