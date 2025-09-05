import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parcel_am/core/bloc_manager/persistence/state_persistence_manager.dart';
import 'package:parcel_am/core/bloc_manager/persistence/error_recovery_strategy.dart';

import 'state_persistence_manager_test.mocks.dart';

// Test state classes
class TestState {
  final String data;
  final int version;

  const TestState({
    required this.data,
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
    'data': data,
    'version': version,
  };

  factory TestState.fromJson(Map<String, dynamic> json) => TestState(
    data: json['data'] as String,
    version: json['version'] as int? ?? 1,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestState && other.data == data && other.version == version;
  }

  @override
  int get hashCode => data.hashCode ^ version.hashCode;

  @override
  String toString() => 'TestState(data: $data, version: $version)';
}

@GenerateMocks([FlutterSecureStorage])
void main() {
  late MockFlutterSecureStorage mockStorage;
  late StatePersistenceManager persistenceManager;
  late ErrorRecoveryStrategy errorRecoveryStrategy;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    errorRecoveryStrategy = ExponentialBackoffStrategy(
      maxRetries: 3,
      initialDelay: Duration(milliseconds: 100),
      maxDelay: Duration(seconds: 1),
    );
    
    persistenceManager = StatePersistenceManager(
      storage: mockStorage,
      errorRecoveryStrategy: errorRecoveryStrategy,
    );
  });

  tearDown(() {
    reset(mockStorage);
  });

  group('StatePersistenceManager Tests', () {
    test('should save state successfully', () async {
      const testState = TestState(data: 'test_data');
      const key = 'test_key';

      when(mockStorage.write(
        key: 'bloc_state_test_key',
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      await persistenceManager.saveState<TestState>(
        key: key,
        state: testState,
        serializer: (state) => state.toJson(),
      );

      verify(mockStorage.write(
        key: 'bloc_state_test_key',
        value: anyNamed('value'),
      )).called(1);
    });

    test('should restore state successfully', () async {
      const testState = TestState(data: 'restored_data');
      const key = 'test_key';
      final now = DateTime.now();
      final savedJson = '{"data":{"data":"restored_data","version":1},"timestamp":"${now.toIso8601String()}","version":1}';

      when(mockStorage.read(key: 'bloc_state_test_key'))
          .thenAnswer((_) async => savedJson);

      final restoredState = await persistenceManager.restoreState<TestState>(
        key: key,
        deserializer: (json) => TestState.fromJson(json),
      );

      expect(restoredState, equals(testState));
      verify(mockStorage.read(key: 'bloc_state_test_key')).called(1);
    });

    test('should handle missing state gracefully', () async {
      const key = 'missing_key';

      when(mockStorage.read(key: 'bloc_state_missing_key'))
          .thenAnswer((_) async => null);

      final restoredState = await persistenceManager.restoreState<TestState>(
        key: key,
        deserializer: (json) => TestState.fromJson(json),
      );

      expect(restoredState, isNull);
    });

    test('should handle corrupted state data', () async {
      const key = 'corrupted_key';
      const corruptedJson = 'invalid json';

      when(mockStorage.read(key: 'bloc_state_corrupted_key'))
          .thenAnswer((_) async => corruptedJson);

      final restoredState = await persistenceManager.restoreState<TestState>(
        key: key,
        deserializer: (json) => TestState.fromJson(json),
      );

      expect(restoredState, isNull);
    });

    test('should clear state successfully', () async {
      const key = 'test_key';

      when(mockStorage.delete(key: 'bloc_state_test_key'))
          .thenAnswer((_) async {});

      await persistenceManager.clearState(key);

      verify(mockStorage.delete(key: 'bloc_state_test_key')).called(1);
    });

    test('should validate state before saving', () async {
      const testState = TestState(data: 'test_data');
      const key = 'test_key';

      when(mockStorage.write(
        key: 'bloc_state_test_key',
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      await persistenceManager.saveState<TestState>(
        key: key,
        state: testState,
        serializer: (state) => state.toJson(),
        validator: (state) => state.data.isNotEmpty,
      );

      verify(mockStorage.write(
        key: 'bloc_state_test_key',
        value: anyNamed('value'),
      )).called(1);
    });

    test('should not save invalid state', () async {
      const testState = TestState(data: ''); // Invalid - empty data
      const key = 'test_key';

      await persistenceManager.saveState<TestState>(
        key: key,
        state: testState,
        serializer: (state) => state.toJson(),
        validator: (state) => state.data.isNotEmpty,
      );

      verifyNever(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')));
    });
  });

  group('ErrorRecoveryStrategy Tests', () {
    test('ExponentialBackoffStrategy should retry with increasing delays', () async {
      final strategy = ExponentialBackoffStrategy(
        maxRetries: 3,
        initialDelay: Duration(milliseconds: 10),
        maxDelay: Duration(milliseconds: 100),
      );

      int attempts = 0;
      final stopwatch = Stopwatch()..start();

      final result = await strategy.execute(() async {
        attempts++;
        if (attempts < 3) {
          throw Exception('Test failure');
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(attempts, equals(3));
      expect(stopwatch.elapsedMilliseconds, greaterThan(20)); // At least 2 delays
    });

    test('CircuitBreakerStrategy should open circuit after failures', () async {
      final strategy = CircuitBreakerStrategy(
        failureThreshold: 2,
        timeout: Duration(milliseconds: 100),
      );

      int attempts = 0;

      // First failure
      try {
        await strategy.execute(() async {
          attempts++;
          throw Exception('Test failure');
        });
      } catch (e) {
        // Expected
      }

      // Second failure - should open circuit
      try {
        await strategy.execute(() async {
          attempts++;
          throw Exception('Test failure');
        });
      } catch (e) {
        // Expected
      }

      // Third attempt - should fail fast due to open circuit
      try {
        await strategy.execute(() async {
          attempts++;
          return 'success';
        });
      } catch (e) {
        expect(e, isA<CircuitBreakerOpenException>());
      }

      expect(attempts, equals(2)); // Third attempt should not execute
    });

    test('RetryWithFallbackStrategy should use fallback after retries', () async {
      final strategy = RetryWithFallbackStrategy<String>(
        maxRetries: 2,
        fallback: () async => 'fallback_result',
      );

      int attempts = 0;

      final result = await strategy.execute<String>(() async {
        attempts++;
        throw Exception('Always fails');
      });

      expect(result, equals('fallback_result'));
      expect(attempts, equals(2));
    });
  });

  group('State Persistence Integration Tests', () {
    test('should handle complete save/restore cycle', () async {
      const testState = TestState(data: 'integration_test');
      const key = 'integration_key';

      // Mock successful save
      when(mockStorage.write(
        key: 'bloc_state_integration_key',
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      await persistenceManager.saveState<TestState>(
        key: key,
        state: testState,
        serializer: (state) => state.toJson(),
      );

      verify(mockStorage.write(
        key: 'bloc_state_integration_key',
        value: anyNamed('value'),
      )).called(1);

      // Mock successful restore
      final now = DateTime.now();
      final savedJson = '{"data":{"data":"integration_test","version":1},"timestamp":"${now.toIso8601String()}","version":1}';
      when(mockStorage.read(key: 'bloc_state_integration_key'))
          .thenAnswer((_) async => savedJson);

      final restoredState = await persistenceManager.restoreState<TestState>(
        key: key,
        deserializer: (json) => TestState.fromJson(json),
      );

      expect(restoredState, equals(testState));
    });
  });

  group('StateInfo Tests', () {
    test('should provide state information', () async {
      final now = DateTime.now();
      when(mockStorage.readAll())
          .thenAnswer((_) async => {
            'bloc_state_key1': '{"data":{"data":"value1","version":1},"timestamp":"${now.toIso8601String()}","version":1}',
            'bloc_state_key2': '{"data":{"data":"value2","version":1},"timestamp":"${now.toIso8601String()}","version":1}',
            'other_key': 'other_value',
          });

      final stateInfo = await persistenceManager.getStateInfo();

      expect(stateInfo.length, equals(2));
      expect(stateInfo.containsKey('key1'), true);
      expect(stateInfo.containsKey('key2'), true);
      expect(stateInfo['key1']?.version, equals(1));
    });
  });
}