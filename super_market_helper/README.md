# Super Market Helper - Mobile App

A comprehensive Flutter mobile application for supermarket inventory management, expiry tracking, and business analytics. This app works seamlessly with the Django REST API backend to provide a complete inventory management solution.

## 📱 Overview

Super Market Helper is a feature-rich mobile application designed for supermarket owners and managers to efficiently manage their inventory, track product expiry dates, monitor stock levels, and gain valuable business insights through comprehensive analytics.

## 🚀 Features

### Core Functionality
- **Product Management**: Add, update, and manage products with barcode scanning support
- **Inventory Tracking**: Real-time stock monitoring with automatic low-stock alerts
- **Expiry Management**: Track product expiry dates with smart notifications and alerts
- **Stock Movements**: Record stock in/out, adjustments, and wastage with photo evidence
- **Category & Supplier Management**: Organize products and manage supplier relationships
- **Analytics Dashboard**: Comprehensive business insights with interactive charts
- **Barcode Scanning**: GS1-128 barcode support for quick product lookup
- **Receipt OCR**: Extract product information from receipt images
- **Offline Support**: Critical operations work offline with sync when online

### Advanced Features
- **Multi-store Support**: Manage multiple store locations
- **Smart Pricing**: Dynamic pricing recommendations based on market data
- **IoT Integration**: Connect with smart shelves and sensors
- **Voice Commands**: Hands-free operation with speech-to-text
- **Biometric Authentication**: Secure login with fingerprint/face recognition
- **Real-time Notifications**: Push notifications for alerts and updates
- **Report Generation**: Export reports as PDF/Excel
- **PWA Support**: Install as web app on supported devices

### User Experience
- **Intuitive UI**: Clean, modern interface with Material Design
- **Dark Mode**: Automatic dark/light theme switching
- **Multi-language**: Support for multiple languages
- **Accessibility**: Screen reader support and high contrast options
- **Performance**: Optimized for smooth operation on all devices

## 📋 Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)
- Android Studio / Xcode for mobile development
- For Android: Android SDK API 21+ (Android 5.0+)
- For iOS: macOS with Xcode 12+
- Backend API running (see `../backend_super_market/README.md`)

## 🛠️ Installation & Setup

### 1. Navigate to the project directory
```bash
cd super_market_helper
```

### 2. Install Flutter dependencies
```bash
flutter pub get
```

### 3. Configure API endpoint
Update the API base URL in the app configuration:
- Default: `http://localhost:8000/api/v1/`
- For production: Update in `lib/services/api_service.dart`

### 4. Configure Firebase (Optional)
If using Firebase features:
- Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Configure Firebase project settings

### 5. Run the application
```bash
# For Android
flutter run

# For iOS (macOS only)
flutter run --device-id=<ios_device_id>

# For Web
flutter run -d chrome

# For Windows
flutter run -d windows

# For Linux
flutter run -d linux
```

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── enterprise_models.dart   # Enterprise-specific models
│   └── ...                      # Other model files
├── providers/                   # State management (Provider/Riverpod)
│   ├── auth_provider.dart       # Authentication state
│   ├── inventory_provider.dart  # Inventory management
│   └── ...                      # Other providers
├── screens/                     # UI screens
│   ├── auth/                    # Authentication screens
│   ├── inventory/               # Inventory management screens
│   ├── analytics/               # Analytics dashboard
│   └── ...                      # Other screens
├── services/                    # API and external services
│   ├── api_service.dart         # REST API client
│   ├── websocket_service.dart   # Real-time updates
│   └── ...                      # Other services
├── utils/                       # Utility functions
├── widgets/                     # Reusable UI components
├── constants/                   # App constants and themes
└── config/                      # Configuration files
```

## 🔧 Configuration

### API Configuration
Update `lib/services/api_service.dart`:
```dart
class ApiService {
  static const String baseUrl = 'YOUR_API_BASE_URL';
  // ...
}
```

### Firebase Configuration
For push notifications and cloud storage:
1. Create Firebase project
2. Add Android/iOS apps
3. Download config files
4. Place in appropriate directories

### Permissions
The app requires the following permissions:
- Camera (barcode scanning, photo evidence)
- Storage (file export, local database)
- Location (store mapping, GPS features)
- Microphone (voice commands)
- Notifications (alerts and reminders)

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Code Generation
For JSON serialization and Hive adapters:
```bash
flutter pub run build_runner build
```

## 🚀 Build & Deployment

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Windows
```bash
flutter build windows --release
```

### Linux
```bash
flutter build linux --release
```

## 📱 Supported Platforms

- **Android**: API 21+ (Android 5.0+)
- **iOS**: 12.0+
- **Web**: Modern browsers with WebRTC support
- **Windows**: Windows 10+
- **Linux**: Ubuntu 18.04+, Fedora 30+

## 🔐 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Biometric Login**: Fingerprint/face recognition
- **PIN Protection**: Additional security layer
- **Data Encryption**: Local data encryption with secure storage
- **Certificate Pinning**: API communication security

## 🌐 Offline Capabilities

- **Local Database**: SQLite with encryption
- **Sync Mechanism**: Automatic sync when online
- **Conflict Resolution**: Smart conflict handling
- **Offline Indicators**: Clear offline/online status

## 📊 Analytics & Reporting

- **Dashboard**: Real-time business metrics
- **Charts**: Interactive data visualization
- **Reports**: PDF/Excel export capabilities
- **Custom Filters**: Flexible data filtering
- **Historical Data**: Trend analysis and forecasting

## 🔧 Development Guidelines

### Code Style
- Follow Flutter/Dart best practices
- Use `flutter_lints` for code analysis
- Maintain consistent naming conventions
- Write comprehensive documentation

### State Management
- Use Provider for simple state
- Use Riverpod for complex state management
- Follow unidirectional data flow

### API Integration
- Use Dio for HTTP requests
- Implement proper error handling
- Cache responses appropriately
- Handle network connectivity changes

## 🐛 Troubleshooting

### Common Issues

**Build Failures**
- Ensure Flutter SDK is up to date: `flutter upgrade`
- Clean build: `flutter clean && flutter pub get`

**API Connection Issues**
- Verify backend is running
- Check API endpoint configuration
- Review network permissions

**Permission Issues**
- Grant required permissions in device settings
- Check platform-specific permission handling

**Performance Issues**
- Enable profile mode for debugging
- Use Flutter DevTools for performance analysis

## 🤝 Contributing

1. Follow the established code style
2. Write tests for new features
3. Update documentation as needed
4. Ensure compatibility across platforms
5. Test on multiple devices/emulators

## 📄 Dependencies

### Core Dependencies
- **State Management**: Provider, Riverpod
- **Database**: Hive, SQLite
- **Networking**: Dio, HTTP
- **Authentication**: JWT, Biometric
- **UI Components**: Material Design, Custom widgets

### Specialized Libraries
- **Barcode Scanning**: Mobile Scanner, ML Kit
- **OCR**: Google ML Kit Text Recognition
- **Charts**: FL Chart, Syncfusion Charts
- **PDF/Excel**: PDF, Excel packages
- **Maps**: Google Maps Flutter

## 📧 Support

For technical support:
- Check the main project README at `../README.md`
- Review backend API documentation at `../backend_super_market/README.md`
- Check Flutter documentation: https://flutter.dev/docs

---

**Built with ❤️ using Flutter for efficient supermarket management**
