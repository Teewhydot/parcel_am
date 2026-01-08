# Testing Patterns

**Analysis Date:** 2026-01-08

## Test Framework

**Runner:**
- flutter_test - Built-in Flutter testing framework
- mockito - Mock generation via annotations
- Vitest not used; using flutter_test instead

**Assertion Library:**
- Built-in `expect()` from flutter_test
- Matchers: `equals()`, `isEmpty()`, `isA<T>()`, `throwsException`, etc.

**Run Commands:**
```bash
flutter test                              # Run all tests
flutter test test/features/...           # Run feature tests
flutter test --coverage                  # Generate coverage report
flutter test --watch                     # Watch mode
```

## Test File Organization

**Location:**
- `*_test.dart` files alongside or near source
- Primary test directory: `test/` at project root
- Mirrors source structure: `lib/features/X/` → `test/features/X/`

**Naming:**
- All tests: `{source}_test.dart`
- No distinction by test type in filename
- Examples: `wallet_bloc_test.dart`, `parcel_model_test.dart`

**Structure:**
```
test/
  core/
    navigation/
      parcel_notification_navigation_test.dart
    services/
      notification_service_parcel_test.dart
    widgets/
      app_button_kyc_test.dart
  features/
    parcel_am_core/
      data/
        datasources/
          wallet_remote_data_source_test.dart
        models/
          transaction_model_test.dart
      presentation/
        widgets/
          delivery_card_test.dart
        bloc/
          wallet_bloc_test.dart
    notifications/
      parcel_notification_integration_test.dart
  data/
    parcel_seeder.dart                   # Shared test fixtures
```

## Test Structure

**Suite Organization:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('UserRepository', () {
    late UserRepository repository;
    late MockUserDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockUserDataSource();
      repository = UserRepository(dataSource: mockDataSource);
    });

    test('should fetch user successfully', () async {
      // Arrange
      final testUser = UserModel(id: '1', name: 'Test');
      when(mockDataSource.getUser('1')).thenAnswer((_) async => testUser);

      // Act
      final result = await repository.getUser('1');

      // Assert
      expect(result, equals(testUser));
      verify(mockDataSource.getUser('1')).called(1);
    });

    test('should throw exception on failure', () async {
      // Arrange
      when(mockDataSource.getUser('1')).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(() => repository.getUser('1'), throwsException);
    });
  });
}
```

**Patterns:**
- Use `setUp()` for per-test initialization
- Use `setUpAll()` for one-time setup (less common)
- Arrange-Act-Assert structure with comments
- One test focus per test (can have multiple assertions)
- Test name describes what should happen

## Mocking

**Framework:**
- mockito package for mock generation
- `@GenerateMocks([Class])` annotation
- `MockClassName` naming convention for generated mocks

**Patterns:**
```dart
@GenerateMocks([UserRepository, FirebaseAuth])
void main() {
  late MockUserRepository mockRepository;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockRepository = MockUserRepository();
    mockAuth = MockFirebaseAuth();
  });

  test('should use mocked repository', () {
    when(mockRepository.getUser('1'))
        .thenAnswer((_) async => UserEntity(id: '1'));

    // test code

    verify(mockRepository.getUser('1')).called(1);
  });
}
```

**What to Mock:**
- External services (Firebase, APIs)
- Repositories (test the layer above)
- BLoCs (when testing presentation logic)
- Date/time operations if needed

**What NOT to Mock:**
- Pure business logic functions
- Data models
- Entities
- Value objects
- Local utilities

## Fixtures and Factories

**Test Data:**
```dart
// Factory function
UserModel createTestUser({
  String id = 'test-id',
  String name = 'Test User',
}) {
  return UserModel(
    id: id,
    name: name,
    email: '$name@test.com',
  );
}

// Shared fixtures
const testParcelJson = {
  'id': 'parcel-1',
  'status': 'created',
  'amount': 100.0,
};

// In test
test('should parse parcel JSON', () {
  final model = ParcelModel.fromJson(testParcelJson);
  expect(model.id, equals('parcel-1'));
});
```

**Location:**
- Factories: Defined in test file near usage
- Shared fixtures: `test/data/parcel_seeder.dart` (if multi-file use)
- Mock data: Inline in test when simple, factory when complex

## Coverage

**Requirements:**
- No enforced minimum coverage percentage
- Coverage tracked for awareness
- Focus on critical paths (BLoCs, use cases, repositories)

**Configuration:**
- Built into flutter_test
- Excludes: `*_test.dart` files, generated files, main.dart

**View Coverage:**
```bash
flutter test --coverage
open coverage/index.html  # macOS
```

## Test Types

**Unit Tests:**
- Test single class/function in isolation
- Mock all external dependencies
- Fast execution (typically <100ms each)
- Examples: Models, entities, validators

**Widget Tests:**
- Test individual widgets or small widget trees
- Mock BLoCs and services
- Use `testWidgets()` instead of `test()`
- Verify UI rendering and user interaction
- Examples: `delivery_card_test.dart`, `app_button_kyc_test.dart`

**Integration Tests:**
- Test multiple layers working together
- Mock external services (Firestore, APIs)
- Slower than unit tests
- Examples: `wallet_balance_management_integration_test.dart`, `parcel_notification_integration_test.dart`

**E2E Tests:**
- Not currently implemented
- Would require test driver setup

## Common Patterns

**Async Testing:**
```dart
test('should handle async operation', () async {
  final result = await repository.fetchData();
  expect(result, isNotEmpty);
});
```

**Error Testing:**
```dart
test('should throw on invalid input', () {
  expect(() => validator.validate(''), throwsException);
});

test('should reject failed async operation', () async {
  when(mockService.fetch()).thenThrow(Exception('Error'));
  expect(() => repository.fetch(), throwsException);
});
```

**BLoC Testing:**
```dart
blocTest<WalletBloc, BaseState<WalletData>>(
  'should emit LoadedState when wallet loaded',
  build: () {
    when(mockUseCase.getWallet('user-1'))
        .thenAnswer((_) async => walletEntity);
    return WalletBloc(useCase: mockUseCase);
  },
  act: (bloc) => bloc.add(WalletLoadRequested()),
  expect: () => [
    isA<LoadingState<WalletData>>(),
    isA<LoadedState<WalletData>>(),
  ],
);
```

**Widget Testing:**
```dart
testWidgets('DeliveryCard should display status', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DeliveryCard(parcel: testParcel),
      ),
    ),
  );

  expect(find.text('In Transit'), findsOneWidget);
});
```

**Snapshot Testing:**
- Not used in this codebase
- Prefer explicit assertions for clarity

---

*Testing analysis: 2026-01-08*
*Update when test patterns change*
