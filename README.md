# Super Market Helper

A comprehensive inventory management system consisting of a Flutter mobile application and a Django REST API backend.

## 📱 Overview

Super Market Helper is a full-stack solution designed to help supermarket owners and managers efficiently track inventory, manage products, monitor expiry dates, and analyze business performance. The system provides real-time insights and automated alerts to prevent stockouts and reduce waste.

## 🏗️ Architecture

This project is divided into two main components:

### Backend (Django REST Framework)
- **Location**: `backend_super_market/`
- **Technology**: Python 3.10+, Django 4.x, PostgreSQL
- **Purpose**: Provides RESTful APIs for data management and business logic

### Frontend (Flutter)
- **Location**: `super_market_helper/`
- **Technology**: Flutter (Dart), supports iOS/Android/Web
- **Purpose**: Mobile application for inventory management and analytics

## 🚀 Features

### Core Functionality
- **Product Management**: Add, update, delete products with barcode support
- **Inventory Tracking**: Real-time stock levels and automatic low-stock alerts
- **Expiry Management**: Track product expiry dates with automated notifications
- **Stock Movements**: Record stock in/out, adjustments, and wastage
- **Category & Supplier Management**: Organize products and track suppliers
- **Analytics Dashboard**: Comprehensive business insights and reporting
- **Multi-user Support**: Isolated data per user/company
- **Barcode Scanning**: Quick product lookup and inventory updates

### Security & Performance
- JWT-based authentication
- Data encryption and secure storage
- Offline capability for critical operations
- Real-time synchronization
- Scalable architecture

## 📋 Prerequisites

### Backend Requirements
- Python 3.10 or higher
- PostgreSQL 14 or higher
- pip package manager

### Frontend Requirements
- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)
- Android Studio / Xcode for mobile development

## 🛠️ Installation & Setup

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend_super_market
   ```

2. **Create virtual environment**:
   ```bash
   # Windows
   python -m venv venv
   venv\Scripts\activate

   # Linux/Mac
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Database setup**:
   - Create PostgreSQL database
   - Configure environment variables (see backend README)
   - Run migrations: `python manage.py migrate`
   - Create superuser: `python manage.py createsuperuser`

5. **Start development server**:
   ```bash
   python manage.py runserver
   ```
   API available at: `http://localhost:8000`

### Frontend Setup

1. **Navigate to frontend directory**:
   ```bash
   cd super_market_helper
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**:
   - Update API base URL in the app configuration
   - Default: `http://localhost:8000/api/v1/`

4. **Run the application**:
   ```bash
   # For Android
   flutter run

   # For iOS (macOS only)
   flutter run --device-id=<ios_device_id>

   # For Web
   flutter run -d chrome
   ```

## 📚 API Documentation

The backend provides comprehensive REST APIs. See `backend_super_market/README.md` for detailed API documentation including:

- Authentication endpoints
- Product management
- Category and supplier management
- Stock movements
- Analytics and reporting
- Security features

## 🧪 Testing

### Backend Testing
```bash
cd backend_super_market
python manage.py test
```

### Frontend Testing
```bash
cd super_market_helper
flutter test
```

## 🚀 Deployment

### Backend Deployment
- Configure production settings in `settings.py`
- Use Gunicorn for production server
- Set up PostgreSQL in production
- Configure environment variables

### Frontend Deployment
- Build for Android: `flutter build apk`
- Build for iOS: `flutter build ios`
- Build for Web: `flutter build web`

## 📁 Project Structure

```
Super Market Helper/
├── backend_super_market/          # Django REST API Backend
│   ├── accounts/                  # User authentication
│   ├── products/                  # Product & inventory management
│   ├── analytics/                 # Business analytics
│   ├── backend_super_market/      # Django settings & config
│   ├── manage.py
│   ├── requirements.txt
│   └── README.md
├── super_market_helper/           # Flutter Mobile App
│   ├── lib/                       # Dart source code
│   ├── android/                   # Android platform code
│   ├── ios/                       # iOS platform code
│   ├── web/                       # Web platform code
│   ├── pubspec.yaml
│   └── README.md
├── README.md                      # This file
└── .gitignore                     # Root gitignore
```

## 🔧 Development Guidelines

### Code Style
- **Backend**: Follow PEP 8 for Python, use type hints
- **Frontend**: Follow Flutter/Dart best practices

### Branching Strategy
- `main`: Production-ready code
- `develop`: Development branch
- Feature branches: `feature/feature-name`

### Commit Messages
- Use conventional commits: `feat:`, `fix:`, `docs:`, etc.
- Keep messages clear and descriptive

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is proprietary software for Super Market Helper.

## 📧 Support

For technical support or questions:
- Check the individual README files for component-specific help
- Review API documentation for integration issues
- Contact the development team for assistance

---

**Built with ❤️ for efficient supermarket management**