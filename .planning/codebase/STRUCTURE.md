# Codebase Structure

**Analysis Date:** 2026-01-08

## Directory Layout

```
parcel_am/
├── lib/                              # Dart application source
│   ├── main.dart                    # App entry point
│   ├── app/                         # App-level configuration
│   │   └── init.dart               # Firebase & dependency initialization
│   ├── core/                        # Shared code across features
│   │   ├── bloc/                   # Base BLoC classes and factories
│   │   ├── config/                 # Firebase configuration
│   │   ├── constants/              # App constants
│   │   ├── data/                   # Core data layer (repositories)
│   │   ├── domain/                 # Core domain entities
│   │   ├── enums/                  # Shared enumerations
│   │   ├── errors/                 # Error handling and mapping
│   │   ├── helpers/                # Utility helpers
│   │   ├── routes/                 # GetX routing configuration
│   │   ├── services/               # Core services (Firebase, API, etc.)
│   │   ├── theme/                  # App theme (colors, fonts, radius)
│   │   ├── utils/                  # Utility functions
│   │   └── widgets/                # Reusable UI components
│   └── features/                    # Feature modules
│       ├── chat/                    # Real-time chat feature
│       ├── escrow/                  # Escrow payment management
│       ├── file_upload/             # File upload functionality
│       ├── kyc/                     # KYC verification
│       ├── notifications/           # Push notification handling
│       ├── parcel_am_core/          # Main parcel delivery logic
│       ├── passkey/                 # Passkey authentication
│       ├── payments/                # Payment processing
│       └── seeder/                  # Database seeding utilities
├── test/                            # Test files
│   ├── core/                        # Core layer tests
│   ├── features/                    # Feature tests
│   └── data/                        # Test fixtures and helpers
├── functions/                       # Firebase Cloud Functions
│   ├── services/                    # Payment and backend services
│   ├── lib/                         # Shared functions code
│   └── index.js                     # Functions entry point
├── pubspec.yaml                     # Dart dependencies
├── pubspec.lock                     # Locked dependency versions
├── analysis_options.yaml            # Linting configuration
├── firebase.indexes.json            # Firestore indexes
├── .env                             # Environment variables
└── .gitignore                       # Git ignore rules
```

## Directory Purposes

