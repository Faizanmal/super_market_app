"""
URL patterns for receipt OCR endpoints.
"""
from django.urls import path
from .receipt_views import process_receipt_ocr

app_name = 'receipt'

urlpatterns = [
    # Receipt OCR processing
    path('receipt-scan/', process_receipt_ocr, name='receipt-scan'),
]