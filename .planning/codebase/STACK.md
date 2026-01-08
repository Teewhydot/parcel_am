# Technology Stack

**Analysis Date:** 2026-01-08

## Languages

**Primary:**
- Dart 3.x - All application code in `lib/` directory
- Kotlin/Swift - Native platform channels (Android/iOS)

**Secondary:**
- JavaScript - Cloud Functions (`functions/`) and backend services
- YAML - Configuration files

## Runtime

**Environment:**
- Flutter 3.x - Cross-platform mobile framework
- Dart VM runtime - Backend services

**Package Manager:**
- pub (Dart package manager)
- Lockfile: `pubspec.lock` present

## Frameworks

**Core:**
- Flutter 3.x - UI framework for iOS/Android
- GetX - State management and routing (`lib/core/routes/getx_route_module.dart`)
- BLoC (flutter_bloc) - Business logic and state management for complex features

**Backend:**
- Firebase - Cloud infrastructure
  - Cloud Firestore - Database (`firestore.indexes.json`)
  - Firebase Authentication - User management
  - Firebase Cloud Functions - Serverless backend
  - Firebase Messaging - Push notifications
  - Firebase Storage - File storage

**Testing:**
- flutter_test - Widget and unit testing
- mockito - Mock generation
- Not detected: Formal integration/E2E test framework

**Build/Dev:**
- Dart compiler - Code compilation
- Android Studio/Xcode - IDE integration

## Key Dependencies

**Critical:**
- `cloud_firestore` v15.x - Database access
- `firebase_auth` v5.x - Authentication
- `firebase_messaging` v16.0.4 - Push notifications
- `flutter_bloc` v8.x - State management
- `get` v4.x - Routing and service location
- `corbado_auth` - Passkey authentication
- `image_picker` - Media selection
- `geolocator` - Location services
- `file_picker` - File selection

**Infrastructure:**
- `firebase_storage` - Cloud file storage
- `cached_network_image` v3.4.1 - Image caching
- `app_badge_plus` v1.2.2 - App badge notifications
- `flutter_local_notifications` v18.0.1 - Local notifications
- `equatable` - Value equality
- `dartz` - Functional programming (Either/Option types)

**Payment Processing:**
- Flutterwave integration (`functions/services/flutterwave-service.js`)
- Paystack integration (`lib/core/services/paystack_service.dart`)

## Configuration

**Environment:**
- Firebase configuration - `lib/core/config/firebase_config.dart`
- API constants - `lib/core/services/api_service/api_constants.dart`
- `.env` file present (environment variables)
- Constants - `lib/core/constants/app_constants.dart`

**Build:**
- `pubspec.yaml` - Project manifest and dependencies
- `analysis_options.yaml` - Dart linting rules
- Platform-specific configs for Android/iOS

## Platform Requirements

**Development:**
- macOS/Linux/Windows with Flutter SDK 3.x
- Dart 3.x
- Xcode (macOS) for iOS development
- Android SDK for Android development
- Firebase CLI tools

**Production:**
- iOS 11.0+ devices
- Android 5.0+ devices
- Firebase project with Cloud Firestore and Cloud Functions enabled
- Flutterwave and Paystack merchant accounts for payments

---

*Stack analysis: 2026-01-08*
*Update after major dependency changes*
