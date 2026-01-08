# Coding Conventions

**Analysis Date:** 2026-01-08

## Naming Patterns

**Files:**
- `snake_case.dart` for all Dart source files
- Test files: `*_test.dart` paired with source file
- BLoC triplets: `*_event.dart`, `*_state.dart`, `*_bloc.dart`
- Data files: `*_model.dart`, `*_entity.dart`, `*_repository.dart`
- Example: `create_parcel_usecase.dart`, `parcel_bloc.dart`, `parcel_event.dart`

**Classes:**
- `PascalCase` for all classes
- No prefixes (not `IUserRepository`, just `UserRepository`)
- Interfaces end with contract names: `ChatRepository`, `WalletRepository`
- Models suffix: `UserModel`, `ParcelModel`
- Entities suffix: `UserEntity`, `ParcelEntity`
- Exceptions suffix: `ChatException`, `PaymentException`

**Functions:**
- `camelCase` for all functions and methods
- No special prefixes for async functions (just normal names)
- Event handlers: `_on{EventName}` in BLoCs
- Getters/setters: standard property syntax preferred
- Callback handlers: `on{ActionName}` or `handle{ActionName}`

**Variables:**
- `camelCase` for local variables and properties
- `UPPER_SNAKE_CASE` for constants
- Final variables: use `final` keyword
- Stream variables: suffix with `Stream` (e.g., `parcelStream`)
- Observable variables: suffix with `Rx` or `Observable` if using GetX reactivity
- Private members: prefix with underscore `_privateVar` or `_privateMethod()`

**Types:**
- `PascalCase` for classes, interfaces, type aliases
- `PascalCase` for enums, enum values also `PascalCase` or `UPPER_CASE`
- Examples: `ParcelStatus.created`, `UserRole.admin`
- No `I` prefix for interfaces: `UserRepository` not `IUserRepository`

## Code Style

**Formatting:**
- Dart Format default: 80 character line length (sometimes 100)
- 2-space indentation
- Single quotes for strings: `'string'` not `"string"`
- Double quotes for interpolated strings: `"Hello $name"`
- Trailing commas in multi-line collections

**Linting:**
- `analysis_options.yaml` defines lint rules
- ESLint-equivalent rules enabled
- No console logs in production code
- No unused imports
- Strong null safety enabled

**Imports:**
- External packages first: `import 'package:...';`
- Dart imports: `import 'dart:...';`
- Relative imports: `import '../...';`
- Type imports: `import 'package:foo/foo.dart' as foo;`
- Organized: External → Dart → Relative
- Alphabetical within each group

## BLoC Pattern

**Event Structure:**
```dart
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String chatId;
  const LoadMessages(this.chatId);

  @override
  List<Object> get props => [chatId];
}
```

**State Structure:**
```dart
abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatLoading extends ChatState {
  @override
  List<Object> get props => [];
}
```

**BLoC Pattern:**
- Extend `BaseBloC<Event, State>` for consistency
- Use `on<EventType>(_handler)` to register event handlers
- Handlers are named `_on{EventName}`
- Use `Emitter<State>` for state emission
- Mixins: `RefreshableBlocMixin`, `PaginationBlocMixin` for common behavior

## Error Handling

**Patterns:**
- Services throw typed exceptions
- Repositories catch exceptions and return `Either<Failure, Success>`
- Use `dartz` Either/Option types for functional error handling
- BLoCs catch Failures and emit `ErrorState`
- No uncaught exceptions in production code

**Custom Errors:**
- Extend `Failure` in domain layer
- Create specific failure types: `ChatException`, `PaymentFailure`
- Include context in error messages
- Example: `ParcelFailure('Parcel not found with id: $id')`

**Async Error Handling:**
```dart
try {
  final result = await useCase.execute();
  result.fold(
    (failure) => emit(ErrorState(error: failure)),
    (success) => emit(SuccessState(data: success)),
  );
} catch (e) {
  emit(ErrorState(error: UnexpectedFailure(e.toString())));
}
```

## Logging

**Framework:**
- Custom `Logger` instance in `lib/core/utils/logger.dart`
- Used for debugging: `log('message')`
- No `print()` statements in committed code
- Firebase Crashlytics integration for error tracking

**Patterns:**
- Log important state transitions
- Log API calls and responses (not sensitive data)
- Log errors with context
- Levels: debug, info, warning, error (no trace level)

## Comments

**When to Comment:**
- Complex algorithms: explain the logic
- Business rules: document why not just what
- Non-obvious workarounds: explain the issue and fix
- BLoC event handlers: brief description of flow
- Avoid: obvious comments like `// increment counter`

**JSDoc/TSDoc Style (for public APIs):**
```dart
/// Creates a new parcel and holds funds in escrow.
///
/// Returns [ParcelEntity] with escrow status or [Failure] if creation fails.
Future<Either<Failure, ParcelEntity>> createParcel(ParcelRequest request) async {
  // implementation
}
```

**TODO Format:**
- Simple: `// TODO: refactor this logic`
- With context: `// TODO: optimize N+1 query in wallet_bloc`
- Link to issue if tracking: `// TODO: issue #123 - handle timeout`

## Function Design

**Size:**
- Keep functions under 50 lines when possible
- Extract helpers for complex logic
- One responsibility per function
- One level of abstraction

**Parameters:**
- Max 3 parameters
- For 4+ parameters, use a single parameters object
- Destructure in parameter list: `void fetch({required String id, required int limit})`
- Named parameters for clarity: `create(id: '123', status: 'pending')`

**Return Values:**
- Always return explicitly (avoid implicit `null` returns)
- Use `Either<Failure, T>` for operations that can fail
- Return early for guard clauses
- Prefer immutable data structures

## Module Design

**Exports:**
- Named exports preferred
- Default exports only for main app widget
- Public API: export from feature root if needed
- Example: `lib/features/chat/` might export main entities

**Barrel Files:**
- Optional in this codebase (not strictly enforced)
- If used: `lib/features/{feature}/lib.dart` re-exports public API
- Avoid circular dependencies

**Dependency Injection:**
- GetX `Get.put()` for singleton services
- Factory pattern in `injection_container.dart` for complex setup
- Prefer constructor injection in classes
- Service locator pattern for UI layer only

---

*Convention analysis: 2026-01-08*
*Update when patterns change*
