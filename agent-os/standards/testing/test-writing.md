## Test Coverage Best Practices

## Testing Philosophy
- **Write Minimal Tests During Development**: Focus on feature completion first, add strategic tests at logical milestones
- **Test Only Core Functionality**: Test critical user flows and business logic, skip secondary features initially
- **Defer Edge Case Testing**: Don't test edge cases during development unless business-critical
- **Test Behavior, Not Implementation**: Test what code does, not how it does it - reduces brittleness when refactoring
- **Balance Coverage with Pragmatism**: Aim for reasonable coverage on core features, not 100% coverage

## Unit Testing (Business Logic)
- **Test BLoCs/Cubits Thoroughly**: Unit test all state management logic in isolation
- **Use bloc_test Package**: Simplifies BLoC testing with concise syntax
- **Test State Transitions**: Verify correct states are emitted for each event
- **Test Initial State**: Always test that initial state is correct
- **Mock Repositories**: Use mockito or mocktail to mock data sources
- **Test All Paths**: Test success, failure, and loading states
- **Test Error Handling**: Verify errors are caught and proper error states emitted

Example:
```dart
blocTest<UserBloc, UserState>(
  'emits [Loading, Loaded] when FetchUser succeeds',
  build: () => UserBloc(mockRepository),
  act: (bloc) => bloc.add(FetchUser('123')),
  expect: () => [
    UserState.loading(),
    UserState.loaded(mockUser),
  ],
);
```

## Widget Testing
- **Test Custom Widgets**: Test reusable custom widgets, not every screen
- **Test Widget Behavior**: Verify widgets display correct data and respond to interactions
- **Use pumpWidget**: Create widget trees with WidgetTester.pumpWidget()
- **Find Widgets**: Use find.text(), find.byType(), find.byKey() to locate widgets
- **Simulate Interactions**: Use tester.tap(), tester.enterText(), tester.drag()
- **Pump Frames**: Use await tester.pump() or pumpAndSettle() to process rebuilds
- **Mock BLoCs**: Provide mock BLoCs via BlocProvider in widget tests
- **Test Loading/Error States**: Verify UI responds correctly to different states

Example:
```dart
testWidgets('displays user name when loaded', (tester) async {
  when(() => mockBloc.state).thenReturn(UserState.loaded(user));

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: mockBloc,
        child: UserScreen(),
      ),
    ),
  );

  expect(find.text('John Doe'), findsOneWidget);
});
```

## Integration Testing
- **Test Critical User Flows**: End-to-end tests for key features (login, purchase, etc.)
- **Use integration_test Package**: Official Flutter package for integration tests
- **Run on Real Devices**: Integration tests should run on physical devices or emulators
- **Test Navigation**: Verify users can navigate through complete workflows
- **Test with Real Firebase**: Use Firebase Emulator or test Firebase project
- **Keep Tests Focused**: Each integration test should test one complete flow
- **Handle Async Operations**: Use proper waits for Firebase operations to complete

## Mocking & Fakes
- **Mock External Dependencies**: Mock Firestore, Firebase Auth, HTTP clients
- **Use mockito or mocktail**: Popular mocking libraries for Dart
- **Create Fake Implementations**: For complex objects, create fake classes instead of mocks
- **Use fake_cloud_firestore**: Fake Firestore for offline unit/widget tests
- **Mock Platform Channels**: Mock native platform code with TestDefaultBinaryMessenger
- **Don't Mock Value Objects**: No need to mock simple data classes (models)

## Test Organization
- **Mirror Source Structure**: test/ folder should mirror lib/ folder structure
- **Group Related Tests**: Use group() to organize related test cases
- **Use setUp/tearDown**: Initialize and clean up in setUp() and tearDown()
- **Shared Test Helpers**: Create helper functions for common test setup
- **Test File Naming**: user_bloc_test.dart for testing user_bloc.dart

## Testing Firebase
- **Use Firebase Emulator**: Test Firestore, Auth, Functions locally
- **Test Security Rules**: Write tests for Firestore Security Rules
- **Mock FirebaseFirestore**: Use fake_cloud_firestore in unit tests
- **Test Offline Behavior**: Verify app works with offline persistence
- **Test Error Cases**: Verify handling of permission-denied, not-found errors

## Golden Tests (Optional)
- **Snapshot Widget UI**: Golden tests capture widget screenshots
- **Use matchesGoldenFile**: Compare rendered widget against golden file
- **Update Goldens**: flutter test --update-goldens to regenerate
- **Platform-Specific**: Goldens may differ between platforms
- **Use Sparingly**: Useful for design systems, less for business logic

## Test Naming
- **Descriptive Names**: Test name should explain what's being tested
- **Use "should" or "emits"**: "should return user when id is valid"
- **Include Context**: "emits [Loading, Error] when repository throws exception"
- **Avoid Generic Names**: Not "test1", "test2" - be specific

## Fast Tests
- **Keep Unit Tests Fast**: Should run in milliseconds
- **Avoid Real Network Calls**: Mock HTTP clients and Firebase
- **Minimize Widget Tests**: Widget tests are slower than unit tests
- **Run Subset During Development**: Run single test file while coding
- **Use --dart-define=skip_integration**: Skip slow integration tests locally

## Running Tests
- **Run All Tests**: flutter test
- **Run Single File**: flutter test test/blocs/user_bloc_test.dart
- **Run with Coverage**: flutter test --coverage
- **View Coverage**: genhtml coverage/lcov.info -o coverage/html
- **CI/CD Integration**: Run flutter test in CI pipeline

## What to Test
✅ **Do Test:**
- BLoC/Cubit state transitions and business logic
- Repository data transformations
- Custom widgets behavior
- Navigation flows (integration tests)
- Form validation logic
- Error handling in BLoCs

❌ **Don't Test:**
- Flutter framework widgets (Text, Container already tested)
- Third-party packages (firebase_auth, etc. already tested)
- Simple data models with no logic
- Getters and setters without logic
- Private methods (test through public interface)

## Test Data
- **Create Test Fixtures**: Reusable test data in test/fixtures/ folder
- **Use Factory Functions**: Functions that create test models
- **Keep Data Simple**: Minimal data needed for test to pass
- **Use Meaningful Data**: Makes test easier to understand

## Debugging Tests
- **Use debugPrint**: Print values during test execution
- **Run Single Test**: Focus on failing test
- **Use --verbose**: flutter test --verbose for detailed output
- **Check Stack Traces**: Read full error messages carefully
- **Use Debugger**: Set breakpoints in tests in IDE
