# Architecture

**Analysis Date:** 2026-01-08

## Pattern Overview

**Overall:** Clean Architecture with Feature-Based Organization + BLoC State Management

**Key Characteristics:**
- Feature-driven modular structure (`lib/features/`)
- Clear separation of concerns (presentation, domain, data layers)
- Centralized service layer for cross-cutting concerns (`lib/core/services/`)
- Firebase as primary backend (Firestore + Cloud Functions)
- BLoC and GetX for state management
- Dependency injection via service locator

## Layers

**Presentation Layer:**
- Purpose: UI rendering and user interaction handling
- Contains: Screens, widgets, BLoC event/state management
- Location: `lib/features/*/presentation/`
- Depends on: Domain layer (use cases), BLoCs
- Used by: Flutter rendering engine

**Domain Layer:**
- Purpose: Business logic and use cases
- Contains: Entities, repositories (interfaces), use cases
- Location: `lib/features/*/domain/`
- Depends on: Nothing (pure Dart, no external dependencies)
- Used by: Data layer, presentation layer

**Data Layer:**
- Purpose: Data access and persistence
- Contains: Models, remote/local data sources, repository implementations
- Location: `lib/features/*/data/`
- Depends on: Domain entities, Firebase/API clients
- Used by: Domain use cases

**Core Layer:**
- Purpose: Shared utilities, services, and configuration
- Contains: Theme, constants, validators, services, error handling
- Location: `lib/core/`
- Depends on: Firebase SDK, third-party packages
- Used by: All features

## Data Flow

**User Action Flow:**
1. User interacts with widget in presentation layer
2. Widget adds event to BLoC (e.g., `ParcelCreateRequested`)
3. BLoC calls corresponding use case from domain layer
4. Use case executes business logic and calls repository
5. Repository (data layer) fetches data from Firestore/API
6. Data flows back up: Model → Entity → Use Case result
7. BLoC emits state (LoadedState, ErrorState, etc.)
8. Presentation layer rebuilds with new state

**Example: Parcel Creation**
- User taps "Create Parcel" → `ParcelCreateRequested` event added
- `ParcelBloc._onCreateRequested()` validates and calls `createParcel` use case
- Use case calls `ParcelRepository.createParcel()`
- Repository creates Firestore transaction with `ParcelRemoteDataSource`
- Response flows back as `ParcelModel` → `ParcelEntity`
- BLoC emits `LoadedState` with updated parcel data
- UI rebuilds showing confirmation

**State Management:**
- BLoC as source of truth for screen state
- Real-time updates via Firestore streams in BLoCs
- Pessimistic updates (wait for server confirmation) for critical operations
- Optimistic updates for UX responsiveness where safe

## Key Abstractions

**BLoC Pattern:**
- Purpose: Centralize business logic and state
- Examples: `ParcelBloc`, `WalletBloc`, `ChatBloc`, `KycBloc`
- Pattern: Event → Handler → State emission
- Location: `lib/features/*/presentation/bloc/`

**Use Cases:**
- Purpose: Encapsulate specific business operations
- Examples: `CreateParcelUseCase`, `CreateEscrowUseCase`, `ReleaseEscrowUseCase`
- Pattern: Immutable with single `call` method
- Location: `lib/features/*/domain/usecases/`

**Repository Pattern:**
- Purpose: Abstract data sources from business logic
- Examples: `ParcelRepository`, `WalletRepository`, `ChatRepository`
- Pattern: Interface in domain, implementation in data
- Location: Interfaces in `*/domain/repositories/`, implementations in `*/data/repositories/`

**Data Source Pattern:**
- Purpose: Encapsulate API/Firestore calls
- Examples: `ParcelRemoteDataSource`, `WalletRemoteDataSource`
- Pattern: Separate remote and local data sources
- Location: `lib/features/*/data/datasources/`

## Entry Points

**App Entry:**
- Location: `lib/main.dart`
- Triggers: App launch
- Responsibilities: Initialize Firebase, setup GetX routing, inject dependencies

**Routing:**
- Location: `lib/core/routes/getx_route_module.dart`
- System: GetX route management with AuthGuard protection
- Protected Routes: Dashboard, Payment, Wallet operations require authentication

**Feature Modules:**
- 10 major features: chat, escrow, file_upload, kyc, notifications, parcel_am_core, passkey, payments, seeder

## Error Handling

**Strategy:** Exception throwing with centralized failure mapping

**Patterns:**
- Services throw exceptions on failures
- Remote data sources catch exceptions and return Failures
- Failures bubble up through repositories to use cases
- BLoCs catch Failures and emit ErrorState
- Presentation layer shows error snackbars/dialogs

**Error Types:**
- `FirebaseFailureMapper` - Firebase error mapping
- `FailureMapper` - General failure mapping
- `Failure` domain entities with failure messages

## Cross-Cutting Concerns

**Authentication:**
- Corbado passkey authentication for security
- Firebase Auth integration
- `AuthGuard` middleware on protected routes

**Validation:**
- Form validators in `lib/core/utils/form_validators.dart`
- Entity validators in domain layer
- Input sanitization at presentation boundaries

**Logging:**
- Logger instance: `lib/core/utils/logger.dart`
- Structured logging for debugging
- Firebase Cloud Functions logging on backend

**Notifications:**
- Firebase Messaging for push notifications
- Local notifications via `flutter_local_notifications`
- Notification routing through `NotificationService`

---

*Architecture analysis: 2026-01-08*
*Update when major patterns change*
