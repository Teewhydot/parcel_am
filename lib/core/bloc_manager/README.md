# BlocManager System

A comprehensive BLoC management system for Flutter applications that provides centralized lifecycle management, state persistence, cross-BLoC communication, and advanced error recovery.

## Features

- 🔄 **Lifecycle Management**: Automatic creation, disposal, and memory leak detection
- 💾 **State Persistence**: Secure state storage and restoration with error recovery
- 📡 **Cross-BLoC Communication**: Event bus for inter-BLoC messaging
- 🔌 **Plugin System**: Extensible architecture with built-in plugins
- 🧪 **Test-Friendly**: Comprehensive testing utilities and mocks
- 📊 **Performance Monitoring**: Built-in performance tracking and analytics
- 🔐 **Security**: Secure state encryption and validation

## Quick Start

### 1. Basic Usage

```dart
import 'package:parcel_am/core/bloc_manager/bloc_manager.dart';
import 'package:parcel_am/core/bloc_manager/bloc_manager_config.dart';

// Wrap your BLoC with BlocManager
BlocManager<CounterBloc, CounterState>(
  config: BlocManagerConfig.development(
    getIt: GetIt.instance,
  ),
  create: (context) => CounterBloc(),
  child: MyWidget(),
)
```

### 2. With State Persistence

```dart
BlocManager<AuthBloc, AuthState>(
  config: BlocManagerConfig.production(
    getIt: GetIt.instance,
    enableStatePersistence: true,
    enableCrossBlocCommunication: true,
  ),
  create: (context) => AuthBloc()..add(AuthStarted()),
  child: AuthScreen(),
)
```

## Architecture

### Core Components

```
BlocManager System
├── BlocManager<T, S>           # Main widget wrapper
├── BlocManagerConfig           # Configuration and environment setup
├── BlocLifecycleObserver      # Memory management and leak detection
├── StatePersistenceManager    # Secure state storage
├── CrossBlocCommunication     # Inter-BLoC messaging
├── BlocEventBus              # Event broadcasting system
└── Plugins/                  # Extensible plugin system
    ├── LoggingPlugin
    └── PerformancePlugin
```

## Configuration

### Development Environment

```dart
BlocManagerConfig.development(
  getIt: GetIt.instance,
  enableLogging: true,
  enablePerformanceMonitoring: true,
  enableStatePersistence: false,
)
```

### Production Environment

```dart
BlocManagerConfig.production(
  getIt: GetIt.instance,
  enableLogging: false,
  enablePerformanceMonitoring: true,
  enableStatePersistence: true,
  enableCrossBlocCommunication: true,
  maxMemoryCache: 50, // 50MB limit
)
```

### Test Environment

```dart
BlocManagerConfig.test(
  getIt: GetIt.instance,
  enableLogging: false,
  enablePerformanceMonitoring: false,
  enableStatePersistence: false,
)
```

## State Persistence

### Automatic Persistence

```dart
class MyBloc extends Bloc<MyEvent, MyState> 
    with CrossBlocCommunicationMixin<MyEvent, MyState> {
  
  Future<void> _persistState() async {
    await persistenceManager.saveState<MyState>(
      key: 'my_bloc',
      state: state,
      serializer: (state) => state.toJson(),
      validator: (state) => state.isValid,
    );
  }
}
```

### State Restoration

```dart
Future<MyState?> _restoreState() async {
  return await persistenceManager.restoreState<MyState>(
    key: 'my_bloc',
    deserializer: (json) => MyState.fromJson(json),
  );
}
```

## Cross-BLoC Communication

