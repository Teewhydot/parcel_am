import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:parcel_am/core/bloc_manager/bloc_manager.dart';
import 'package:parcel_am/core/bloc_manager/bloc_manager_config.dart';
import 'package:parcel_am/core/bloc_manager/bloc_lifecycle_observer.dart';
import 'package:parcel_am/core/bloc_manager/plugins/bloc_manager_plugin.dart';
import 'package:get_it/get_it.dart';

import 'bloc_manager_test.mocks.dart';

// Test Bloc and State
abstract class TestState {}
class TestInitial extends TestState {}
class TestLoading extends TestState {}
class TestSuccess extends TestState {
  final String data;
  TestSuccess(this.data);
}
class TestError extends TestState {
  final String error;
  TestError(this.error);
}

class TestBloc extends Bloc<TestEvent, TestState> {
  TestBloc() : super(TestInitial()) {
    on<LoadData>((event, emit) async {
      emit(TestLoading());
      await Future.delayed(Duration(milliseconds: 50));
      emit(TestSuccess(event.data));
    });
    on<TriggerError>((event, emit) {
      emit(TestError(event.message));
    });
  }
}

abstract class TestEvent {}
class LoadData extends TestEvent {
  final String data;
  LoadData(this.data);
}
class TriggerError extends TestEvent {
  final String message;
  TriggerError(this.message);
}

