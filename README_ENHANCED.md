# 🛒 SuperMart Pro - Enterprise Inventory Management System

<p align="center">
  <img src="docs/assets/logo.png" alt="SuperMart Pro Logo" width="200"/>
</p>

<p align="center">
  <strong>AI-Powered Inventory Intelligence for Modern Retail</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#installation">Installation</a> •
  <a href="#api-docs">API Docs</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## 🌟 Overview

**SuperMart Pro** is a comprehensive, enterprise-grade inventory management system designed for modern supermarket and retail operations. Built with cutting-edge technologies, it combines powerful backend services with a beautiful, intuitive mobile application to deliver real-time inventory intelligence, AI-powered predictions, and seamless multi-store management.

### Why SuperMart Pro?

| Challenge | Our Solution |
|-----------|--------------|
| 🗓️ **Expiry Waste** | AI-powered expiry prediction & dynamic pricing reduces waste by up to 40% |
| 📦 **Stock Management** | Real-time inventory tracking with automated reorder suggestions |
| 🏪 **Multi-Store Chaos** | Centralized dashboard with inter-store transfer capabilities |
| 📊 **Poor Visibility** | Comprehensive analytics with predictive insights |
| 🔐 **Security Concerns** | Enterprise-grade security with role-based access control |
| 📱 **On-the-Go Access** | Cross-platform mobile app with offline capabilities |

---

## ✨ Features

### Core Inventory Management
- **📦 Product Management** - Complete CRUD with barcode scanning
- **📁 Category Organization** - Hierarchical categorization with custom attributes
- **👥 Supplier Management** - Track suppliers, contracts, and performance
- **📈 Stock Tracking** - Real-time quantity monitoring with movement history
- **🔄 Batch Management** - FIFO/FEFO tracking for perishables

### Expiry & Freshness Intelligence
- **⏰ Expiry Alerts** - Multi-level notifications (7-day, 3-day, critical)
- **🤖 AI Predictions** - Machine learning-based waste forecasting
- **💰 Dynamic Pricing** - Automated markdown suggestions for near-expiry items
- **📊 Freshness Score** - Real-time inventory health metrics

### Multi-Store Operations
- **🏪 Store Network** - Manage unlimited stores from single dashboard
- **🔄 Inter-Store Transfers** - Seamless stock movement between locations
- **📊 Comparative Analytics** - Store performance benchmarking
- **👥 Role-Based Access** - Granular permissions per store

### Smart Analytics & AI
- **📈 Demand Forecasting** - Predict sales patterns using historical data
- **🎯 Reorder Optimization** - AI-calculated reorder points and quantities
- **💡 Smart Recommendations** - Actionable insights for inventory optimization
- **📊 Custom Reports** - Export to PDF, Excel, CSV

### Enterprise Features
- **🔐 Security** - JWT authentication, rate limiting, audit logging
- **🌐 Multi-Currency** - Support for multiple currencies with live rates
- **📱 Offline Mode** - Full functionality without internet
- **🔔 Real-time Notifications** - Push, email, and in-app alerts
- **🎤 Voice Commands** - Hands-free operation support

### IoT & Sustainability
- **🌡️ Smart Shelf Integration** - Temperature & humidity monitoring
- **♻️ Sustainability Tracking** - Waste reduction metrics & carbon footprint
- **🏆 Green Supplier Ratings** - Environmental performance tracking

---

