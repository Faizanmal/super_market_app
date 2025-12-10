# SuperMart Pro Architecture Documentation

## System Architecture Overview

SuperMart Pro follows a modern, scalable microservices-ready architecture designed for enterprise-grade inventory management.

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                                    Client Layer                                       │
├──────────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐  │
│  │   Flutter   │  │    Web      │  │   Admin     │  │      Third-party APIs       │  │
│  │  Mobile App │  │   Portal    │  │   Panel     │  │   (POS, ERP, Suppliers)     │  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────────────┬──────────────┘  │
│         │                │                │                        │                 │
└─────────┴────────────────┴────────────────┴────────────────────────┴─────────────────┘
                                         │
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                               API Gateway / Load Balancer                             │
│                                  (Nginx / Kong / AWS ALB)                            │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐ │
│  │ • SSL Termination • Rate Limiting • Request Routing • Load Balancing • CORS    │ │
│  └─────────────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                                 Application Layer                                     │
├──────────────────────────────────────────────────────────────────────────────────────┤
│                           Django REST Framework Backend                               │
│                                                                                       │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────────────┐   │
│  │   Authentication    │  │    Authorization    │  │       Middleware            │   │
│  │   • JWT Tokens      │  │    • RBAC           │  │   • Security Headers        │   │
│  │   • Token Refresh   │  │    • Object Level   │  │   • Rate Limiting           │   │
│  │   • Session Mgmt    │  │    • Store Access   │  │   • Audit Logging           │   │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────────────────┘   │
│                                                                                       │
│  ┌───────────────────────────────────────────────────────────────────────────────┐   │
│  │                              Service Layer                                     │   │
│  ├───────────────────────────────────────────────────────────────────────────────┤   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌──────────┐ │   │
│  │  │  Product    │ │  Inventory  │ │  Analytics  │ │   Multi-    │ │   AI/ML  │ │   │
│  │  │  Service    │ │  Service    │ │  Service    │ │   Store     │ │  Engine  │ │   │
│  │  │             │ │             │ │             │ │  Service    │ │          │ │   │
│  │  │ • CRUD Ops  │ │ • Stock Mgmt│ │ • Reports   │ │ • Transfers │ │ • Demand │ │   │
│  │  │ • Search    │ │ • Movements │ │ • Insights  │ │ • Sync      │ │   Pred.  │ │   │
│  │  │ • Categories│ │ • Expiry    │ │ • KPIs      │ │ • Hierarchy │ │ • Expiry │ │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │   Pred.  │ │   │
│  │                                                                  │ • Pricing│ │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ └──────────┘ │   │
│  │  │ Supplier    │ │ Notifica-   │ │   IoT       │ │  Security   │              │   │
│  │  │ Service     │ │ tion Svc    │ │  Service    │ │  Service    │              │   │
│  │  │             │ │             │ │             │ │             │              │   │
│  │  │ • Orders    │ │ • Push      │ │ • Sensors   │ │ • Audit     │              │   │
│  │  │ • Contracts │ │ • Email     │ │ • Shelves   │ │ • Compliance│              │   │
│  │  │ • Perf.     │ │ • SMS       │ │ • Env. Mon. │ │ • Incidents │              │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘              │   │
│  └───────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                       │
│  ┌───────────────────────────────────────────────────────────────────────────────┐   │
│  │                             Data Access Layer                                  │   │
│  │  • Django ORM • Repository Pattern • Query Optimization • Soft Deletes        │   │
│  └───────────────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                                   Data Layer                                          │
├──────────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────────────┐   │
│  │     PostgreSQL      │  │       Redis         │  │    Celery + RabbitMQ        │   │
│  │   Primary Database  │  │   Cache & Broker    │  │    Background Tasks         │   │
│  │                     │  │                     │  │                             │   │
│  │  • Products         │  │  • Session Cache    │  │  • Expiry Checks            │   │
│  │  • Users            │  │  • API Cache        │  │  • Report Generation        │   │
│  │  • Stores           │  │  • Real-time Data   │  │  • Email Sending            │   │
│  │  • Analytics        │  │  • Rate Limiting    │  │  • AI Model Training        │   │
│  │  • Audit Logs       │  │  • Pub/Sub          │  │  • Bulk Operations          │   │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Backend Architecture

### Layer Structure

