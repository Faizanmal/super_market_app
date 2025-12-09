// ==================== EXPIRY & SHELF MANAGEMENT SYSTEM ====================
// Project Architecture Documentation
// 
// This file documents the complete structure of the Expiry & Shelf Management System
// for Supermarket Operations

/*
lib/
├── main.dart                           # App entry point
├── app.dart                            # App root widget with routing
│
├── core/                               # Core functionality
│   ├── constants/                      # App constants
│   │   ├── api_constants.dart
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── expiry_thresholds.dart
│   ├── errors/                         # Error handling
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/                        # Network layer
│   │   ├── api_client.dart
│   │   ├── network_info.dart
│   │   └── interceptors.dart
│   ├── utils/                          # Utilities
│   │   ├── date_utils.dart
│   │   ├── string_utils.dart
│   │   ├── validators.dart
│   │   ├── gs1_parser.dart            # GS1-128 barcode parser
│   │   └── permissions.dart
│   └── theme/                          # Theme configuration
│       ├── app_theme.dart
│       └── text_styles.dart
│
├── config/                             # App configuration
│   ├── routes.dart                     # Route definitions
│   ├── environment.dart                # Environment variables
│   └── firebase_options.dart           # Firebase config
│
├── models/                             # Data models
│   ├── user_model.dart                 # User with roles
│   ├── store_model.dart                # Store/Branch
│   ├── product_model.dart              # Product
│   ├── batch_model.dart                # Product Batch
│   ├── shelf_location_model.dart       # Shelf location
│   ├── receiving_log_model.dart        # Receiving activity
│   ├── audit_model.dart                # Shelf audit
│   ├── alert_model.dart                # Expiry alert
│   ├── task_model.dart                 # Staff task
│   ├── photo_model.dart                # Photo evidence
│   └── response_models.dart            # API responses
│
├── providers/                          # State management (Riverpod)
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── products_provider.dart
│   ├── batches_provider.dart
│   ├── receiving_provider.dart
│   ├── shelf_provider.dart
│   ├── audit_provider.dart
│   ├── alerts_provider.dart
│   ├── tasks_provider.dart
│   ├── analytics_provider.dart
│   └── notification_provider.dart
│
├── services/                           # Business logic services
│   ├── auth/                           # Authentication
│   │   ├── auth_service.dart
│   │   ├── biometric_service.dart
│   │   └── token_storage.dart
│   ├── barcode/                        # Barcode scanning
│   │   ├── barcode_scanner_service.dart
│   │   ├── gs1_decoder_service.dart
│   │   └── ocr_service.dart
│   ├── database/                       # Local database
│   │   ├── hive_service.dart
│   │   └── sqflite_service.dart
│   ├── api/                            # API services
│   │   ├── product_api_service.dart
│   │   ├── batch_api_service.dart
│   │   ├── receiving_api_service.dart
│   │   ├── shelf_api_service.dart
│   │   ├── audit_api_service.dart
│   │   ├── alert_api_service.dart
│   │   ├── task_api_service.dart
│   │   └── analytics_api_service.dart
│   ├── storage/                        # Cloud storage
│   │   ├── firebase_storage_service.dart
│   │   └── photo_upload_service.dart
│   ├── notification/                   # Notifications
│   │   ├── fcm_service.dart
│   │   ├── local_notification_service.dart
│   │   └── alert_scheduler.dart
│   ├── qr/                             # QR code
│   │   ├── qr_generator_service.dart
│   │   └── qr_scanner_service.dart
│   ├── export/                         # Reports export
│   │   ├── pdf_export_service.dart
│   │   └── excel_export_service.dart
│   └── sync/                           # Offline sync
│       ├── sync_service.dart
│       └── conflict_resolver.dart
│
├── widgets/                            # Reusable widgets
│   ├── common/                         # Common widgets
│   │   ├── app_bar.dart
│   │   ├── loading_indicator.dart
│   │   ├── error_widget.dart
│   │   ├── empty_state.dart
│   │   └── custom_button.dart
│   ├── cards/                          # Card widgets
│   │   ├── product_card.dart
│   │   ├── batch_card.dart
│   │   ├── shelf_card.dart
│   │   ├── alert_card.dart
│   │   └── task_card.dart
│   ├── forms/                          # Form widgets
│   │   ├── custom_text_field.dart
│   │   ├── date_picker_field.dart
│   │   ├── dropdown_field.dart
│   │   └── image_picker_field.dart
│   ├── charts/                         # Chart widgets
│   │   ├── expiry_chart.dart
│   │   ├── category_chart.dart
│   │   └── trend_chart.dart
│   └── expiry/                         # Expiry-specific
│       ├── expiry_badge.dart
│       ├── expiry_timeline.dart
│       └── color_coded_indicator.dart
│
└── screens/                            # App screens
    ├── auth/                           # Authentication
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   └── role_selection_screen.dart
    │
    ├── home/                           # Home/Dashboard
    │   ├── home_screen.dart
    │   ├── widgets/
    │   │   ├── dashboard_summary.dart
    │   │   ├── quick_actions.dart
    │   │   └── alert_summary.dart
    │   └── role_dashboards/            # Role-specific dashboards
    │       ├── manager_dashboard.dart
    │       ├── receiver_dashboard.dart
    │       ├── shelf_staff_dashboard.dart
    │       ├── auditor_dashboard.dart
    │       └── head_office_dashboard.dart
    │
    ├── receiving/                      # Module 2: Product Intake/Receiving
    │   ├── receiving_screen.dart
    │   ├── scan_barcode_screen.dart
    │   ├── manual_entry_screen.dart
    │   ├── ocr_entry_screen.dart
    │   ├── batch_details_screen.dart
    │   ├── receiving_history_screen.dart
    │   └── widgets/
    │       ├── gs1_scanner.dart
    │       ├── batch_form.dart
    │       ├── validation_alert.dart
    │       └── pallet_photo_capture.dart
    │
    ├── shelf/                          # Module 3: Shelf Management
    │   ├── shelf_overview_screen.dart
    │   ├── location_list_screen.dart
    │   ├── location_details_screen.dart
    │   ├── add_location_screen.dart
    │   ├── assign_batch_screen.dart
    │   ├── qr_generation_screen.dart
    │   ├── shelf_map_screen.dart
    │   └── widgets/
    │       ├── location_card.dart
    │       ├── shelf_map_widget.dart
    │       ├── batch_placement_form.dart
    │       └── qr_code_display.dart
    │
    ├── audit/                          # Module 4: Shelf Audit
    │   ├── audit_list_screen.dart
    │   ├── start_audit_screen.dart
    │   ├── audit_in_progress_screen.dart
    │   ├── audit_details_screen.dart
    │   ├── scan_audit_item_screen.dart
    │   └── widgets/
    │       ├── audit_form.dart
    │       ├── audit_item_card.dart
    │       ├── findings_summary.dart
    │       └── photo_evidence_list.dart
    │
    ├── alerts/                         # Module 5: Expiry Monitoring & Alerts
    │   ├── alerts_screen.dart
    │   ├── alert_details_screen.dart
    │   ├── category_alerts_screen.dart
    │   ├── location_alerts_screen.dart
    │   └── widgets/
    │       ├── alert_filter.dart
    │       ├── severity_indicator.dart
    │       ├── suggested_action_widget.dart
    │       └── alert_timeline.dart
    │
    ├── analytics/                      # Module 6: Dashboard & Analytics
    │   ├── analytics_screen.dart
    │   ├── store_comparison_screen.dart
    │   ├── loss_report_screen.dart
    │   ├── supplier_performance_screen.dart
    │   ├── predictive_insights_screen.dart
    │   └── widgets/
    │       ├── kpi_card.dart
    │       ├── comparison_chart.dart
    │       ├── trend_analysis.dart
    │       └── prediction_widget.dart
    │
    ├── tasks/                          # Module 10: Tasks & Notifications
    │   ├── tasks_screen.dart
    │   ├── task_details_screen.dart
    │   ├── create_task_screen.dart
    │   ├── my_tasks_screen.dart
    │   └── widgets/
    │       ├── task_list_item.dart
    │       ├── task_form.dart
    │       ├── priority_badge.dart
    │       └── completion_form.dart
    │
    ├── reports/                        # Module 9: Reporting & Compliance
    │   ├── reports_screen.dart
    │   ├── expiry_report_screen.dart
    │   ├── audit_log_report_screen.dart
    │   ├── disposal_report_screen.dart
    │   ├── custom_report_screen.dart
    │   └── widgets/
    │       ├── report_filter.dart
    │       ├── report_preview.dart
    │       └── export_options.dart
    │
    ├── products/                       # Product Management
    │   ├── products_screen.dart
    │   ├── product_details_screen.dart
    │   ├── add_product_screen.dart
    │   ├── batches_screen.dart
    │   └── widgets/
    │       ├── product_list_item.dart
    │       ├── batch_list_item.dart
    │       └── expiry_calendar.dart
    │
    ├── profile/                        # User Profile
    │   ├── profile_screen.dart
    │   ├── settings_screen.dart
    │   ├── notification_settings_screen.dart
    │   └── widgets/
    │       ├── profile_header.dart
    │       └── settings_tile.dart
    │
    └── scanner/                        # Barcode/QR Scanner
        ├── scanner_screen.dart
        ├── gs1_scanner_screen.dart
        ├── qr_scanner_screen.dart
        └── widgets/
            ├── scanner_overlay.dart
            ├── barcode_result_display.dart
            └── gs1_data_display.dart

*/

// SYSTEM FEATURES SUMMARY:
// 
// ✅ Module 1: Role-Based Authentication (5 Roles)
// ✅ Module 2: Product Intake/Receiving (GS1-128, OCR, Manual)
// ✅ Module 3: Shelf Location Tracking (QR Codes, Maps, Photos)
// ✅ Module 4: Shelf Audit System (Periodic checks, Photo evidence)
// ✅ Module 5: Expiry Monitoring & Alerts (Automated, Color-coded)
// ✅ Module 6: Analytics Dashboard (Store-wide & HQ insights)
// ✅ Module 7: Image Management (Photo evidence system)
// ✅ Module 8: Product Database Integration (GTIN lookup)
// ✅ Module 9: Reporting & Compliance (PDF/Excel export)
// ✅ Module 10: Notifications & Task Management (FCM, Local)

// ROLES:
// 1. Store Manager - Full access to all features
// 2. Stock Receiver - Warehouse receiving operations
// 3. Shelf Staff - Shelf placement and basic checks
// 4. Auditor/QA - Audit and compliance activities
// 5. Head Office Admin - Multi-store analytics & oversight

void main() {
  // This is an architecture documentation file
  // See actual implementation in respective module files
}
