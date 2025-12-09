"""
URL patterns for barcode generation and scanning endpoints.
"""
from django.urls import path
from .barcode_views import (
    get_supported_barcode_formats,
    generate_barcode,
    generate_product_barcode,
    create_barcode_label,
    batch_generate_barcodes,
    scan_barcode_from_image,
    validate_barcode,
    search_product_by_barcode,
)

app_name = 'barcode'

urlpatterns = [
    # Barcode format information
    path('formats/', get_supported_barcode_formats, name='supported-formats'),

    # Barcode generation
    path('generate/', generate_barcode, name='generate-barcode'),
    path('generate/<int:product_id>/', generate_product_barcode, name='generate-product-barcode'),
    path('label/<int:product_id>/', create_barcode_label, name='create-barcode-label'),
    path('batch-generate/', batch_generate_barcodes, name='batch-generate-barcodes'),

    # Barcode scanning and validation
    path('scan/', scan_barcode_from_image, name='scan-barcode'),
    path('validate/', validate_barcode, name='validate-barcode'),
    path('search/', search_product_by_barcode, name='search-product-by-barcode'),
]