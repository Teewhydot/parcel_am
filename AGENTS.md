# Agent Development Guide

## Commands

**Setup**: `flutter pub get`  
**Build**: `flutter build apk` (Android) or `flutter build ios` (iOS)  
**Lint**: `flutter analyze`  
**Test**: `flutter test`  
**Dev**: `flutter run`

## Tech Stack

- **Framework**: Flutter (Dart 3.8.1+)
- **Architecture**: Clean Architecture with BLoC pattern
- **State Management**: flutter_bloc, GetX (navigation)
- **DI**: get_it
- **Backend**: Firebase (Auth, Core)
- **Networking**: http, internet_connection_checker
- **Storage**: shared_preferences, flutter_secure_storage

## Project Structure

- `lib/features/`: Feature modules (data/domain/presentation layers)
- `lib/core/`: Shared utilities (bloc_manager, network, routes, theme, widgets)
- `lib/injection_container.dart`: Dependency injection setup
- `test/`: Unit and widget tests

## Code Style

- Follow `flutter_lints` rules (see `analysis_options.yaml`)
- Clean Architecture layers: presentation → domain → data
- Use BLoC for state management, Equatable for value equality
- Repository pattern with local/remote data sources
- Use cases encapsulate business logic
