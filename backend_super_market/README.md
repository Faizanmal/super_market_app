# Super Market Helper - Backend API

A comprehensive Django REST Framework backend for the Super Market Helper Flutter mobile application. This backend provides secure, scalable, and maintainable APIs for inventory management, expiry tracking, analytics, and multi-store operations.

## 🚀 Features

### Core Features
- **User Authentication**: JWT-based authentication with registration, login, and profile management
- **Product Management**: Full CRUD operations for products with barcode support
- **Category Management**: Organize products into categories
- **Supplier Management**: Track product suppliers and relationships
- **Stock Movements**: Record and track stock changes (in, out, wastage, adjustments)
- **Expiry Management**: Track product expiry dates with automatic status calculation
- **Analytics & Dashboard**: Comprehensive statistics and insights
- **Low Stock Alerts**: Automatic detection of low stock levels
- **Multi-user Support**: Each user has isolated data
- **Multi-store Operations**: Manage multiple store locations with centralized control

### Advanced Features
- **IoT Integration**: Connect with smart shelves, sensors, and automated systems
- **Machine Learning**: Smart pricing recommendations and demand forecasting
- **Receipt OCR**: Extract product data from receipt images
- **Barcode Processing**: Advanced GS1-128 barcode support and utilities
- **Smart Pricing**: Dynamic pricing based on market analysis and competition
- **Sustainability Tracking**: Monitor environmental impact and carbon footprint
- **Enterprise Features**: Advanced reporting, bulk operations, and enterprise workflows
- **Real-time Notifications**: WebSocket-based real-time updates and alerts
- **Currency Management**: Multi-currency support for international operations
- **Security Middleware**: Advanced security features and audit trails

### Security Features
- JWT token authentication with refresh tokens
- Password hashing and validation
- Token blacklisting on logout
- CORS configuration for Flutter app integration
- SQL injection protection through ORM
- XSS protection and input sanitization
- User data isolation and access control
- Audit logging and security monitoring

## 📋 Prerequisites

- Python 3.10 or higher
- PostgreSQL 14 or higher
- pip (Python package manager)

## 🛠️ Installation

### 1. Clone or navigate to the project
```bash
cd backend_super_market
```

### 2. Create and activate virtual environment
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Linux/Mac
python3 -m venv venv
source venv/bin/activate
```

### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure PostgreSQL Database

Create a PostgreSQL database:
```sql
CREATE DATABASE supermarket_db;
CREATE USER postgres WITH PASSWORD 'postgres';
GRANT ALL PRIVILEGES ON DATABASE supermarket_db TO postgres;
```

### 5. Environment Variables (REQUIRED for Security)

**⚠️ IMPORTANT: Never commit the `.env` file to version control!**

Create a `.env` file in the project root with secure values:
```env
# Django Settings
DEBUG=False
SECRET_KEY=your-secure-secret-key-here

# Database Configuration
DB_NAME=supermarket_db
DB_USER=postgres
DB_PASSWORD=your_secure_db_password_here
DB_HOST=localhost
DB_PORT=5432

# Test Account Passwords (for development only - change immediately)
ADMIN_PASSWORD=change_this_password_immediately
MANAGER_PASSWORD=change_this_password_immediately
RECEIVER_PASSWORD=change_this_password_immediately
STAFF_PASSWORD=change_this_password_immediately
AUDITOR_PASSWORD=change_this_password_immediately

# Security Settings
ALLOWED_HOSTS=localhost,127.0.0.1,yourdomain.com
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,https://yourdomain.com

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password-here
DEFAULT_FROM_EMAIL=noreply@supermarket.com

# Firebase Configuration (if using push notifications)
FCM_SERVER_KEY=your-fcm-server-key-here
FCM_PROJECT_ID=super-market-helper

