# State Management Best Practices

## General Principles
- **Use the state management solution already established in the project** - consistency matters more than personal preference
- **For new projects, prefer BLoC/Cubit** - clear separation of concerns, testable, scalable
- Separate business logic from UI - widgets should only handle presentation
- Keep state as close to where it's used as possible - avoid global state when local state suffices
- Make state immutable - use final fields and create new instances for updates
- Avoid setState() for complex state - use proper state management solutions

## BLoC/Cubit Pattern (Recommended)
- Use Cubit for simple state changes, BLoC for complex event-driven logic with streams
- Keep one BLoC/Cubit per feature or screen for separation of concerns
- Name events/states clearly: LoadUserRequested, UserLoaded, UserLoadFailure
- Use sealed classes or Freezed for type-safe state classes
- Use BlocProvider at the appropriate level - not globally unless truly needed
- Use BlocBuilder for UI that depends on state, BlocListener for side effects (navigation, snackbars)
- Use BlocConsumer when you need both builder and listener
- Close BLoCs properly - rely on BlocProvider's automatic disposal
- Emit states sequentially - avoid calling emit() multiple times in rapid succession
- Test BLoCs independently from UI - they should be pure Dart classes

## Local State (setState)
- Use StatefulWidget with setState only for simple, widget-local state
- Acceptable for: form input, animation controllers, tab selection, expand/collapse
- Not suitable for: data fetching, business logic, state shared across widgets
- Always check mounted before calling setState in async callbacks
- Dispose controllers and listeners in dispose() method
- Use late keyword for non-nullable state that's initialized in initState()

## Provider (Alternative)
- If project uses Provider, follow ChangeNotifier pattern
- Keep ChangeNotifier classes in separate files from widgets
- Call notifyListeners() after state changes, not during
- Use Consumer widget to rebuild only necessary parts of the tree
- Use Selector for granular rebuilds based on specific properties
- Dispose resources in ChangeNotifier.dispose() method
- Prefer read for one-time access, watch for reactive dependencies

## State Organization
- Separate state into: UI state, business state, and data/entity state
- Keep loading, error, and success states distinct (often using sealed classes)
- Use meaningful state class names: AuthenticationState, UserProfileState
- Include all necessary data in state classes - avoid additional API calls from UI
- Use copyWith() methods for updating immutable state classes
- Consider using Equatable or Freezed for value equality and copyWith generation

## Data Flow
- Data flows down (parent to child) via constructor parameters
- Events flow up (child to parent) via callbacks or BLoC events
- Use StreamBuilders for reactive data streams (e.g., Firestore snapshots)
- Use FutureBuilder only for one-time async operations
- Avoid passing BuildContext to business logic - keep BLoCs/Cubits UI-agnostic
- Handle loading states explicitly - show spinners or skeleton screens

## Error Handling
- Always model error states explicitly in your state classes
- Display user-friendly error messages, not raw exception messages
- Use try-catch in BLoCs/Cubits, emit error states appropriately
- Implement retry mechanisms for failed operations
- Log errors for debugging but don't expose technical details to users
- Consider using Result/Either types for explicit success/failure modeling

## Dependency Injection
- Use get_it or injectable for dependency injection in larger apps
- Provide repositories, services, and data sources via DI, not BLoCs
- Keep BLoCs registered at the appropriate scope (singleton vs factory)
- Mock dependencies in tests for isolated testing
- Avoid service locator pattern directly in widgets - use BlocProvider with create

## Performance
- Use BlocSelector to rebuild only when specific state properties change
- Avoid emitting duplicate states - use Equatable or override == operator
- Don't create new BLoC instances in build methods
- Use const constructors for state classes when possible
- Debounce or throttle events that can fire rapidly (e.g., search input)

## Testing
- Write unit tests for all BLoCs/Cubits testing state transitions
- Use blocTest package for concise BLoC testing
- Mock repositories and services - test business logic in isolation
- Test error states and edge cases, not just happy paths
- Test initial states, event handling, and state emissions
- Widget tests should mock BLoCs - test UI logic separately from business logic