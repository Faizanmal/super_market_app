"""
Django management command to set up multi-store system with sample data
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
import random
 
from products.models import (
    Category, Supplier, Product, Store, StoreInventory, 
    InterStoreTransfer, StorePerformanceMetrics, StoreUser
)

User = get_user_model()


class Command(BaseCommand):
    help = 'Set up multi-store system with sample data'

    def add_arguments(self, parser):
        parser.add_argument(
            '--no-sample-data',
            action='store_true',
            help='Skip creating sample data, only create tables',
        )
        parser.add_argument(
            '--stores',
            type=int,
            default=3,
            help='Number of sample stores to create (default: 3)',
        )
        parser.add_argument(
            '--products',
            type=int,
            default=50,
            help='Number of sample products to create (default: 50)',
        )

    def handle(self, *args, **options):
        self.stdout.write('Setting up multi-store management system...')
        
        # Create sample data if requested
        if not options['no_sample_data']:
            self.create_sample_data(
                num_stores=options['stores'],
                num_products=options['products']
            )
        
        self.stdout.write(
            self.style.SUCCESS('Multi-store system setup completed successfully!')
        )

    def create_sample_data(self, num_stores=3, num_products=50):
        """Create comprehensive sample data for multi-store system"""
        
        self.stdout.write('Creating sample data...')
        
        # Create admin user if doesn't exist
        admin_user = self.create_admin_user()
        
        # Create categories and suppliers
        categories = self.create_categories()
        suppliers = self.create_suppliers()
        
        # Create sample products
        products = self.create_products(categories, suppliers, num_products)
        
        # Create stores
        stores = self.create_stores(admin_user, num_stores)
        
        # Create store inventories
        self.create_store_inventories(stores, products)
        
        # Create sample transfers
        self.create_sample_transfers(stores, products, admin_user)
        
        # Create performance metrics
        self.create_performance_metrics(stores)
        
        # Create store users
        self.create_store_users(stores, admin_user)
        
        self.stdout.write(f'Created {len(stores)} stores with sample data')

    def create_admin_user(self):
        """Create or get admin user"""
        try:
            admin_user = User.objects.get(username='admin')
            self.stdout.write('Using existing admin user')
        except User.DoesNotExist:
            admin_user = User.objects.create_superuser(
                username='admin',
                email='admin@supermarket.com',
                password=os.environ.get('ADMIN_PASSWORD', 'change_this_password_immediately'),
                first_name='System',
                last_name='Administrator'
            )
            self.stdout.write('Created admin user: admin (password from environment variable)')
        
        return admin_user

    def create_categories(self):
        """Create sample categories"""
        category_names = [
            'Fruits & Vegetables', 'Dairy & Eggs', 'Meat & Seafood',
            'Bakery', 'Beverages', 'Snacks', 'Frozen Foods',
            'Canned Goods', 'Health & Beauty', 'Household Items'
        ]
        
        categories = []
        for name in category_names:
            category, created = Category.objects.get_or_create(
                name=name,
                defaults={'description': f'{name} products'}
            )
            categories.append(category)
        
        self.stdout.write(f'Created/found {len(categories)} categories')
        return categories

    def create_suppliers(self):
        """Create sample suppliers"""
        supplier_data = [
            {'name': 'Fresh Farm Co.', 'email': 'orders@freshfarm.com', 'phone': '555-0101'},
            {'name': 'Dairy Direct Ltd.', 'email': 'sales@dairydirect.com', 'phone': '555-0102'},
            {'name': 'Metro Meat Supply', 'email': 'orders@metromeat.com', 'phone': '555-0103'},
            {'name': 'Global Foods Inc.', 'email': 'orders@globalfoods.com', 'phone': '555-0104'},
            {'name': 'Beverage World', 'email': 'sales@beverageworld.com', 'phone': '555-0105'},
        ]
        
        suppliers = []
        for data in supplier_data:
            supplier, created = Supplier.objects.get_or_create(
                name=data['name'],
                defaults={
                    'email': data['email'],
                    'phone': data['phone'],
                    'address': f'123 {data["name"]} Street, Business District, NY 10001'
                }
            )
            suppliers.append(supplier)
        
        self.stdout.write(f'Created/found {len(suppliers)} suppliers')
        return suppliers

    def create_products(self, categories, suppliers, num_products):
        """Create sample products"""
        product_templates = [
            ('Organic Bananas', 'Fruits & Vegetables', 1.99, 2.49),
            ('Fresh Milk 1L', 'Dairy & Eggs', 3.49, 4.29),
            ('Ground Beef 1lb', 'Meat & Seafood', 5.99, 7.49),
            ('Whole Wheat Bread', 'Bakery', 2.99, 3.99),
            ('Orange Juice 1L', 'Beverages', 4.49, 5.99),
            ('Potato Chips', 'Snacks', 2.49, 3.49),
            ('Frozen Pizza', 'Frozen Foods', 6.99, 8.99),
            ('Canned Tomatoes', 'Canned Goods', 1.49, 2.19),
            ('Shampoo 300ml', 'Health & Beauty', 7.99, 10.99),
            ('Laundry Detergent', 'Household Items', 12.99, 16.99),
        ]
        
        products = []
        for i in range(num_products):
            template = product_templates[i % len(product_templates)]
            name = f"{template[0]} #{i+1:03d}"
            
            # Find category
            category = next((c for c in categories if c.name == template[1]), categories[0])
            supplier = random.choice(suppliers)
            
            product, created = Product.objects.get_or_create(
                name=name,
                defaults={
                    'category': category,
                    'supplier': supplier,
                    'barcode': f"123456{i+1:06d}",
                    'cost_price': Decimal(str(template[2])),
                    'selling_price': Decimal(str(template[3])),
                    'description': f'High quality {name.lower()}',
                    'reorder_level': random.randint(10, 50),
                    'max_stock': random.randint(100, 500),
                    'location': f'Aisle {random.randint(1, 20)}, Shelf {random.randint(1, 5)}',
                }
            )
            products.append(product)
        
        self.stdout.write(f'Created/found {len(products)} products')
        return products

    def create_stores(self, admin_user, num_stores):
        """Create sample stores"""
        store_templates = [
            {
                'name': 'Downtown Main Store',
                'code': 'MAIN001',
                'type': 'main',
                'city': 'New York',
                'state': 'NY',
                'address': '123 Main Street',
                'postal_code': '10001'
            },
            {
                'name': 'Westside Branch',
                'code': 'WEST001',
                'type': 'branch',
                'city': 'New York',
                'state': 'NY',
                'address': '456 West Avenue',
                'postal_code': '10002'
            },
            {
                'name': 'Central Warehouse',
                'code': 'WARE001',
                'type': 'warehouse',
                'city': 'Brooklyn',
                'state': 'NY',
                'address': '789 Industrial Blvd',
                'postal_code': '11201'
            },
            {
                'name': 'Eastside Franchise',
                'code': 'EAST001',
                'type': 'franchise',
                'city': 'Queens',
                'state': 'NY',
                'address': '321 East Road',
                'postal_code': '11101'
            },
            {
                'name': 'Uptown Express',
                'code': 'UP001',
                'type': 'branch',
                'city': 'Bronx',
                'state': 'NY',
                'address': '654 Uptown Street',
                'postal_code': '10451'
            }
        ]
        
        stores = []
        for i in range(min(num_stores, len(store_templates))):
            template = store_templates[i]
            
            store, created = Store.objects.get_or_create(
                code=template['code'],
                defaults={
                    'name': template['name'],
                    'store_type': template['type'],
                    'status': 'active',
                    'address': template['address'],
                    'city': template['city'],
                    'state': template['state'],
                    'postal_code': template['postal_code'],
                    'country': 'USA',
                    'phone': f'555-{1000 + i:04d}',
                    'email': f'{template["code"].lower()}@supermarket.com',
                    'manager': admin_user,
                    'timezone': 'America/New_York',
                    'currency': 'USD',
                    'opening_hours': {
                        'monday': {'open': '08:00', 'close': '22:00'},
                        'tuesday': {'open': '08:00', 'close': '22:00'},
                        'wednesday': {'open': '08:00', 'close': '22:00'},
                        'thursday': {'open': '08:00', 'close': '22:00'},
                        'friday': {'open': '08:00', 'close': '23:00'},
                        'saturday': {'open': '09:00', 'close': '23:00'},
                        'sunday': {'open': '10:00', 'close': '21:00'},
                    },
                    'auto_reorder_enabled': True,
                    'inter_store_transfers_enabled': True,
                    'centralized_inventory': template['type'] == 'warehouse',
                    'created_by': admin_user,
                }
            )
            stores.append(store)
        
        self.stdout.write(f'Created/found {len(stores)} stores')
        return stores

    def create_store_inventories(self, stores, products):
        """Create store inventories for all stores"""
        total_inventories = 0
        
        for store in stores:
            # Each store gets 70-90% of all products
            num_products_in_store = int(len(products) * random.uniform(0.7, 0.9))
            store_products = random.sample(products, num_products_in_store)
            
            for product in store_products:
                # Check if inventory already exists
                inventory, created = StoreInventory.objects.get_or_create(
                    store=store,
                    product=product,
                    defaults={
                        'current_stock': random.randint(0, 200),
                        'min_stock_level': random.randint(5, 20),
                        'max_stock_level': random.randint(100, 300),
                        'reorder_point': random.randint(10, 50),
                        'reorder_quantity': random.randint(50, 150),
                        'store_cost_price': product.cost_price,
                        'store_selling_price': product.selling_price,
                        'aisle': f'A{random.randint(1, 20)}',
                        'shelf': f'S{random.randint(1, 10)}',
                        'bin_location': f'B{random.randint(1, 5)}',
                        'is_active': True,
                        'auto_reorder': random.choice([True, True, True, False]),  # 75% auto reorder
                    }
                )
                
                if created:
                    total_inventories += 1
        
        self.stdout.write(f'Created {total_inventories} store inventory records')

    def create_sample_transfers(self, stores, products, admin_user):
        """Create sample inter-store transfers"""
        if len(stores) < 2:
            self.stdout.write('Need at least 2 stores for transfers')
            return
        
        transfer_count = 0
        statuses = ['pending', 'approved', 'in_transit', 'received', 'cancelled']
        reasons = ['rebalancing', 'emergency', 'excess_stock', 'promotional', 'seasonal']
        
        # Create 20-30 sample transfers
        for i in range(random.randint(20, 30)):
            from_store = random.choice(stores)
            to_store = random.choice([s for s in stores if s != from_store])
            product = random.choice(products)
            
            # Check if product exists in from_store
            from_inventory = StoreInventory.objects.filter(
                store=from_store,
                product=product
            ).first()
            
            if not from_inventory:
                continue
            
            status = random.choice(statuses)
            requested_quantity = random.randint(5, min(50, from_inventory.current_stock))
            
            if requested_quantity == 0:
                continue
            
            # Create transfer
            transfer = InterStoreTransfer.objects.create(
                from_store=from_store,
                to_store=to_store,
                product=product,
                requested_quantity=requested_quantity,
                status=status,
                reason=random.choice(reasons),
                notes=f'Sample transfer #{i+1}',
                requested_by=admin_user,
                transfer_cost=Decimal(str(random.uniform(5.0, 25.0))),
                unit_cost=product.cost_price,
            )
            
            # Set additional fields based on status
            base_date = timezone.now() - timedelta(days=random.randint(1, 30))
            transfer.requested_date = base_date
            
            if status in ['approved', 'in_transit', 'received']:
                transfer.approved_quantity = requested_quantity
                transfer.approved_date = base_date + timedelta(hours=random.randint(1, 24))
                transfer.approved_by = admin_user
                
                if status in ['in_transit', 'received']:
                    transfer.shipped_date = transfer.approved_date + timedelta(hours=random.randint(1, 12))
                    
                    if status == 'received':
                        transfer.received_quantity = requested_quantity
                        transfer.received_date = transfer.shipped_date + timedelta(hours=random.randint(1, 48))
                        transfer.received_by = admin_user
            
            transfer.save()
            transfer_count += 1
        
        self.stdout.write(f'Created {transfer_count} sample transfers')

    def create_performance_metrics(self, stores):
        """Create sample performance metrics for stores"""
        metrics_count = 0
        
        # Create metrics for last 30 days
        for days_ago in range(30):
            date = timezone.now().date() - timedelta(days=days_ago)
            
            for store in stores:
                # Skip if metrics already exist
                if StorePerformanceMetrics.objects.filter(store=store, date=date).exists():
                    continue
                
                # Generate realistic metrics based on store type
                base_sales = 5000 if store.store_type == 'main' else 3000
                if store.store_type == 'warehouse':
                    base_sales = 1000
                
                # Add some randomness and weekly patterns
                weekday_multiplier = 1.2 if date.weekday() < 5 else 0.8  # Higher on weekdays
                random_factor = random.uniform(0.7, 1.3)
                
                total_sales = Decimal(str(base_sales * weekday_multiplier * random_factor))
                total_transactions = int(total_sales / random.uniform(25, 75))  # Avg transaction value
                
                # Count store inventory items
                total_products = StoreInventory.objects.filter(store=store, is_active=True).count()
                
                if total_products > 0:
                    out_of_stock = random.randint(0, max(1, total_products // 20))
                    low_stock = random.randint(0, max(1, total_products // 10))
                    overstocked = random.randint(0, max(1, total_products // 15))
                else:
                    out_of_stock = low_stock = overstocked = 0
                
                StorePerformanceMetrics.objects.create(
                    store=store,
                    date=date,
                    total_sales=total_sales,
                    total_transactions=total_transactions,
                    average_transaction_value=total_sales / max(1, total_transactions),
                    total_products=total_products,
                    total_stock_value=Decimal(str(random.uniform(50000, 200000))),
                    products_out_of_stock=out_of_stock,
                    products_low_stock=low_stock,
                    products_overstocked=overstocked,
                    products_expired=random.randint(0, 5),
                    wastage_value=Decimal(str(random.uniform(100, 1000))),
                    transfers_sent=random.randint(0, 5),
                    transfers_received=random.randint(0, 5),
                    inventory_turnover=Decimal(str(random.uniform(2.0, 8.0))),
                    stock_accuracy=Decimal(str(random.uniform(85.0, 99.5))),
                )
                
                metrics_count += 1
        
        self.stdout.write(f'Created {metrics_count} performance metric records')

    def create_store_users(self, stores, admin_user):
        """Create store user profiles"""
        # Create StoreUser for admin
        admin_store_user, created = StoreUser.objects.get_or_create(
            user=admin_user,
            defaults={
                'primary_store': stores[0] if stores else None,
                'can_manage_inventory': True,
                'can_approve_transfers': True,
                'can_view_analytics': True,
                'can_manage_users': True,
                'default_store_view': 'multi',
            }
        )
        
        if created:
            admin_store_user.assigned_stores.set(stores)
            self.stdout.write('Created admin store user profile')
        
        # Create sample staff users
        staff_data = [
            {'username': 'manager1', 'first_name': 'John', 'last_name': 'Manager', 'email': 'john@supermarket.com'},
            {'username': 'clerk1', 'first_name': 'Jane', 'last_name': 'Clerk', 'email': 'jane@supermarket.com'},
            {'username': 'supervisor1', 'first_name': 'Bob', 'last_name': 'Supervisor', 'email': 'bob@supermarket.com'},
        ]
        
        for i, staff in enumerate(staff_data):
            if i < len(stores):
                user, created = User.objects.get_or_create(
                    username=staff['username'],
                    defaults={
                        'first_name': staff['first_name'],
                        'last_name': staff['last_name'],
                        'email': staff['email'],
                        'is_staff': True,
                    }
                )
                
                if created:
                    user.set_password('password123')
                    user.save()
                
                store_user, created = StoreUser.objects.get_or_create(
                    user=user,
                    defaults={
                        'primary_store': stores[i],
                        'can_manage_inventory': staff['username'].startswith('manager'),
                        'can_approve_transfers': staff['username'].startswith('manager'),
                        'can_view_analytics': True,
                        'can_manage_users': False,
                        'default_store_view': 'single',
                    }
                )
                
                if created:
                    store_user.assigned_stores.set([stores[i]])
        
        self.stdout.write('Created sample staff users')