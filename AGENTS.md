# Agent Development Guide

## Commands

**Setup:**
```bash
flutter pub get
```

**Build:** `flutter build apk` (or `ios`, `web`, etc.)

**Lint:** `flutter analyze`

**Test:** `flutter test`

**Dev Server:** `flutter run` (requires emulator/device)

## Tech Stack & Architecture

- **Framework:** Flutter 3.8.1+ with Dart
- **Architecture:** Clean Architecture with BLoC pattern
- **State Management:** flutter_bloc, provider, get_it (DI)
- **Backend:** Firebase (Auth, Core), HTTP client
- **Storage:** shared_preferences, flutter_secure_storage
- **Key Libraries:** geolocator, image_picker, permission_handler, intl_phone_field

**Structure:** `lib/features/{feature}/` with `data/`, `domain/`, `presentation/` layers. Core utilities in `lib/core/`.

## Code Style

- Follow `flutter_lints` rules (enforced via `analysis_options.yaml`)
- Use Clean Architecture: separate domain, data, and presentation layers
- BLoC for state management, GetIt for dependency injection
- Register dependencies in `injection_container.dart`
