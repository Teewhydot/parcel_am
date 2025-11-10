# Agent Guide

## Commands

**Setup:** `flutter pub get`  
**Build:** `flutter build apk` (Android) or `flutter build ios` (iOS)  
**Lint:** `flutter analyze`  
**Test:** `flutter test`  
**Dev:** `flutter run` (requires connected device/emulator)

## Tech Stack

- **Framework:** Flutter (Dart)
- **Architecture:** Clean Architecture with BLoC pattern
- **State Management:** flutter_bloc, provider, GetX
- **Backend:** Firebase (Auth, Core, App Check)
- **Storage:** shared_preferences, flutter_secure_storage
- **DI:** get_it

## Structure

- `lib/features/` - Feature modules with data/domain/presentation layers
- `lib/core/` - Shared utilities (bloc, network, errors, widgets, routes, config)
- `test/` - Unit and widget tests

## Code Style

- Follow `analysis_options.yaml` (uses `package:flutter_lints/flutter.yaml`)
- Clean Architecture: separate data, domain, and presentation layers
- Use BLoC for state management with Equatable for value equality