**lib/app/**
- Purpose: Application initialization and setup
- Key files: `init.dart` - Initializes Firebase, GetX routing, dependency injection

**lib/core/bloc/**
- Purpose: Base BLoC classes and mixins for state management
- Contains: `BaseBloC`, `BaseState`, `PaginationBlocMixin`, `RefreshableBlocMixin`
- Key files: `base_bloc.dart`, `base_state.dart`, factory patterns

**lib/core/services/**
- Purpose: Application-wide services (Firebase, payments, notifications, etc.)
- Key services: `PaystackService`, `FileUploadService`, `NotificationService`, `ConnectivityService`
- Authentication: `AuthGuard`, `KycGuard` for route protection

**lib/core/theme/**
- Purpose: Centralized UI design tokens
- Files: `app_colors.dart`, `app_font_size.dart`, `app_radius.dart`, `app_theme.dart`

**lib/features/parcel_am_core/**
- Purpose: Main parcel delivery/request logic
- Contains: Parcel creation, status tracking, wallet management
- Key screens: Dashboard, BrowseRequests, CreateParcel, TrackingScreen, PaymentScreen

**lib/features/chat/**
- Purpose: Real-time messaging between users
- Pattern: Data source → Repository → Use cases → BLoC → UI
- Key entities: Chat, Message, Presence

**lib/features/escrow/**
- Purpose: Secure payment holding during delivery
- Key operations: CreateEscrow, HoldFunds, ReleaseFunds, CancelEscrow

**lib/features/kyc/**
- Purpose: User identity verification and compliance
- Key screens: VerificationScreen, KycBlockedScreen
- Status tracking: pending, approved, rejected, blocked

**lib/features/payments/**
- Purpose: Payment processing and wallet transactions
- Integration: Flutterwave, Paystack, local wallet
- BLoCs: PaystackPaymentBloc for payment flow

**test/**
- Purpose: Unit, widget, and integration tests
- Patterns: Mockito for mocking, flutter_test framework
- Coverage: Wallet management, notifications, widgets, data models

**functions/** (Firebase Cloud Functions)
- Purpose: Backend services and webhooks
- Key services: `flutterwave-service.js` for payment processing
- Configuration: Environment variables for API keys

## Key File Locations

**Entry Points:**
- `lib/main.dart` - App startup
- `lib/app/init.dart` - Initialization logic
- `lib/core/routes/getx_route_module.dart` - Route definitions

**Configuration:**
- `pubspec.yaml` - Dependencies and project metadata
- `.env` - Environment variables
- `analysis_options.yaml` - Dart linting rules
- `firebase.indexes.json` - Firestore database indexes
- `lib/core/config/firebase_config.dart` - Firebase setup

**Core Logic:**
- `lib/core/services/` - All core services
- `lib/core/theme/` - Design tokens
- `lib/core/bloc/` - Base BLoC infrastructure
- `lib/core/utils/validators.dart` - Input validation

**Testing:**
- `test/` - All test files
- Pattern: Test files mirror source structure
- Example: `test/features/parcel_am_core/` mirrors `lib/features/parcel_am_core/`

## Naming Conventions

**Files:**
- `snake_case.dart` for all Dart files (e.g., `parcel_bloc.dart`, `create_parcel_screen.dart`)
- `_event.dart`, `_state.dart`, `_bloc.dart` for BLoC-related files
- `_model.dart` for data layer models
- `_entity.dart` for domain entities
- `_repository.dart` for repository interfaces
- `_repository_impl.dart` for repository implementations
- `_usecase.dart` for use case classes
- `_test.dart` for test files

**Classes:**
- `PascalCase` for all class names
- `PascalCase` for enum names (values in `UPPER_CASE`)
- `camelCase` for methods and properties

**Directories:**
- `snake_case` for all directory names
- Plural names for collections: `screens/`, `widgets/`, `services/`, `models/`
- Feature names lowercase: `parcel_am_core/`, `kyc/`, `payments/`

**Special Patterns:**
- `*_event.dart` + `*_state.dart` + `*_bloc.dart` = BLoC triplet
- `*_data.dart` for BLoC data models/view models
- `index.dart` or exports in feature root for barrel exports (if used)

## Where to Add New Code

**New Feature:**
- Create `lib/features/{feature_name}/` directory
- Subdirectories: `presentation/`, `domain/`, `data/`
- Tests: Mirror in `test/features/{feature_name}/`

**New Screen/Widget:**
- Location: `lib/features/{feature}/presentation/screens/` or `widgets/`
- Naming: `{feature}_screen.dart` or `{component}_widget.dart`
- Should use BLoC for state management

**New BLoC:**
- Location: `lib/features/{feature}/presentation/bloc/`
- Files: `{feature}_event.dart`, `{feature}_state.dart`, `{feature}_bloc.dart`
- Data model: `{feature}_data.dart` (optional, for complex state)

**New Use Case:**
- Location: `lib/features/{feature}/domain/usecases/`
- File: `{operation}_usecase.dart`
- Extends `UseCase<Output, Params>` from `lib/core/usecases/`

**New Repository:**
- Location: `lib/features/{feature}/data/repositories/`
- Files: Interface in `domain/repositories/`, implementation in `data/repositories/`
- Pattern: Implement domain repository interface

**New Service:**
- Location: `lib/core/services/` (if core) or `lib/features/{feature}/data/datasources/`
- Naming: `{service}_service.dart` or `{entity}_remote_data_source.dart`

**Unit Tests:**
- Location: Mirror `lib/` structure under `test/`
- File: `{source}_test.dart`
- Use mockito for dependencies

## Special Directories

**lib/core/bloc/mixins/**
- Purpose: BLoC behavior mixins for common patterns
- Files: `CacheableBlocMixin`, `PaginationBlocMixin`, `RefreshableBlocMixin`

**lib/core/helpers/**
- Purpose: Pure utility functions and helpers
- Examples: `haptic_helper.dart`, `user_extensions.dart`

**test/data/**
- Purpose: Shared test fixtures and mock data
- File: `parcel_seeder.dart` for generating test parcels

**functions/**
- Purpose: Firebase Cloud Functions backend
- Note: JavaScript-based, separate from Flutter codebase
- Key: `index.js` entry point, services directory

---

*Structure analysis: 2026-01-08*
*Update when directory structure changes*
