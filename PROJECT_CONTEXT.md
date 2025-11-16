# ParcelAm - Project Context Guide

## Project Overview

**ParcelAm** is a comprehensive Flutter application built with Clean Architecture and BLoC state management pattern. The app serves as a parcel delivery and travel linking platform with real-time chat, escrow services, KYC verification, and notification systems.

### Key Features
- **Authentication & User Management**: Firebase-based auth with KYC verification
- **Real-time Chat**: Multi-user chat with presence indicators and typing status
- **Escrow System**: Secure payment handling for parcel delivery
- **Package Management**: Track parcels, create disputes, confirm delivery
- **Notifications**: Push and local notifications with Firebase integration
- **Wallet System**: Digital wallet for transactions
- **TravelLink**: Connect travelers with parcel senders

## Architecture

### Clean Architecture Implementation
```
lib/
├── core/                    # Shared utilities, services, and base classes
├── features/               # Feature modules (independent, self-contained)
│   ├── chat/              # Real-time chat functionality
│   ├── escrow/            # Payment escrow system
│   ├── kyc/               # KYC verification (standalone)
│   ├── notifications/     # Push/local notifications
│   ├── package/           # Package tracking and management
│   └── travellink/        # Main business logic (auth, wallet, parcels)
├── app/                   # App-level configuration and providers
└── main.dart             # App entry point
```

### Feature Module Structure
Each feature follows Clean Architecture:
```
feature/
├── data/                  # Data layer
│   ├── datasources/      # Remote/local data sources
│   ├── models/           # Data transfer objects
│   └── repositories/     # Repository implementations
├── domain/               # Business logic layer
│   ├── entities/         # Business objects
│   ├── repositories/     # Repository interfaces
│   ├── usecases/         # Business use cases
│   └── failures/         # Error handling
└── presentation/         # UI layer
    ├── bloc/            # BLoC state management
    ├── screens/         # UI screens
    └── widgets/         # Reusable UI components
```

## Technology Stack

### Core Dependencies
- **Flutter**: ^3.8.1 (UI framework)
- **Dart**: ^3.8.1 (programming language)

### State Management & Architecture
- **flutter_bloc**: ^8.1.6 (BLoC pattern implementation)
- **bloc**: ^8.1.4 (core BLoC library)
- **get_it**: ^9.0.5 (dependency injection)
- **provider**: ^6.1.2 (state management provider)

### Backend & Storage
- **Firebase Core**: ^4.2.1 (Firebase initialization)
- **Firebase Auth**: ^6.1.2 (authentication)
- **Cloud Firestore**: ^6.1.0 (NoSQL database)
- **Firebase Storage**: ^13.0.4 (file storage)
- **Firebase Messaging**: ^16.0.4 (push notifications)

### Network & Utilities
- **http**: ^1.6.0 (HTTP client)
- **internet_connection_checker**: ^3.0.1 (network connectivity)
- **shared_preferences**: ^2.3.2 (local storage)
- **flutter_secure_storage**: ^9.2.2 (secure storage)

### UI & UX
- **flutter_screenutil**: ^5.9.3 (responsive design)
- **flutter_svg**: ^2.2.2 (SVG support)
- **cached_network_image**: ^3.4.1 (image caching)
- **skeletonizer**: ^2.1.0+1 (loading skeletons)
- **flutter_slidable**: ^3.1.1 (swipe actions)

### Location & Permissions
- **geolocator**: ^14.0.2 (location services)
- **geocoding**: ^4.0.0 (geocoding)
- **permission_handler**: ^12.0.1 (permissions)

## Development Standards

### Code Style (from `agent-os/standards/global/coding-style.md`)

#### Naming Conventions
- **Classes/Enums/Extensions**: UpperCamelCase (`UserModel`, `AuthState`)
- **Files/Directories**: lowercase_with_underscores (`user_repository.dart`)
- **Variables/Functions**: lowerCamelCase (`userName`, `fetchUserData`)
- **Constants**: lowerCamelCase (`maxRetryCount`) - NOT UPPER_SNAKE_CASE
- **Private members**: Prefix with underscore (`_privateMethod`)

