# Agent Setup Guide

## Commands

**Setup**: `flutter pub get`

**Build**: `flutter build apk` (Android) or `flutter build ios` (iOS)

**Lint**: `flutter analyze`

**Test**: `flutter test`

**Dev Server**: `flutter run`

## Tech Stack & Architecture

- **Framework**: Flutter/Dart with Firebase (Auth, Core)
- **Architecture**: Clean Architecture with BLoC pattern
- **State Management**: flutter_bloc + provider + get_it (DI)
- **Layers**: `features/{feature}/` → `data/`, `domain/`, `presentation/` (with `bloc/`)
- **Core**: Shared utilities in `lib/core/` (network, services, theme, widgets, bloc_manager)

## Code Style

- Follow `analysis_options.yaml` (uses `package:flutter_lints/flutter.yaml`)
- Use BLoC for state management with Equatable for state classes
- Repository pattern with remote/local data sources
- Abstract use cases extending `UseCase<Type, Params>`
- Dependency injection via get_it in `injection_container.dart`
