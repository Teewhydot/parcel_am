# Tech Stack

Define your technical stack below. This serves as a reference for all team members and helps maintain consistency across the project.

## Framework & Runtime
- **Framework:** Flutter
- **Language:** Dart
- **Package Manager:** pub (flutter pub)
- **Minimum Flutter Version:** [e.g., 3.10.0 or latest stable]
- **Minimum Dart Version:** [e.g., 3.0.0 or as required by Flutter]

## State Management
- **Primary Solution:** [e.g., BLoC/Cubit, Riverpod, Provider, GetX]
- **Package:** [e.g., flutter_bloc: ^8.1.0]
- **Pattern:** [e.g., Feature-based BLoCs, Repository pattern]

## Backend & Database
- **Backend Service:** Firebase
- **Authentication:** Firebase Authentication
- **Database:** Cloud Firestore
- **Storage:** Firebase Storage
- **Cloud Functions:** Firebase Cloud Functions (Node.js/TypeScript)
- **Hosting:** [Firebase Hosting if applicable]

## Navigation & Routing
- **Router:** [e.g., GoRouter, AutoRoute, Navigator 2.0, built-in Navigator]
- **Package:** [e.g., go_router: ^13.0.0]
- **Deep Linking:** [Enabled/Disabled]

## UI & Design
- **Design System:** [e.g., Material Design 3, Cupertino, Custom]
- **Theme Management:** [e.g., ThemeData with light/dark modes]
- **Icons:** [e.g., Material Icons, Cupertino Icons, custom icon font]
- **UI Component Library:** [e.g., None, custom widgets]

## Networking & API
- **HTTP Client:** [e.g., http, dio]
- **Serialization:** [e.g., json_serializable, Freezed, manual]
- **Code Generation:** [build_runner for json_serializable/Freezed]

## Local Storage & Caching
- **Key-Value Storage:** [e.g., shared_preferences]
- **Local Database:** [e.g., None, sqflite, hive, isar]
- **Secure Storage:** [e.g., flutter_secure_storage]
- **Image Caching:** [e.g., cached_network_image]

## Testing
- **Unit Testing:** Built-in Flutter test framework
- **Widget Testing:** Built-in Flutter test framework
- **Integration Testing:** integration_test package
- **Mocking:** [e.g., mockito, mocktail]
- **BLoC Testing:** [e.g., bloc_test]

## Code Quality & Formatting
- **Linting:** flutter_lints or custom analysis_options.yaml
- **Formatting:** dart format
- **Static Analysis:** flutter analyze
- **Pre-commit Hooks:** [e.g., None, husky, custom scripts]

## CI/CD & Deployment
- **CI/CD Platform:** [e.g., GitHub Actions, Codemagic, Bitrise, Firebase App Distribution]
- **App Distribution:** [Google Play Store, Apple App Store, Firebase App Distribution]
- **Build Variants:** [e.g., dev, staging, production]
- **Fastlane:** [Yes/No for automating iOS/Android builds]

## Monitoring & Analytics
- **Crash Reporting:** [e.g., Firebase Crashlytics]
- **Analytics:** [e.g., Firebase Analytics, Google Analytics]
- **Performance Monitoring:** [e.g., Firebase Performance Monitoring]
- **Error Tracking:** [e.g., Sentry, Firebase Crashlytics]

## Development Tools
- **IDE:** [e.g., VS Code, Android Studio, IntelliJ IDEA]
- **Version Control:** Git
- **Emulators:** [Android Emulator, iOS Simulator]
- **Firebase Tools:** Firebase CLI, FlutterFire CLI
- **Design Tools:** [e.g., Figma, Adobe XD]

## Third-Party Packages
List key packages used in the project:
- **State Management:** [e.g., flutter_bloc: ^8.1.0]
- **Firebase:** [e.g., firebase_core, cloud_firestore, firebase_auth, firebase_storage]
- **UI:** [e.g., cached_network_image, flutter_svg, shimmer]
- **Utilities:** [e.g., intl for internationalization, url_launcher]
- **Forms:** [e.g., None or reactive_forms, flutter_form_builder]
- **Image Handling:** [e.g., image_picker, image_cropper]
- **Permissions:** [e.g., permission_handler]
- **Other:** [List additional key packages]

## Platform Support
- **Android:** Minimum SDK [e.g., 21 (Android 5.0)]
- **iOS:** Minimum iOS [e.g., 12.0]
- **Web:** [Supported/Not Supported]
- **Desktop:** [Windows/macOS/Linux - Supported/Not Supported]

## Environment Variables & Configuration
- **Build Flavors:** [e.g., dev, staging, production]
- **Configuration Method:** [e.g., --dart-define, .env files, firebase_options.dart]
- **Secrets Management:** [Firebase config files, environment variables]