```
backend_super_market/
├── core/                          # Shared Core Module
│   ├── base_models.py             # Abstract base models
│   ├── exceptions.py              # Custom exceptions
│   ├── permissions.py             # RBAC permissions
│   ├── pagination.py              # Pagination classes
│   ├── mixins.py                  # View mixins
│   ├── serializers.py             # Base serializers
│   ├── cache.py                   # Cache management
│   └── services.py                # Service layer base
│
├── accounts/                      # Authentication Module
│   ├── models.py                  # User, Role models
│   ├── views.py                   # Auth views
│   ├── serializers.py             # User serializers
│   └── services.py                # Auth service
│
├── products/                      # Core Business Logic
│   ├── models.py                  # Product, Category, Stock
│   ├── views.py                   # API ViewSets
│   ├── serializers.py             # Data serialization
│   ├── services.py                # Business logic
│   ├── ai_engine.py               # ML predictions
│   ├── tasks.py                   # Background tasks
│   └── signals.py                 # Django signals
│
└── analytics/                     # Analytics Module
    ├── models.py                  # Analytics models
    ├── views.py                   # Report views
    └── services.py                # Analytics service
```

### Design Patterns Used

#### 1. Repository Pattern
```python
# Separates data access from business logic
class ProductRepository:
    @staticmethod
    def get_by_barcode(barcode: str) -> Optional[Product]:
        return Product.objects.filter(barcode=barcode).first()
    
    @staticmethod
    def get_expiring(days: int = 7) -> QuerySet:
        threshold = timezone.now().date() + timedelta(days=days)
        return Product.objects.filter(expiry_date__lte=threshold)
```

#### 2. Service Layer Pattern
```python
# Business logic in services, not views
class InventoryService:
    def __init__(self, product_repo: ProductRepository):
        self.product_repo = product_repo
    
    def process_stock_receipt(self, product_id: int, quantity: int):
        product = self.product_repo.get_by_id(product_id)
        product.quantity += quantity
        product.save()
        self._create_stock_movement(product, quantity, 'in')
        self._check_reorder_point(product)
```

#### 3. Observer Pattern (Django Signals)
```python
# Automatic reactions to model changes
@receiver(post_save, sender=Product)
def product_saved_handler(sender, instance, created, **kwargs):
    if instance.quantity <= instance.min_stock_level:
        NotificationService.send_low_stock_alert(instance)
```

#### 4. Strategy Pattern (AI Engine)
```python
# Interchangeable prediction algorithms
class DemandPredictor(ABC):
    @abstractmethod
    def predict(self, product_id: int, days: int) -> float:
        pass

class LinearPredictor(DemandPredictor):
    def predict(self, product_id: int, days: int) -> float:
        # Linear regression implementation
        pass

class SeasonalPredictor(DemandPredictor):
    def predict(self, product_id: int, days: int) -> float:
        # Seasonal ARIMA implementation
        pass
```

---

## Frontend Architecture (Flutter)

### Clean Architecture Implementation

```
super_market_helper/lib/
├── core/                          # Core Module
│   ├── constants/                 # App-wide constants
│   │   ├── app_constants.dart
│   │   └── api_constants.dart
│   │
│   ├── theme/                     # Theming
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   │
│   ├── network/                   # Network Layer
│   │   ├── api_client.dart
│   │   ├── api_exception.dart
│   │   └── interceptors/
│   │
│   ├── storage/                   # Local Storage
│   │   ├── secure_storage.dart
│   │   └── hive_service.dart
│   │
│   └── utils/                     # Utilities
│       ├── extensions.dart
│       └── validators.dart
│
├── features/                      # Feature Modules
│   ├── auth/                      # Authentication Feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── products/                  # Products Feature
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── inventory/                 # Inventory Feature
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── analytics/                 # Analytics Feature
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart                      # App Entry Point
```

