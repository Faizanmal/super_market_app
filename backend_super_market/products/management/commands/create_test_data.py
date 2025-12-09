"""
Simple Test Data Creation Script for Super Market Helper
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from accounts.models import User
from products.models import (
    Store, Product, ProductBatch, ShelfLocation, BatchLocation,
    ShelfAudit, AuditItem, ExpiryAlert, Task, Category, Supplier
)


class Command(BaseCommand):
    help = 'Creates sample test data'

    def handle(self, *args, **kwargs):
        self.stdout.write('Creating test data...')
        
        # Create admin
        admin, created = User.objects.get_or_create(
            email='admin@example.com',
            defaults={
                'first_name': 'Admin', 'last_name': 'User',
                'role': 'head_office', 'is_staff': True, 'is_superuser': True
            }
        )
        if created:
            admin.set_password(os.environ.get('ADMIN_PASSWORD', 'change_this_password_immediately'))
            admin.save()
        
        # Create stores
        store1, _ = Store.objects.get_or_create(
            code='STR001',
            defaults={'name': 'Downtown Store', 'address': '123 Main St',
                     'phone': '555-0101', 'email': 'downtown@store.com',
                     'created_by': admin}
        )
        
        # Create users
        manager, created = User.objects.get_or_create(
            email='manager@example.com',
            defaults={'first_name': 'John', 'last_name': 'Manager',
                     'role': 'store_manager', 'store': store1}
        )
        if created:
            manager.set_password(os.environ.get('MANAGER_PASSWORD', 'change_this_password_immediately'))
            manager.save()
            
        receiver, created = User.objects.get_or_create(
            email='receiver@example.com',
            defaults={'first_name': 'Bob', 'last_name': 'Receiver',
                     'role': 'stock_receiver', 'store': store1}
        )
        if created:
            receiver.set_password(os.environ.get('RECEIVER_PASSWORD', 'change_this_password_immediately'))
            receiver.save()
            
        staff, created = User.objects.get_or_create(
            email='staff@example.com',
            defaults={'first_name': 'Alice', 'last_name': 'Staff',
                     'role': 'shelf_staff', 'store': store1}
        )
        if created:
            staff.set_password(os.environ.get('STAFF_PASSWORD', 'change_this_password_immediately'))
            staff.save()
            
        auditor, created = User.objects.get_or_create(
            email='auditor@example.com',
            defaults={'first_name': 'Carol', 'last_name': 'Auditor',
                     'role': 'auditor', 'store': store1}
        )
        if created:
            auditor.set_password(os.environ.get('AUDITOR_PASSWORD', 'change_this_password_immediately'))
            auditor.save()
        
        # Create category & supplier
        dairy_cat, _ = Category.objects.get_or_create(
            name='Dairy',
            defaults={'description': 'Dairy products', 'created_by': admin}
        )
        
        supplier, _ = Supplier.objects.get_or_create(
            name='Fresh Dairy Co.',
            defaults={'email': 'supplier@dairy.com', 'phone': '555-1001',
                     'address': '123 Supplier St', 'created_by': admin}
        )
        
        # Create products
        today = timezone.now().date()
        
        milk, _ = Product.objects.get_or_create(
            barcode='0712345678901',
            defaults={
                'name': 'Fresh Milk 1L', 'description': 'Whole milk',
                'category': dairy_cat, 'supplier': supplier,
                'cost_price': Decimal('2.50'), 'selling_price': Decimal('3.99'),
                'expiry_date': today + timedelta(days=7),
                'quantity': 50, 'created_by': admin, 'store': store1
            }
        )
        
        # Create shelf location
        location, _ = ShelfLocation.objects.get_or_create(
            store=store1,
            location_code='A1-DAIRY-L',
            defaults={'aisle': 'A1', 'section': 'Dairy', 'position': 'Left',
                     'capacity': 100, 'created_by': admin}
        )
        
        # Create batch
        batch, _ = ProductBatch.objects.get_or_create(
            batch_number='BATCH001',
            defaults={
                'product': milk, 'gtin': milk.barcode,
                'expiry_date': today + timedelta(days=2),
                'manufacture_date': today - timedelta(days=5),
                'quantity': 35, 'original_quantity': 50,
                'unit_cost': Decimal('2.50'), 'unit_selling_price': Decimal('3.99'),
                'store': store1, 'received_by': receiver
            }
        )
        
        # Create batch location
        BatchLocation.objects.get_or_create(
            batch=batch, shelf_location=location,
            defaults={'quantity': 35, 'placed_by': staff,
                     'placed_at': timezone.now()}
        )
        
        # Note: Receiving logs use ManyToMany with batches, skipping for simplicity
        
        # Create expiry alert
        ExpiryAlert.objects.get_or_create(
            batch=batch,
            defaults={
                'store': store1, 'severity': 'critical',
                'days_until_expiry': 2, 'quantity_at_risk': 35,
                'estimated_loss': Decimal('87.50'),
                'suggested_action': 'clearance'
            }
        )
        
        # Create task
        Task.objects.get_or_create(
            store=store1,
            title='Remove expired milk batch',
            defaults={
                'task_type': 'dispose', 'description': 'Remove expired milk batch',
                'priority': 'urgent', 'batch': batch,
                'assigned_to': staff, 'assigned_by': manager,
                'status': 'pending', 'due_date': timezone.now()
            }
        )
        
        # Create audit
        audit, _ = ShelfAudit.objects.get_or_create(
            audit_number='AUD001',
            defaults={
                'store': store1, 'auditor': auditor,
                'status': 'in_progress', 'notes': 'Weekly audit'
            }
        )
        
        AuditItem.objects.get_or_create(
            audit=audit, batch=batch,
            defaults={
                'quantity_found': 35, 'quantity_expected': 35,
                'status': 'ok'
            }
        )
        
        self.stdout.write(self.style.SUCCESS('\n✅ Test data created!'))
        self.stdout.write('\nAccounts created with environment-defined passwords.')
        self.stdout.write('  manager@example.com - Store Manager')
        self.stdout.write('  receiver@example.com - Stock Receiver')
        self.stdout.write('  staff@example.com - Shelf Staff')
        self.stdout.write('  auditor@example.com - Auditor')
        self.stdout.write('  admin@example.com - Admin')