## 🏗️ Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SuperMart Pro Architecture                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐         │
│  │   Flutter App   │    │   Web Portal    │    │  Admin Panel    │         │
│  │  (iOS/Android)  │    │    (React)      │    │   (Django)      │         │
│  └────────┬────────┘    └────────┬────────┘    └────────┬────────┘         │
│           │                      │                      │                   │
│           └──────────────────────┼──────────────────────┘                   │
│                                  │                                          │
│                        ┌─────────▼─────────┐                               │
│                        │   API Gateway     │                               │
│                        │   (Nginx/Kong)    │                               │
│                        └─────────┬─────────┘                               │
│                                  │                                          │
│  ┌───────────────────────────────┼───────────────────────────────────┐     │
│  │                      Django REST Backend                           │     │
│  ├─────────────────────────────────────────────────────────────────────┤     │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────────────┐  │     │
│  │  │  Auth     │ │ Products  │ │ Analytics │ │  AI/ML Engine     │  │     │
│  │  │  Module   │ │  Module   │ │  Module   │ │  (Predictions)    │  │     │
│  │  └───────────┘ └───────────┘ └───────────┘ └───────────────────┘  │     │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────────────┐  │     │
│  │  │  Multi-   │ │ Notifi-   │ │   IoT     │ │  Security &       │  │     │
│  │  │  Store    │ │ cations   │ │  Service  │ │  Compliance       │  │     │
│  │  └───────────┘ └───────────┘ └───────────┘ └───────────────────┘  │     │
│  └───────────────────────────────┬───────────────────────────────────┘     │
│                                  │                                          │
│  ┌───────────────────────────────┼───────────────────────────────────┐     │
│  │                       Data Layer                                    │     │
│  ├─────────────────────────────────────────────────────────────────────┤     │
│  │  ┌─────────────┐   ┌─────────────┐   ┌─────────────────────────┐   │     │
│  │  │ PostgreSQL  │   │   Redis     │   │     Celery + RabbitMQ   │   │     │
│  │  │  (Primary)  │   │  (Cache)    │   │   (Background Tasks)    │   │     │
│  │  └─────────────┘   └─────────────┘   └─────────────────────────┘   │     │
│  └───────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Tech Stack

#### Backend (Django REST Framework)
| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Django 5.x | Core web framework |
| API | Django REST Framework | RESTful API |
| Authentication | JWT (SimpleJWT) | Token-based auth |
| Database | PostgreSQL 15 | Primary data store |
| Cache | Redis 7 | Session & data cache |
| Task Queue | Celery 5.x | Background processing |
| WebSocket | Django Channels | Real-time updates |
| ML | scikit-learn, pandas | Predictions |

#### Frontend (Flutter)
| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Flutter 3.x | Cross-platform UI |
| State | Provider + Riverpod | State management |
| Storage | Hive + SQLite | Local database |
| Network | Dio + HTTP | API communication |
| Charts | FL Chart | Data visualization |
| Scanner | ML Kit | Barcode scanning |

---

## 🚀 Installation

### Prerequisites

- **Backend**: Python 3.11+, PostgreSQL 15+, Redis 7+
- **Frontend**: Flutter 3.16+, Dart 3.2+
- **Tools**: Docker, Git

### Quick Start with Docker

```bash
# Clone the repository
git clone https://github.com/your-org/supermart-pro.git
cd supermart-pro

# Start all services with Docker Compose
docker-compose up -d

# Access the services
# - API: http://localhost:8000/api/
# - API Docs: http://localhost:8000/api/docs/
# - Admin: http://localhost:8000/admin/
```

### Manual Backend Setup

```bash
# Navigate to backend directory
cd backend_super_market

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Start development server
python manage.py runserver

# In separate terminal, start Celery
celery -A backend_super_market worker -l info

# Start Celery Beat (scheduler)
celery -A backend_super_market beat -l info
```

### Manual Flutter Setup

```bash
# Navigate to Flutter directory
cd super_market_helper

# Get dependencies
flutter pub get

# Generate code (for Hive adapters, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run

# Build for production
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

---

## 📚 API Documentation

### Authentication

```http
POST /api/auth/login/
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password"
}

Response:
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGci...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGci...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "store_manager"
  }
}
```

### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| **Products** |||
| GET | `/api/products/products/` | List products |
| POST | `/api/products/products/` | Create product |
| GET | `/api/products/products/{id}/` | Get product |
| PATCH | `/api/products/products/{id}/` | Update product |
| DELETE | `/api/products/products/{id}/` | Delete product |
| GET | `/api/products/products/expiring_soon/` | Expiring products |
| GET | `/api/products/products/low_stock/` | Low stock products |
| POST | `/api/products/products/search_barcode/` | Search by barcode |
| **Analytics** |||
| GET | `/api/products/smart-analytics/dashboard_metrics/` | Dashboard data |
| GET | `/api/products/smart-analytics/demand_forecast/` | AI forecast |
| GET | `/api/products/smart-analytics/ai_recommendations/` | AI suggestions |
| **Stores** |||
| GET | `/api/products/stores/` | List stores |
| POST | `/api/products/store-transfers/` | Transfer stock |

### Full API Documentation
- **Swagger UI**: `http://localhost:8000/api/docs/`
- **ReDoc**: `http://localhost:8000/api/redoc/`
- **OpenAPI Schema**: `http://localhost:8000/api/schema/`

---

## 📂 Project Structure