# API Keys (if using currency conversion)
FIXER_IO_API_KEY=your-fixer-api-key-here
OPENEXCHANGERATES_API_KEY=your-openexchangerates-api-key-here
```

**Generate a secure SECRET_KEY:**
```bash
python -c "import secrets; print(secrets.token_urlsafe(50))"
```

### 6. Run Migrations
```bash
python manage.py makemigrations accounts
python manage.py makemigrations products
python manage.py makemigrations analytics
python manage.py migrate
```

### 7. Create Superuser
```bash
python manage.py createsuperuser
```

### 8. Run Development Server
```bash
python manage.py runserver
```

The API will be available at `http://localhost:8000`

## 📚 API Documentation

### Base URL
```
http://localhost:8000/api/v1/
```

### Authentication Endpoints

#### Register User
```http
POST /api/v1/auth/register/
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "password_confirm": "SecurePass123!",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+1234567890",
  "company_name": "SuperMart Store",
  "address": "123 Main St"
}
```

#### Login
```http
POST /api/v1/auth/login/
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}

Response:
{
  "refresh": "refresh_token_here",
  "access": "access_token_here",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    ...
  }
}
```

#### Get User Profile
```http
GET /api/v1/auth/profile/
Authorization: Bearer {access_token}
```

#### Update Profile
```http
PUT /api/v1/auth/profile/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "first_name": "John",
  "last_name": "Smith",
  "phone_number": "+1234567890"
}
```

#### Change Password
```http
POST /api/v1/auth/change-password/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "old_password": "OldPass123!",
  "new_password": "NewPass123!",
  "new_password_confirm": "NewPass123!"
}
```

#### Logout
```http
POST /api/v1/auth/logout/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "refresh": "refresh_token_here"
}
```

### Product Management

#### List Products
```http
GET /api/v1/products/?search=milk&category=1&ordering=-created_at
Authorization: Bearer {access_token}

Query Parameters:
- search: Search by name, barcode, or SKU
- category: Filter by category ID
- supplier: Filter by supplier ID
- min_quantity, max_quantity: Filter by quantity range
- min_price, max_price: Filter by price range
- expiry_from, expiry_to: Filter by expiry date range
- ordering: Sort results (e.g., -created_at, expiry_date)
```

#### Create Product
```http
POST /api/v1/products/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "Fresh Milk",
  "description": "Organic whole milk",
  "category": 1,
  "supplier": 1,
  "barcode": "1234567890123",
  "sku": "MILK-001",
  "quantity": 100,
  "min_stock_level": 20,
  "cost_price": "2.50",
  "selling_price": "3.99",
  "expiry_date": "2024-12-31",
  "manufacture_date": "2024-10-01",
  "batch_number": "BATCH-001",
  "location": "Shelf A1"
}
```

#### Get Product Details
```http
GET /api/v1/products/{id}/
Authorization: Bearer {access_token}
```

#### Update Product
```http
PUT /api/v1/products/{id}/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "quantity": 150,
  "selling_price": "4.49"
}
```

#### Delete Product (Soft Delete)
```http
DELETE /api/v1/products/{id}/
Authorization: Bearer {access_token}
```

#### Get Expiring Soon Products
```http
GET /api/v1/products/expiring_soon/
Authorization: Bearer {access_token}
```

#### Get Expired Products
```http
GET /api/v1/products/expired/
Authorization: Bearer {access_token}
```

#### Get Low Stock Products
```http
GET /api/v1/products/low_stock/
Authorization: Bearer {access_token}
```

#### Search by Barcode
```http
POST /api/v1/products/search_barcode/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "barcode": "1234567890123"
}
```

### Category Management

#### List Categories
```http
GET /api/v1/categories/
Authorization: Bearer {access_token}
```

#### Create Category
```http
POST /api/v1/categories/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "Dairy Products",
  "description": "Milk, cheese, yogurt, etc.",
  "icon": "🥛",
  "color": "#3498db"
}
```

#### Update Category
```http
PUT /api/v1/categories/{id}/
Authorization: Bearer {access_token}
```

