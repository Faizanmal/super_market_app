"""
Apps configuration for products app.
"""
from django.apps import AppConfig

class ProductsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'products'
    verbose_name = 'Product Management'
    
    def ready(self):
        """Import signals when app is ready."""
        # Import signals only if not migrating
        import sys
        if 'migrate' not in sys.argv and 'makemigrations' not in sys.argv:
            import products.signals  # noqa