### Using the Mixin

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> 
    with CrossBlocCommunicationMixin<AuthEvent, AuthState> {
  
  AuthBloc() : super(AuthInitial()) {
    // Subscribe to cross-BLoC events
    subscribeToCrossBlocEvents<Map<String, dynamic>>(
      (data) => add(SessionExpired()),
      eventKey: 'session_expired',
    );
    
    // Register for communication
    registerForCommunication('auth');
  }
  
  void _onLoginSuccess(LoginSuccess event, Emitter<AuthState> emit) {
    // Emit cross-BLoC event
    emitCrossBlocEvent('user_authenticated', {
      'userId': event.user.id,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

### Direct BLoC Messaging

```dart
// Send message to specific BLoC
sendToBloC<UserEvent>(
  to: 'user',
  event: LoadUserProfile(userId: 'user123'),
);

// Broadcast to all compatible BLoCs
broadcastToBLoCs<AppEvent>(GlobalRefresh());
```

## Error Recovery Strategies

### Exponential Backoff

```dart
StatePersistenceManager(
  errorRecoveryStrategy: ExponentialBackoffStrategy(
    maxRetries: 3,
    initialDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 10),
    multiplier: 2.0,
    jitterFactor: 0.1,
  ),
)
```

### Circuit Breaker

```dart
StatePersistenceManager(
  errorRecoveryStrategy: CircuitBreakerStrategy(
    failureThreshold: 5,
    timeout: Duration(minutes: 1),
  ),
)
```

### Composite Strategy

```dart
StatePersistenceManager(
  errorRecoveryStrategy: CompositeErrorRecoveryStrategy(
    strategies: [
      ExponentialBackoffStrategy(maxRetries: 2),
      CircuitBreakerStrategy(failureThreshold: 3),
      RetryWithFallbackStrategy(fallback: () => defaultState),
    ],
  ),
)
```

## Plugin System

### Built-in Plugins

#### Logging Plugin

```dart
class LoggingPlugin extends BlocManagerPlugin {
  @override
  Future<void> onBlocCreated<T extends BlocBase>(String key, T bloc) async {
    print('[BlocManager] Created: $key ($T)');
  }
  
  @override
  Future<void> onStateChange<T>(String key, T previousState, T newState) async {
    print('[BlocManager] $key: $previousState -> $newState');
  }
}
```

#### Performance Plugin

```dart
class PerformancePlugin extends BlocManagerPlugin {
  final Map<String, Stopwatch> _timers = {};
  
  @override
  Future<void> onBlocCreated<T extends BlocBase>(String key, T bloc) async {
    _timers[key] = Stopwatch()..start();
  }
  
  @override
  Future<void> onBlocDisposed<T extends BlocBase>(String key, T bloc) async {
    final timer = _timers.remove(key);
    if (timer != null) {
      print('[Performance] $key lived for ${timer.elapsedMilliseconds}ms');
    }
  }
}
```

### Custom Plugin

```dart
class CustomAnalyticsPlugin extends BlocManagerPlugin {
  final AnalyticsService _analytics;
  
  CustomAnalyticsPlugin(this._analytics);
  
  @override
  Future<void> onStateChange<T>(String key, T previousState, T newState) async {
    await _analytics.trackEvent('bloc_state_change', {
      'bloc_type': key,
      'state_type': T.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

## Testing

### Test Setup

```dart
void main() {
  late MockAuthRepository mockRepository;
  late AuthBloc authBloc;
  
  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(repository: mockRepository);
  });
  
  tearDown(() {
    authBloc.close();
  });
  
  testBloc<AuthBloc, AuthState>(
    'should emit authenticated state on login',
    build: () => authBloc,
    act: (bloc) => bloc.add(LoginRequested('user', 'pass')),
    expect: () => [
      AuthLoading(),
      AuthAuthenticated(user: testUser),
    ],
    verify: (bloc) {
      verify(mockRepository.login('user', 'pass')).called(1);
    },
  );
}
```

### Integration Testing

```dart
testWidgets('BlocManager integration test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocManager<CounterBloc, CounterState>(
        config: BlocManagerConfig.test(getIt: GetIt.instance),
        create: (_) => CounterBloc(),
        child: CounterScreen(),
      ),
    ),
  );
  
  // Test interactions
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  
  expect(find.text('1'), findsOneWidget);
});
```

## Memory Management

### Automatic Leak Detection

```dart
final observer = DefaultBlocLifecycleObserver();
final statistics = observer.getStatistics();

print('Active BLoCs: ${statistics['activeBlocCount']}');
print('Total created: ${statistics['totalCreatedCount']}');
print('Memory usage: ${statistics['memoryUsage']}MB');

// Check for leaks
final leaks = await observer.checkForLeaks();
if (leaks.isNotEmpty) {
  print('Memory leaks detected: $leaks');
}
```

## Migration Guide

### From Standard BLoC to BlocManager

#### Before

```dart
BlocProvider<AuthBloc>(
  create: (context) => AuthBloc(),
  child: AuthScreen(),
)
```

#### After

```dart
BlocManager<AuthBloc, AuthState>(
  config: BlocManagerConfig.development(getIt: GetIt.instance),
  create: (context) => AuthBloc(),
  child: AuthScreen(),
)
```

### Adding State Persistence

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> 
    with CrossBlocCommunicationMixin<AuthEvent, AuthState> {
  
  static const String _persistenceKey = 'auth_bloc';
  
  // Serialize state
  Map<String, dynamic> _stateToJson(AuthState state) {
    return {
      'status': state.status.index,
      'user': state.user?.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  // Deserialize state
  AuthState _stateFromJson(Map<String, dynamic> json) {
    return AuthState(
      status: AuthStatus.values[json['status'] as int],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}
```

## Best Practices

### 1. State Management

- Keep state immutable
- Use copyWith for state updates
- Validate state before persistence
- Handle serialization errors gracefully

### 2. Cross-BLoC Communication

- Use specific event keys for clarity
- Avoid circular dependencies
- Handle communication errors
- Use replay for important events

### 3. Performance

- Limit memory cache size in production
- Use lazy initialization when possible
- Clean up subscriptions properly
- Monitor BLoC lifecycle

### 4. Testing

- Mock dependencies properly
- Test error scenarios
- Verify cross-BLoC interactions
- Use integration tests for critical flows

## Troubleshooting

### Common Issues

#### BLoC Not Disposed
```dart
// Ensure proper cleanup
@override
Future<void> close() async {
  // Cancel subscriptions
  _subscription?.cancel();
  // Unregister from communication
  unregisterFromCommunication();
  return super.close();
}
```

#### State Not Persisting
```dart
// Check serialization
Map<String, dynamic> toJson() {
  // Ensure all fields are serializable
  return {
    'field1': field1,
    'field2': field2?.toJson(), // Handle null values
  };
}
```

#### Cross-BLoC Events Not Received
```dart
// Ensure registration
registerForCommunication('bloc_key');

// Check event key consistency
emitCrossBlocEvent('user_updated', data); // Sender
subscribeToCrossBlocEvents<DataType>(    // Receiver
  callback,
  eventKey: 'user_updated', // Same key
);
```

## API Reference

See the individual class documentation for detailed API information:

- [BlocManager](./bloc_manager.dart)
- [BlocManagerConfig](./bloc_manager_config.dart) 
- [StatePersistenceManager](./persistence/state_persistence_manager.dart)
- [CrossBlocCommunication](./communication/cross_bloc_communication.dart)
- [BlocEventBus](./communication/bloc_event_bus.dart)
- [ErrorRecoveryStrategy](./persistence/error_recovery_strategy.dart)

## Contributing

1. Follow the existing code style
2. Add comprehensive tests
3. Update documentation
4. Ensure backward compatibility
5. Test with real-world scenarios

## License

This project is part of the TravelLink parcel delivery platform.