#### Delete Category
```http
DELETE /api/v1/categories/{id}/
Authorization: Bearer {access_token}
```

### Supplier Management

#### List Suppliers
```http
GET /api/v1/suppliers/
Authorization: Bearer {access_token}
```

#### Create Supplier
```http
POST /api/v1/suppliers/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "Fresh Farms Ltd",
  "contact_person": "Jane Smith",
  "email": "contact@freshfarms.com",
  "phone": "+1234567890",
  "address": "456 Farm Road"
}
```

### Stock Movements

#### List Stock Movements
```http
GET /api/v1/stock-movements/?product=1&movement_type=in
Authorization: Bearer {access_token}
```

#### Create Stock Movement
```http
POST /api/v1/stock-movements/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "product": 1,
  "movement_type": "in",
  "quantity": 50,
  "reason": "New stock arrival",
  "reference_number": "PO-12345",
  "unit_price": "2.50"
}

Movement Types:
- "in": Stock In
- "out": Stock Out
- "adjustment": Inventory Adjustment
- "wastage": Wastage/Damage
```

### Analytics & Dashboard

#### Dashboard Summary
```http
GET /api/v1/analytics/dashboard/
Authorization: Bearer {access_token}

Response:
{
  "total_products": 150,
  "total_inventory_value": 25000.00,
  "low_stock_count": 12,
  "expiring_soon_count": 8,
  "expired_count": 3,
  "out_of_stock": 5,
  "total_categories": 10,
  "total_suppliers": 15
}
```

#### Stock Summary
```http
GET /api/v1/analytics/stock-summary/
Authorization: Bearer {access_token}

Response:
{
  "out_of_stock": 5,
  "low_stock": 12,
  "adequate_stock": 133,
  "total": 150
}
```

#### Expiry Summary
```http
GET /api/v1/analytics/expiry-summary/
Authorization: Bearer {access_token}

Response:
{
  "expired": 3,
  "expiring_soon": 8,
  "fresh": 139,
  "total": 150
}
```

#### Category Distribution
```http
GET /api/v1/analytics/category-distribution/
Authorization: Bearer {access_token}
```

#### Top Products by Value
```http
GET /api/v1/analytics/top-products/?limit=10
Authorization: Bearer {access_token}
```

#### Stock Movements Summary
```http
GET /api/v1/analytics/stock-movements-summary/
Authorization: Bearer {access_token}
```

#### Profit Analysis
```http
GET /api/v1/analytics/profit-analysis/
Authorization: Bearer {access_token}
```

#### Alerts (Combined)
```http
GET /api/v1/analytics/alerts/
Authorization: Bearer {access_token}

Response:
{
  "low_stock": [...],
  "expiring_soon": [...],
  "expired": [...]
}
```

## 🏗️ Project Structure