@GenerateMocks([BlocManagerPlugin, BlocLifecycleObserver])
void main() {
  late GetIt getIt;
  late BlocManagerConfig config;
  
  setUp(() {
    getIt = GetIt.instance;
    getIt.reset();
    config = BlocManagerConfig(
      getIt: getIt,
      enableLogging: true,
      enablePerformanceMonitoring: true,
    );
  });

  tearDown(() {
    getIt.reset();
  });

  group('BlocManager Core Tests', () {
    testWidgets('should create BlocManager with generic type safety', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocManager<TestBloc, TestState>(
            config: config,
            create: (context) => TestBloc(),
            child: Container(),
          ),
        ),
      );

      expect(find.byType(BlocManager<TestBloc, TestState>), findsOneWidget);
    });

    testWidgets('should provide bloc to descendants', (tester) async {
      TestBloc? capturedBloc;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocManager<TestBloc, TestState>(
            config: config,
            create: (context) => TestBloc(),
            child: Builder(
              builder: (context) {
                capturedBloc = context.read<TestBloc>();
                return Container();
              },
            ),
          ),
        ),
      );

      expect(capturedBloc, isNotNull);
      expect(capturedBloc, isA<TestBloc>());
    });

    testWidgets('should handle state changes with BlocBuilder', (tester) async {
      late TestBloc testBloc;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocManager<TestBloc, TestState>(
            config: config,
            create: (context) {
              testBloc = TestBloc();
              return testBloc;
            },
            child: BlocBuilder<TestBloc, TestState>(
              builder: (context, state) {
                if (state is TestInitial) {
                  return Text('Initial');
                } else if (state is TestLoading) {
                  return Text('Loading');
                } else if (state is TestSuccess) {
                  return Text('Success: ${state.data}');
                } else if (state is TestError) {
                  return Text('Error: ${state.error}');
                }
                return Container();
              },
            ),
          ),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);

      // Trigger state change
      testBloc.add(LoadData('test data'));
      await tester.pump();
      expect(find.text('Loading'), findsOneWidget);
      
      await tester.pump(Duration(milliseconds: 60));
      expect(find.text('Success: test data'), findsOneWidget);
    });

    testWidgets('should register bloc with dependency injection', (tester) async {
      TestBloc? registeredBloc;
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocManager<TestBloc, TestState>(
            config: config,
            create: (context) => TestBloc(),
            registerWithDI: true,
            child: Container(),
          ),
        ),
      );

      expect(() => getIt<TestBloc>(), returnsNormally);
      registeredBloc = getIt<TestBloc>();
      expect(registeredBloc, isNotNull);
    });

    testWidgets('should apply plugins', (tester) async {
      final mockPlugin = MockBlocManagerPlugin();
      
      when(mockPlugin.onBlocCreated(any, any)).thenAnswer((_) async {});
      when(mockPlugin.onStateChange(any, any, any)).thenAnswer((_) async {});
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocManager<TestBloc, TestState>(
            config: config,
            plugins: [mockPlugin],
            create: (context) => TestBloc(),
            child: Container(),
          ),
        ),
      );

      verify(mockPlugin.onBlocCreated(any, any)).called(1);
    });

    testWidgets('should handle lifecycle observer', (tester) async {
      final mockObserver = MockBlocLifecycleObserver();
      
      when(mockObserver.onBlocCreated(any)).thenAnswer((_) async {});
      when(mockObserver.onBlocDisposed(any)).thenAnswer((_) async {});
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocManager<TestBloc, TestState>(
            config: config,
            lifecycleObserver: mockObserver,
            create: (context) => TestBloc(),
            child: Container(),
          ),
        ),
      );

      verify(mockObserver.onBlocCreated(any)).called(1);

      await tester.pumpWidget(Container());
      verify(mockObserver.onBlocDisposed(any)).called(1);
    });

    testWidgets('should dispose bloc properly', (tester) async {
      bool disposed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocManager<TestBloc, TestState>(
            config: config,
            create: (context) => TestBloc(),
            onDispose: () => disposed = true,
            child: Container(),
          ),
        ),
      );

      expect(disposed, false);

      await tester.pumpWidget(Container());
      expect(disposed, true);
    });

    testWidgets('should handle lazy initialization', (tester) async {
      late TestBloc testBloc;
      bool blocCreated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocManager<TestBloc, TestState>(
            config: config,
            lazy: true,
            create: (context) {
              blocCreated = true;
              testBloc = TestBloc();
              return testBloc;
            },
            child: Container(),
          ),
        ),
      );

      // Bloc should not be created yet
      expect(blocCreated, false);
      
      // Add a widget that tries to access the bloc
      await tester.pumpWidget(
        MaterialApp(
          home: BlocManager<TestBloc, TestState>(
            config: config,
            lazy: true,
            create: (context) {
              blocCreated = true;
              testBloc = TestBloc();
              return testBloc;
            },
            child: Builder(
              builder: (context) {
                // This should trigger lazy initialization
                context.read<TestBloc>();
                return Container();
              },
            ),
          ),
        ),
      );

      expect(blocCreated, true);
    });
  });

  group('BlocManagerConfig Tests', () {
    test('should create config with default values', () {
      final config = BlocManagerConfig(getIt: getIt);
      
      expect(config.getIt, equals(getIt));
      expect(config.enableLogging, false);
      expect(config.enablePerformanceMonitoring, false);
      expect(config.maxMemoryCache, null);
    });

    test('should create config with custom values', () {
      final config = BlocManagerConfig(
        getIt: getIt,
        enableLogging: true,
        enablePerformanceMonitoring: true,
        maxMemoryCache: 100,
      );
      
      expect(config.enableLogging, true);
      expect(config.enablePerformanceMonitoring, true);
      expect(config.maxMemoryCache, 100);
    });

    test('should create development config', () {
      final config = BlocManagerConfig.development(getIt: getIt);
      
      expect(config.enableLogging, true);
      expect(config.enablePerformanceMonitoring, true);
      expect(config.enableStatePersistence, true);
      expect(config.enableCrossBlocCommunication, true);
    });

    test('should create production config', () {
      final config = BlocManagerConfig.production(getIt: getIt);
      
      expect(config.enableLogging, false);
      expect(config.enablePerformanceMonitoring, false);
      expect(config.maxMemoryCache, 50);
      expect(config.enableStatePersistence, true);
    });

    test('should create test config', () {
      final config = BlocManagerConfig.test(getIt: getIt);
      
      expect(config.enableLogging, false);
      expect(config.enablePerformanceMonitoring, false);
      expect(config.enableStatePersistence, false);
      expect(config.enableCrossBlocCommunication, false);
    });
  });

  group('BlocLifecycleObserver Tests', () {
    test('should track active blocs', () {
      final observer = DefaultBlocLifecycleObserver();
      final bloc = TestBloc();
      
      observer.onBlocCreated(bloc);
      expect(observer.activeBlocs.contains(bloc), true);
      expect(observer.blocInstanceCount[TestBloc], 1);
      
      observer.onBlocDisposed(bloc);
      expect(observer.activeBlocs.contains(bloc), false);
      expect(observer.blocInstanceCount.containsKey(TestBloc), false);
    });

    test('should provide statistics', () {
      final observer = DefaultBlocLifecycleObserver();
      final bloc1 = TestBloc();
      final bloc2 = TestBloc();
      
      observer.onBlocCreated(bloc1);
      observer.onBlocCreated(bloc2);
      
      final stats = observer.getStatistics();
      expect(stats['activeCount'], 2);
      expect(stats['instanceCounts'][TestBloc], 2);
    });
  });
}