### State Management Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        State Management                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐   │
│  │   Riverpod   │    │   Provider   │    │  Local State     │   │
│  │  (App-wide)  │    │  (Feature)   │    │  (Widget-level)  │   │
│  │              │    │              │    │                  │   │
│  │ • Auth       │    │ • Product    │    │ • Form state     │   │
│  │ • Settings   │    │   List       │    │ • Animation      │   │
│  │ • Theme      │    │ • Cart       │    │ • UI toggles     │   │
│  │ • Network    │    │ • Filters    │    │                  │   │
│  └──────────────┘    └──────────────┘    └──────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    State Flow                             │   │
│  │                                                           │   │
│  │    UI Event → Provider/Notifier → Repository → API/DB    │   │
│  │                       │                                   │   │
│  │                       ▼                                   │   │
│  │              State Update → UI Rebuild                    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              Data Flow                                      │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────┐    ┌────────────┐    ┌──────────┐    ┌─────────────────────┐ │
│   │   UI    │───▶│  Provider  │───▶│ Use Case │───▶│     Repository      │ │
│   │ (Screen)│    │ (Notifier) │    │ (Domain) │    │      (Data)         │ │
│   └────┬────┘    └────────────┘    └──────────┘    └──────────┬──────────┘ │
│        │                                                      │            │
│        │              State Updates                           │            │
│        ◀──────────────────────────────────────────────────────┤            │
│                                                               │            │
│                                         ┌─────────────────────┴──────────┐ │
│                                         │                                │ │
│                                         ▼                                ▼ │
│                                 ┌──────────────┐              ┌──────────┐ │
│                                 │ Local Cache  │              │  API     │ │
│                                 │ (Hive/SQLite)│              │ (Remote) │ │
│                                 └──────────────┘              └──────────┘ │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## Database Schema

### Core Tables

```sql
-- Products Table
CREATE TABLE products_product (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) UNIQUE NOT NULL,
    barcode VARCHAR(100),
    description TEXT,
    category_id INTEGER REFERENCES products_category(id),
    supplier_id INTEGER REFERENCES products_supplier(id),
    store_id INTEGER REFERENCES products_store(id),
    price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2),
    quantity INTEGER DEFAULT 0,
    min_stock_level INTEGER DEFAULT 0,
    max_stock_level INTEGER,
    reorder_point INTEGER,
    unit VARCHAR(50),
    expiry_date DATE,
    batch_number VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    image VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP,
    
    INDEX idx_product_sku (sku),
    INDEX idx_product_barcode (barcode),
    INDEX idx_product_category (category_id),
    INDEX idx_product_expiry (expiry_date),
    INDEX idx_product_store (store_id)
);

-- Stock Movements Table
CREATE TABLE products_stockmovement (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products_product(id),
    store_id INTEGER REFERENCES products_store(id),
    movement_type VARCHAR(20) NOT NULL, -- in, out, adjustment, transfer
    quantity INTEGER NOT NULL,
    quantity_before INTEGER,
    quantity_after INTEGER,
    unit_cost DECIMAL(10,2),
    reference_number VARCHAR(100),
    notes TEXT,
    created_by_id INTEGER REFERENCES accounts_user(id),
    created_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_movement_product (product_id),
    INDEX idx_movement_type (movement_type),
    INDEX idx_movement_date (created_at)
);

-- Users Table
CREATE TABLE accounts_user (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'staff',
    is_active BOOLEAN DEFAULT TRUE,
    is_staff BOOLEAN DEFAULT FALSE,
    is_superuser BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_user_email (email),
    INDEX idx_user_role (role)
);
```

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Security Layers                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    Network Security                                   │   │
│  │  • TLS 1.3 Encryption • DDoS Protection • WAF • IP Whitelisting      │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                     │                                        │
│  ┌──────────────────────────────────┼───────────────────────────────────┐   │
│  │                    Application Security                               │   │
│  │                                  │                                    │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐   │   │
│  │  │Rate Limiting│  │Input Valid. │  │CORS/CSRF   │  │Sec. Headers│   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                     │                                        │
│  ┌──────────────────────────────────┼───────────────────────────────────┐   │
│  │                    Authentication & Authorization                     │   │
│  │                                  │                                    │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐   │   │
│  │  │JWT Auth     │  │Role-Based   │  │Object-Level │  │Store-Level │   │   │
│  │  │(Access +    │  │Access       │  │Permissions  │  │Access      │   │   │
│  │  │ Refresh)    │  │Control      │  │             │  │Control     │   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                     │                                        │
│  ┌──────────────────────────────────┼───────────────────────────────────┐   │
│  │                    Data Security                                      │   │
│  │                                  │                                    │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐   │   │
│  │  │Encryption   │  │Secure       │  │Audit        │  │Data        │   │   │
│  │  │at Rest      │  │Passwords    │  │Logging      │  │Masking     │   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Role-Based Access Control

| Role | Products | Inventory | Analytics | Users | Stores | Settings |
|------|----------|-----------|-----------|-------|--------|----------|
| Super Admin | Full | Full | Full | Full | Full | Full |
| Store Manager | Full | Full | View | View | Own Store | Limited |
| Stock Receiver | View | Create/Update | None | None | Own Store | None |
| Cashier | View | View | None | None | Own Store | None |
| Viewer | View | View | View | None | Own Store | None |

