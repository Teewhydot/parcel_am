# Agent Commands

## Setup
```bash
flutter pub get
```

## Build
```bash
flutter build apk           # Android
flutter build ios           # iOS
flutter build web           # Web
```

## Lint/Test/Dev
```bash
flutter analyze             # Lint
flutter test                # Run tests
flutter run                 # Run on connected device/emulator
```

## Tech Stack
Flutter 3.8.1+ with Clean Architecture + BLoC pattern. DI via GetIt. Navigation via GetX. Firebase backend (Auth, Core). Storage: SharedPreferences + flutter_secure_storage.

## Structure
- `lib/features/`: Feature modules with data/domain/presentation layers
- `lib/core/`: Shared code (network, services, widgets, theme, routes, utils)
- `lib/injection_container.dart`: DI setup

## Conventions
- Clean Architecture: features → data/domain/presentation
- BLoC for state management with Equatable for value equality
- Register all dependencies in `injection_container.dart`
- Follow `flutter_lints` rules per `analysis_options.yaml`