#### Code Organization
- Use 2-space indentation (Dart standard)
- Order imports: Dart libraries → Flutter → packages → relative
- Group related code with blank lines
- Order class members: fields → constructors → methods (public then private)

#### Best Practices
- Keep functions small (ideally <20 lines, max 50 lines)
- One function = one responsibility
- Use `final` for immutable variables
- Use `const` for compile-time constants
- Prefer `async/await` over raw Futures
- Mark widget properties as `final`
- Use `const` constructors for widgets when possible

#### Architecture Guidelines
- Follow Clean Architecture strictly
- Use BLoC for state management
- Implement proper error handling with Either<Failure, T>
- Create reusable widgets (no hardcoded Flutter widgets)
- Remove dead code immediately (don't comment out)

## State Management

### Base BLoC Architecture
All BLoCs extend `BaseBloC<Event, State>` which provides:
- Automatic logging of state transitions
- Common error handling
- Loading/success/error state management
- Exception handling utilities

### State Types
```dart
// Base states from lib/core/bloc/base/base_state.dart
InitialState<T>()     // Initial state
LoadingState<T>()     // Loading with optional message/progress
LoadedState<T>()      // Data loaded successfully
SuccessState<T>()     // Action completed successfully
ErrorState<T>()       // Error occurred
```

### AuthBloc Example
The `AuthBloc` handles:
- User authentication (login/register/logout)
- Profile management
- KYC status updates
- Password reset
- Real-time user state

## Key Features Implementation

### 1. Authentication System
- **Firebase Auth** integration
- **Email/Password** authentication
- **KYC Verification** workflow
- **Session Management** with secure storage
- **Profile Updates** with validation

### 2. Real-time Chat
- **ChatBloc**: Manages user's chat list with auto-updates
- **MessageBloc**: Per-chat message streams with automatic cleanup
- **PresenceBloc**: Online status and typing indicators
- **Stream Management**: Proper subscription cleanup on disposal

### 3. Escrow System
- **Secure Payment Holding**: Funds held until delivery confirmation
- **Multi-party Transactions**: Sender, traveler, and platform involvement
- **Dispute Resolution**: Handle delivery disputes
- **Status Tracking**: Real-time escrow status updates

### 4. KYC Verification
- **Document Upload**: ID verification with image picker
- **Status Tracking**: pending, verified, rejected states
- **Firebase Storage**: Secure document storage
- **Admin Review**: Workflow for verification approval

### 5. Notification System
- **Push Notifications**: Firebase Cloud Messaging
- **Local Notifications**: Flutter local notifications
- **Background Handling**: Background message handlers
- **Notification Service**: Centralized notification management

## Data Flow Patterns

### Repository Pattern
```dart
// Domain layer - Interface
abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
}

// Data layer - Implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  
  @override
  Future<Either<Failure, User>> login(String email, String password) {
    // Implementation with error handling
  }
}
```

### Use Case Pattern
```dart
class LoginUseCase implements UseCase<User, LoginParams> {
  final AuthRepository repository;
  
  @override
  Future<Either<Failure, User>> call(LoginParams params) {
    return repository.login(params.email, params.password);
  }
}
```

### BLoC Event Handling
```dart
on<AuthLoginRequested>((event, emit) async {
  emit(const LoadingState<AuthData>(message: 'Logging in...'));
  
  final result = await authUseCase.login(event.email, event.password);
  
  result.fold(
    (failure) => emit(ErrorState<AuthData>(errorMessage: failure.message)),
    (user) => emit(LoadedState<AuthData>(data: AuthData(user: user))),
  );
});
```

## Firebase Integration

### Services Configuration
- **Firebase Auth**: User authentication and management
- **Cloud Firestore**: Real-time database for chats, users, transactions
- **Firebase Storage**: File storage for KYC documents and images
- **Firebase Messaging**: Push notifications

### Security Rules
- Firestore rules defined in `firestore.rules`
- User-based access control
- Document-level security for sensitive data

## Development Workflow

### Setup Commands
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Build for production
flutter build apk    # Android
flutter build ios    # iOS

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Testing Strategy
- **Unit Tests**: Use cases, repositories, BLoCs
- **Widget Tests**: UI components and screens
- **Integration Tests**: End-to-end user flows
- **Mock Dependencies**: Use mockito for testing

### Code Quality
- **flutter_lints**: Enforced coding standards
- **analysis_options.yaml**: Linting configuration
- **Pre-commit hooks**: Automated formatting and analysis

## Key Files to Understand

### Core Configuration
- `pubspec.yaml` - Dependencies and project configuration
- `lib/main.dart` - App entry point and initialization
- `lib/injection_container.dart` - Dependency injection setup
- `firebase_options.dart` - Firebase configuration

### Core Architecture
- `lib/core/bloc/base/` - Base BLoC and state classes
- `lib/core/services/` - Shared services (notifications, auth, etc.)
- `lib/core/widgets/` - Reusable UI components
- `lib/core/utils/` - Utility functions and helpers

### Feature Modules
- `lib/features/travellink/` - Main business logic
- `lib/features/chat/` - Real-time chat implementation
- `lib/features/escrow/` - Payment escrow system
- `lib/features/kyc/` - KYC verification
- `lib/features/notifications/` - Notification system

### Documentation
- `README.md` - Project overview and chat feature details
- `agent-os/standards/` - Development standards and guidelines
- Various `.md` files for specific features and implementations

## Common Patterns

### Error Handling
```dart
final result = await useCase(params);
result.fold(
  (failure) => emit(ErrorState(errorMessage: failure.message)),
  (success) => emit(LoadedState(data: success)),
);
```

### Navigation
```dart
// Using GetX for navigation
Get.toNamed(Routes.chatScreen, arguments: chatId);
Get.offAllNamed(Routes.home); // Clear stack
```

### Dependency Injection
```dart
// Register in injection_container.dart
sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
sl.registerFactory<AuthBloc>(() => AuthBloc());

// Use in widgets
final authBloc = BlocProvider.of<AuthBloc>(context);
// or via dependency injection
final authBloc = sl<AuthBloc>();
```

## Development Tips

1. **Always extend BaseBloC** for consistency
2. **Use Either<Failure, T>** for error handling
3. **Implement proper stream cleanup** in BLoC dispose methods
4. **Follow the file naming conventions** strictly
5. **Use const constructors** for widgets when possible
6. **Remove unused imports** before committing
7. **Run flutter analyze** to catch issues early
8. **Write tests for business logic** (use cases, repositories)
9. **Use semantic HTML** for web accessibility
10. **Implement proper error states** in UI

This context guide should help you understand the project structure, patterns, and conventions used throughout the ParcelAm application.

---

# Development Rules & Conventions

## Adding New Features

### 1. Feature Structure Requirements
When adding a new feature, follow this exact structure:

```
lib/features/feature_name/
├── data/
│   ├── datasources/
│   │   ├── feature_remote_data_source.dart
│   │   └── feature_local_data_source.dart (if needed)
│   ├── models/
│   │   └── feature_model.dart
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart
│   ├── repositories/
│   │   └── feature_repository.dart
│   ├── usecases/
│   │   ├── feature_usecase.dart
│   │   └── specific_usecase.dart
│   └── failures/
│       └── feature_failures.dart
└── presentation/
    ├── bloc/
    │   ├── feature_bloc.dart
    │   ├── feature_event.dart
    │   └── feature_state.dart
    ├── screens/
    │   └── feature_screen.dart
    └── widgets/
        └── feature_widget.dart
```

### 2. Mandatory Implementation Steps

#### Step 1: Domain Layer First
```dart
// 1. Create Entity
class FeatureEntity extends Equatable {
  final String id;
  final String name;
  
  const FeatureEntity({required this.id, required this.name});
  
  @override
  List<Object> get props => [id, name];
}

// 2. Create Repository Interface
abstract class FeatureRepository {
  Future<Either<Failure, List<FeatureEntity>>> getFeatures();
  Future<Either<Failure, FeatureEntity>> getFeature(String id);
  Stream<List<FeatureEntity>> watchFeatures();
}

// 3. Create Use Cases
class GetFeaturesUseCase implements UseCase<List<FeatureEntity>, NoParams> {
  final FeatureRepository repository;
  
  GetFeaturesUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<FeatureEntity>>> call(NoParams params) {
    return repository.getFeatures();
  }
}
```

#### Step 2: Data Layer Implementation
```dart
// 1. Create Model (with from/toJson)
class FeatureModel extends FeatureEntity {
  const FeatureModel({required super.id, required super.name});
  
  factory FeatureModel.fromJson(Map<String, dynamic> json) {
    return FeatureModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

// 2. Create Data Source
abstract class FeatureRemoteDataSource {
  Future<List<FeatureModel>> getFeatures();
  Future<FeatureModel> getFeature(String id);
  Stream<List<FeatureModel>> watchFeatures();
}

class FeatureRemoteDataSourceImpl implements FeatureRemoteDataSource {
  final FirebaseFirestore firestore;
  
  FeatureRemoteDataSourceImpl(this.firestore);
  
  @override
  Future<List<FeatureModel>> getFeatures() async {
    // Implementation
  }
}

// 3. Create Repository Implementation
class FeatureRepositoryImpl implements FeatureRepository {
  final FeatureRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  
  FeatureRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });
  
  @override
  Future<Either<Failure, List<FeatureEntity>>> getFeatures() async {
    if (await networkInfo.isConnected) {
      try {
        final features = await remoteDataSource.getFeatures();
        return Right(features);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }
}
```

#### Step 3: Presentation Layer
```dart
// 1. Create BLoC Events
abstract class FeatureEvent extends Equatable {
  const FeatureEvent();
}

class FeatureLoadRequested extends FeatureEvent {
  const FeatureLoadRequested();
  
  @override
  List<Object> get props => [];
}

// 2. Create BLoC State
class FeatureState extends Equatable {
  const FeatureState({
    this.status = FeatureStatus.initial,
    this.features = const [],
    this.errorMessage,
  });
  
  final FeatureStatus status;
  final List<FeatureEntity> features;
  final String? errorMessage;
  
  FeatureState copyWith({
    FeatureStatus? status,
    List<FeatureEntity>? features,
    String? errorMessage,
  }) {
    return FeatureState(
      status: status ?? this.status,
      features: features ?? this.features,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [status, features, errorMessage];
}

// 3. Create BLoC
class FeatureBloc extends BaseBloC<FeatureEvent, FeatureState> {
  final GetFeaturesUseCase getFeaturesUseCase;
  
  FeatureBloc({required this.getFeaturesUseCase}) 
    : super(const FeatureState()) {
    
    on<FeatureLoadRequested>(_onFeatureLoadRequested);
  }
  
  Future<void> _onFeatureLoadRequested(
    FeatureLoadRequested event,
    Emitter<FeatureState> emit,
  ) async {
    emit(state.copyWith(status: FeatureStatus.loading));
    
    final result = await getFeaturesUseCase(NoParams());
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: FeatureStatus.error,
        errorMessage: failure.failureMessage,
      )),
      (features) => emit(state.copyWith(
        status: FeatureStatus.loaded,
        features: features,
      )),
    );
  }
}
```

### 3. Dependency Injection Registration
Update `lib/injection_container.dart`:

```dart
//! Features - Feature Data Sources
sl.registerLazySingleton<FeatureRemoteDataSource>(() => FeatureRemoteDataSourceImpl(
  firestore: sl(),
));

//! Features - Feature Repository
sl.registerLazySingleton<FeatureRepository>(() => FeatureRepositoryImpl(
  remoteDataSource: sl(),
  networkInfo: sl(),
));

//! Features - Feature Use Cases
sl.registerLazySingleton<GetFeaturesUseCase>(() => GetFeaturesUseCase(
  repository: sl(),
));

//! Features - Feature BLoC
sl.registerFactory<FeatureBloc>(() => FeatureBloc(
  getFeaturesUseCase: sl(),
));
```

## Code Quality Rules

### 1. Mandatory Code Review Checklist
- [ ] All classes extend appropriate base classes (BaseBloC, BaseState)
- [ ] All entities extend Equatable
- [ ] All use cases implement UseCase interface
- [ ] All repositories use Either<Failure, T> return type
- [ ] All async operations have proper error handling
- [ ] All streams are properly disposed in close() methods
- [ ] All widget properties are marked as final
- [ ] All const constructors are used where possible
- [ ] No unused imports (flutter analyze must pass)
- [ ] Proper documentation for public APIs

### 2. Firebase Integration Rules
```dart
// ALWAYS use proper error handling
try {
  final result = await firestore.collection('users').doc(userId).get();
  if (result.exists) {
    return Right(UserModel.fromJson(result.data()!));
  } else {
    return Left(const UserNotFoundFailure());
  }
} on FirebaseException catch (e) {
  return Left(ServerFailure(message: e.message));
}

// ALWAYS use secure storage for sensitive data
final secureStorage = sl<FlutterSecureStorage>();
await secureStorage.write(key: 'auth_token', value: token);

// ALWAYS validate user permissions
if (currentUser?.uid != document.userId) {
  return Left(const PermissionDeniedFailure());
}
```

### 3. State Management Rules
```dart
// ALWAYS emit loading state before async operations
emit(state.copyWith(status: FeatureStatus.loading));

// ALWAYS handle Both success and error cases
result.fold(
  (failure) => emit(state.copyWith(
    status: FeatureStatus.error,
    errorMessage: failure.failureMessage,
  )),
  (success) => emit(state.copyWith(
    status: FeatureStatus.loaded,
    data: success,
  )),
);

// NEVER call emit() after dispose()
bool _isDisposed = false;

@override
Future<void> close() async {
  _isDisposed = true;
  await streamSubscription?.cancel();
  super.close();
}

void _safeEmit(State newState) {
  if (!_isDisposed) {
    emit(newState);
  }
}
```

### 4. UI Development Rules
```dart
// ALWAYS use const constructors for static widgets
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

// ALWAYS abstract commonly used widgets
class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  
  const AppText(this.text, {super.key, this.style});
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}

// NEVER use hardcoded values
const double defaultPadding = 16.0;
const BorderRadius defaultBorderRadius = BorderRadius.circular(8.0);
```

## Testing Requirements

### 1. Unit Tests (Mandatory)
```dart
// Test Use Cases
class GetFeaturesUseCaseTest {
  late GetFeaturesUseCase useCase;
  late MockFeatureRepository mockRepository;
  
  setUp(() {
    mockRepository = MockFeatureRepository();
    useCase = GetFeaturesUseCase(mockRepository);
  }
  
  test('should get features from repository', () async {
    // Arrange
    final testFeatures = [FeatureEntity(id: '1', name: 'Test')];
    when(mockRepository.getFeatures())
        .thenAnswer((_) async => Right(testFeatures));
    
    // Act
    final result = await useCase(NoParams());
    
    // Assert
    expect(result, Right(testFeatures));
    verify(mockRepository.getFeatures());
  });
}

// Test BLoCs
class FeatureBlocTest {
  late FeatureBloc bloc;
  late MockGetFeaturesUseCase mockUseCase;
  
  setUp(() {
    mockUseCase = MockGetFeaturesUseCase();
    bloc = FeatureBloc(getFeaturesUseCase: mockUseCase);
  }
  
  blocTest<FeatureBloc, FeatureState>(
    'emits [loading, loaded] when FeatureLoadRequested is added',
    build: () {
      when(mockUseCase(any))
          .thenAnswer((_) async => Right([]));
      return bloc;
    },
    act: (bloc) => bloc.add(const FeatureLoadRequested()),
    expect: () => [
      const FeatureState(status: FeatureStatus.loading),
      const FeatureState(status: FeatureStatus.loaded, features: []),
    ],
  );
}
```

### 2. Widget Tests (Recommended)
```dart
testWidgets('displays features when loaded', (tester) async {
  // Arrange
  final mockBloc = MockFeatureBloc();
  when(mockBloc.state).thenReturn(
    const FeatureState(status: FeatureStatus.loaded, features: testFeatures),
  );
  
  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<FeatureBloc>.value(
        value: mockBloc,
        child: const FeatureScreen(),
      ),
    ),
  );
  
  // Assert
  expect(find.text('Test Feature'), findsOneWidget);
});
```

## Git Workflow Rules

### 1. Branch Naming Convention
```bash
feature/user-authentication
bugfix/login-validation-error
hotfix/critical-security-patch
refactor/cleanup-unused-imports
```

### 2. Commit Message Format
```bash
feat(auth): add user registration functionality
fix(chat): resolve message ordering issue
refactor(wallet): simplify transaction logic
test(kyc): add unit tests for document upload
docs(readme): update setup instructions
```

### 3. Pull Request Requirements
- [ ] All tests pass
- [ ] Code coverage > 80%
- [ ] No linting errors
- [ ] Updated documentation if needed
- [ ] At least one code review approval
- [ ] Proper branch naming and commit messages

## Performance Rules

### 1. BLoC Optimization
```dart
// Use distinct() to avoid unnecessary rebuilds
on<FeatureLoadRequested>(_onFeatureLoadRequested, transformer: distinct());

// Use debounce() for frequent events
on<SearchQueryChanged>(_onSearchQueryChanged, 
  transformer: debounce(const Duration(milliseconds: 500)));
```

### 2. Widget Performance
```dart
// Use const widgets where possible
const SizedBox(height: 16);

// Use ListView.builder for long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);

// Use AutomaticKeepAliveClientMixin for tab views
class TabView extends StatefulWidget {
  @override
  _TabViewState createState() => _TabViewState();
}

class _TabViewState extends State<TabView> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
}
```

## Security Rules

### 1. Data Protection
```dart
// NEVER log sensitive information
Logger.logBasic('User logged in: ${user.email}'); // ❌ BAD
Logger.logBasic('User logged in successfully'); // ✅ GOOD

// ALWAYS validate input data
if (!EmailValidator.validate(email)) {
  return Left(const InvalidEmailFailure());
}

// ALWAYS use secure storage for tokens
await secureStorage.write(key: 'auth_token', value: token);
```

### 2. Firebase Security
```dart
// ALWAYS check user permissions
if (currentUser?.uid != documentData['userId']) {
  return Left(const PermissionDeniedFailure());
}

// NEVER trust client-side data validation
// Always validate on both client and server side
```

## Debugging Rules

### 1. Logging Standards
```dart
// Use appropriate log levels
Logger.logBasic('Regular information');
Logger.logSuccess('Operation completed successfully');
Logger.logError('Error occurred: $error');
Logger.logWarning('Warning message');

// Include context in logs
Logger.logError('Failed to load user profile for userId: $userId');
```

### 2. Error Handling
```dart
// ALWAYS provide meaningful error messages
return Left(const Failure(
  message: 'Failed to load profile. Please check your connection.',
  code: 'PROFILE_LOAD_FAILED',
));

// NEVER expose stack traces to users
catch (e, stackTrace) {
  Logger.logError('Unexpected error', error: e, stackTrace: stackTrace);
  return Left(const UnexpectedFailure());
}
```

These rules ensure consistency, quality, and maintainability across the entire ParcelAm project. All developers must follow these conventions when adding new features or making improvements.
