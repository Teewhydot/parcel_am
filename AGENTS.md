# Agent Instructions

## Commands

**Initial Setup:**
```bash
flutter pub get
```

**Build:**
```bash
flutter build apk  # Android
flutter build ios  # iOS
```

**Lint:**
```bash
flutter analyze
```

**Tests:**
```bash
flutter test
```

**Dev Server:**
```bash
flutter run
```

## Tech Stack & Architecture

- **Framework:** Flutter 3.8.1+ with Dart
- **Architecture:** Clean Architecture with BLoC pattern
- **State Management:** flutter_bloc, provider
- **Dependency Injection:** get_it
- **Backend:** Firebase (Auth, Core, App Check)
- **Network:** http, internet_connection_checker
- **Storage:** shared_preferences, flutter_secure_storage

**Structure:** `lib/features/{feature}/` with `data/`, `domain/`, `presentation/` layers. Core utilities in `lib/core/`.

## Code Style

- Follow `flutter_lints` rules (see `analysis_options.yaml`)
- Use Clean Architecture: Entities, Use Cases, Repositories pattern
- BLoC for state management with events/states
- Dependency injection via `injection_container.dart`
- No print statements in production (use proper logging)