```
backend_super_market/
├── backend_super_market/       # Main project configuration
│   ├── settings.py            # Django settings
│   ├── urls.py                # Main URL configuration
│   ├── celery.py              # Celery configuration
│   ├── asgi.py                # ASGI configuration
│   └── wsgi.py                # WSGI configuration
├── accounts/                   # User authentication app
│   ├── models.py              # Custom User model
│   ├── serializers.py         # User serializers
│   ├── views.py               # Auth views
│   ├── urls.py                # Auth URLs
│   └── admin.py               # Admin configuration
├── products/                   # Product management app
│   ├── models.py              # Product, Category, Supplier models
│   ├── serializers.py         # Product serializers
│   ├── views.py               # Product viewsets
│   ├── filters.py             # Custom filters
│   ├── urls.py                # Product URLs
│   ├── admin.py               # Admin configuration
│   ├── advanced_ml_models.py  # ML models for pricing/analytics
│   ├── advanced_ml_views.py   # ML-powered API views
│   ├── iot_models.py          # IoT device models
│   ├── iot_views.py           # IoT integration views
│   ├── smart_pricing_models.py # Smart pricing models
│   ├── smart_pricing_views.py # Smart pricing APIs
│   ├── sustainability_models.py # Sustainability tracking
│   ├── sustainability_views.py # Sustainability APIs
│   ├── multi_store_models.py  # Multi-store models
│   ├── multi_store_views.py   # Multi-store APIs
│   ├── barcode_utils.py       # Barcode processing utilities
│   ├── barcode_views.py       # Barcode APIs
│   ├── currency_utils.py      # Currency conversion utilities
│   ├── receipt_ocr.py         # Receipt OCR processing
│   ├── notification_service.py # Notification services
│   ├── security_middleware.py # Security middleware
│   ├── security_models.py     # Security models
│   ├── websocket_consumers.py # WebSocket consumers
│   ├── consumers.py           # Async consumers
│   ├── tasks.py               # Celery tasks
│   ├── routing.py             # WebSocket routing
│   └── management/            # Custom management commands
├── analytics/                  # Analytics app
│   ├── views.py               # Analytics views
│   ├── urls.py                # Analytics URLs
│   └── apps.py                # App configuration
├── celery_app.py              # Celery application
├── db.sqlite3                 # SQLite database (development)
├── manage.py                  # Django management script
├── requirements.txt           # Python dependencies
├── setup.bat                  # Windows setup script
├── test_new_apis.py           # API testing script
└── README.md                  # This file
```

## 🔐 Security Best Practices

1. **JWT Tokens**: Access tokens expire after 1 day, refresh tokens after 7 days
2. **Password Validation**: Strong password requirements enforced
3. **Data Isolation**: Each user can only access their own data
4. **Token Blacklisting**: Tokens are blacklisted on logout
5. **CORS Configuration**: Properly configured for Flutter app
6. **SQL Injection Protection**: ORM-based queries prevent SQL injection
7. **XSS Protection**: Django's built-in protection enabled

## 🧪 Testing

### Run Tests
```bash
python manage.py test
```

### Create Test Data
```python
python manage.py shell

from accounts.models import User
from products.models import Category, Product
from datetime import date, timedelta

# Create test user
user = User.objects.create_user(
    email='test@example.com',
    password='Test123!',
    first_name='Test',
    last_name='User'
)

# Create test category
category = Category.objects.create(
    name='Test Category',
    created_by=user
)

# Create test product
product = Product.objects.create(
    name='Test Product',
    barcode='TEST123',
    category=category,
    quantity=100,
    cost_price=10.00,
    selling_price=15.00,
    expiry_date=date.today() + timedelta(days=30),
    created_by=user
)
```

## 📱 Flutter Integration

### Add Dependencies
```yaml
dependencies:
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
  provider: ^6.1.1
```

### Example API Service
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  String? _token;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access'];
      return data;
    } else {
      throw Exception('Login failed');
    }
  }

  Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load products');
    }
  }
}
```

## 🚀 Deployment

### Production Settings

Update `settings.py` for production:
```python
DEBUG = False
ALLOWED_HOSTS = ['your-domain.com']

# Use environment variables for sensitive data
SECRET_KEY = os.environ.get('SECRET_KEY')
```

### Deploy with Gunicorn
```bash
gunicorn backend_super_market.wsgi:application --bind 0.0.0.0:8000
```

## 📝 Environment Variables

Create `.env` file for production:
```env
DEBUG=False
SECRET_KEY=your-production-secret-key
DB_NAME=production_db
DB_USER=db_user
DB_PASSWORD=secure_password
DB_HOST=db_host
DB_PORT=5432
ALLOWED_HOSTS=your-domain.com,www.your-domain.com
```

## 🤝 Contributing

This is a production-ready backend with:
- Clean architecture
- Well-documented code
- Type hints and docstrings
- Comprehensive error handling
- Scalable structure

## 📄 License

This project is part of the Super Market Helper application.

## 📧 Support

For issues or questions, please contact the development team.

---

**Made with ❤️ for Super Market Helper**