```
supermart-pro/
├── backend_super_market/        # Django Backend
│   ├── accounts/                # Authentication & users
│   ├── analytics/               # Reports & analytics
│   ├── core/                    # Shared utilities
│   │   ├── base_models.py       # Abstract models
│   │   ├── exceptions.py        # Custom exceptions
│   │   ├── permissions.py       # RBAC permissions
│   │   ├── pagination.py        # Pagination classes
│   │   ├── mixins.py            # View mixins
│   │   └── services.py          # Service layer
│   ├── products/                # Core business logic
│   │   ├── models.py            # Data models
│   │   ├── views.py             # API views
│   │   ├── serializers.py       # Data serialization
│   │   ├── services.py          # Business services
│   │   ├── ai_engine.py         # ML predictions
│   │   └── tasks.py             # Celery tasks
│   ├── backend_super_market/    # Project config
│   │   ├── settings.py          # Django settings
│   │   ├── urls.py              # URL routing
│   │   └── celery.py            # Celery config
│   └── manage.py
│
├── super_market_helper/         # Flutter Frontend
│   ├── lib/
│   │   ├── core/                # Core utilities
│   │   │   ├── constants/       # App constants
│   │   │   ├── theme/           # Theming
│   │   │   ├── network/         # API client
│   │   │   └── storage/         # Local storage
│   │   ├── models/              # Data models
│   │   ├── providers/           # State management
│   │   ├── services/            # API services
│   │   ├── screens/             # UI screens
│   │   └── widgets/             # Reusable widgets
│   ├── pubspec.yaml             # Dependencies
│   └── README.md
│
├── docs/                        # Documentation
│   ├── api/                     # API docs
│   ├── architecture/            # Architecture docs
│   └── guides/                  # User guides
│
├── docker/                      # Docker configs
│   ├── Dockerfile.backend
│   ├── Dockerfile.frontend
│   └── docker-compose.yml
│
└── README.md
```

---

## 🔐 Security

### Implemented Security Measures

- ✅ **JWT Authentication** with token refresh
- ✅ **Role-Based Access Control (RBAC)** with 5 role levels
- ✅ **Rate Limiting** - 100/hour anonymous, 1000/hour authenticated
- ✅ **Request Signing** for sensitive operations
- ✅ **Audit Logging** for all critical actions
- ✅ **Data Encryption** at rest and in transit
- ✅ **CORS Protection** with whitelist
- ✅ **Input Validation** at all layers
- ✅ **SQL Injection Protection** via ORM
- ✅ **XSS Protection** headers

### Security Best Practices

```bash
# Production environment variables
SECRET_KEY=<generate-strong-key>
DEBUG=False
ALLOWED_HOSTS=your-domain.com
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

---

## 🧪 Testing

### Backend Tests

```bash
# Run all tests
python manage.py test

# Run with coverage
coverage run manage.py test
coverage report -m

# Run specific test module
python manage.py test products.tests.test_views
```

### Frontend Tests

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

---

## 🚀 Deployment

### Production Deployment Checklist

- [ ] Set `DEBUG=False`
- [ ] Configure production database
- [ ] Set up Redis for caching
- [ ] Configure Celery workers
- [ ] Enable SSL/TLS
- [ ] Set up logging and monitoring
- [ ] Configure backup strategy
- [ ] Load balancer setup
- [ ] CDN for static files

### Docker Production

```bash
docker-compose -f docker-compose.prod.yml up -d
```

---

## 📈 Roadmap

### Version 2.1 (Q1 2025)
- [ ] Advanced ML demand forecasting
- [ ] Supplier API integrations
- [ ] Enhanced IoT sensor support
- [ ] Multi-language support

### Version 2.2 (Q2 2025)
- [ ] Customer loyalty integration
- [ ] POS system integration
- [ ] Advanced reporting dashboard
- [ ] Mobile POS feature

### Version 3.0 (Q3 2025)
- [ ] AI-powered automated ordering
- [ ] Computer vision for shelf monitoring
- [ ] Blockchain supply chain tracking
- [ ] Advanced analytics with AI insights

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

### Development Setup

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

---

## 📞 Support

- **Documentation**: [docs.supermart.pro](https://docs.supermart.pro)
- **Email**: support@supermart.pro
- **Issues**: [GitHub Issues](https://github.com/your-org/supermart-pro/issues)

---

<p align="center">
  Made with ❤️ by the SuperMart Pro Team
</p>