---

## Deployment Architecture

### Production Deployment

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          Production Environment                               │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐     │
│  │                        CDN (CloudFlare/AWS CloudFront)               │     │
│  │                    Static Assets • SSL • DDoS Protection             │     │
│  └─────────────────────────────────────────────────────────────────────┘     │
│                                      │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐     │
│  │                      Load Balancer (AWS ALB / Nginx)                 │     │
│  │                  Health Checks • SSL Termination • Routing           │     │
│  └─────────────────────────────────────────────────────────────────────┘     │
│                                      │                                        │
│         ┌────────────────────────────┼────────────────────────────┐          │
│         │                            │                            │          │
│         ▼                            ▼                            ▼          │
│  ┌─────────────┐             ┌─────────────┐             ┌─────────────┐     │
│  │   Backend   │             │   Backend   │             │   Backend   │     │
│  │  Instance 1 │             │  Instance 2 │             │  Instance N │     │
│  │  (Gunicorn) │             │  (Gunicorn) │             │  (Gunicorn) │     │
│  └─────────────┘             └─────────────┘             └─────────────┘     │
│                                      │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐     │
│  │                         Data Layer                                   │     │
│  │                                                                      │     │
│  │  ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐     │     │
│  │  │  PostgreSQL  │   │    Redis     │   │    Celery Workers    │     │     │
│  │  │   Primary    │   │   Cluster    │   │      (3-5 workers)   │     │     │
│  │  │   + Replica  │   │              │   │                      │     │     │
│  │  └──────────────┘   └──────────────┘   └──────────────────────┘     │     │
│  │                                                                      │     │
│  └─────────────────────────────────────────────────────────────────────┘     │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Performance Considerations

### Backend Optimizations
- Database query optimization with select_related/prefetch_related
- Redis caching for frequently accessed data
- Pagination for large datasets
- Async tasks for heavy operations
- Connection pooling

### Frontend Optimizations
- Lazy loading of screens
- Image caching and optimization
- Offline-first architecture
- Incremental state updates
- Code splitting

### Caching Strategy

| Cache Layer | TTL | Use Case |
|-------------|-----|----------|
| API Response | 5 min | Product listings |
| User Session | 1 hour | Authentication state |
| Analytics | 15 min | Dashboard metrics |
| Static Data | 24 hours | Categories, units |
| ML Predictions | 1 hour | Demand forecasts |

---

## Monitoring & Observability

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Observability Stack                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │   Logging    │  │   Metrics    │  │   Tracing    │              │
│  │  (ELK Stack) │  │ (Prometheus) │  │   (Jaeger)   │              │
│  │              │  │              │  │              │              │
│  │ • App logs   │  │ • CPU/Memory │  │ • Request    │              │
│  │ • Audit logs │  │ • Requests   │  │   tracking   │              │
│  │ • Error logs │  │ • Response   │  │ • Service    │              │
│  │              │  │   times      │  │   deps       │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│          │                  │                  │                    │
│          └──────────────────┼──────────────────┘                    │
│                             │                                        │
│                    ┌────────▼────────┐                              │
│                    │    Grafana      │                              │
│                    │   Dashboards    │                              │
│                    └────────┬────────┘                              │
│                             │                                        │
│                    ┌────────▼────────┐                              │
│                    │   Alerting      │                              │
│                    │ (PagerDuty/     │                              │
│                    │  Slack/Email)   │                              │
│                    └─────────────────┘                              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Future Architecture Considerations

### Microservices Migration Path

1. **Phase 1**: Extract Auth Service
2. **Phase 2**: Extract Notification Service  
3. **Phase 3**: Extract Analytics Service
4. **Phase 4**: Extract AI/ML Service
5. **Phase 5**: Full microservices with event-driven architecture

### Event-Driven Architecture

```
┌─────────┐    ┌─────────────┐    ┌─────────────┐
│ Service │───▶│   Message   │───▶│   Service   │
│    A    │    │    Queue    │    │      B      │
└─────────┘    │ (RabbitMQ/  │    └─────────────┘
               │   Kafka)    │
               └──────┬──────┘
                      │
                      ▼
               ┌─────────────┐
               │   Service   │
               │      C      │
               └─────────────┘
```

---

*This architecture documentation is living and should be updated as the system evolves.*
