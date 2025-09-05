import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc_manager/communication/cross_bloc_communication.dart';
import 'package:parcel_am/core/bloc_manager/communication/bloc_event_bus.dart';

// Test BLoCs and States
abstract class TestEvent {}
class TestDataLoaded extends TestEvent {
  final String data;
  TestDataLoaded(this.data);
}

abstract class TestState {}
class TestInitial extends TestState {}
class TestDataState extends TestState {
  final String data;
  TestDataState(this.data);
}

abstract class UserEvent {}
class UserProfileRequested extends UserEvent {
  final String userId;
  UserProfileRequested(this.userId);
}

abstract class UserState {}
class UserInitial extends UserState {}
class UserProfileLoaded extends UserState {
  final String userId;
  final String name;
  UserProfileLoaded(this.userId, this.name);
}

// Test BLoCs
class TestBloc extends Bloc<TestEvent, TestState> with CrossBlocCommunicationMixin {
  TestBloc() : super(TestInitial()) {
    on<TestDataLoaded>((event, emit) {
      emit(TestDataState(event.data));
      // Emit cross-bloc event when data is loaded
      emitCrossBlocEvent('user_data_updated', {'data': event.data});
    });
  }
}

class UserBloc extends Bloc<UserEvent, UserState> with CrossBlocCommunicationMixin {
  UserBloc() : super(UserInitial()) {
    on<UserProfileRequested>((event, emit) {
      emit(UserProfileLoaded(event.userId, 'User ${event.userId}'));
      // Emit cross-bloc event
      emitCrossBlocEvent('user_profile_loaded', {
        'userId': event.userId,
        'name': 'User ${event.userId}'
      });
    });
  }
}

void main() {
  late BlocEventBus eventBus;
  late CrossBlocCommunication communication;

  setUp(() {
    eventBus = BlocEventBus.instance;
    eventBus.reset(); // Clear any existing subscriptions
    communication = CrossBlocCommunication.instance;
  });

  tearDown(() {
    eventBus.reset();
  });

  group('BlocEventBus Tests', () {
    test('should emit and listen to events', () async {
      final completer = Completer<String>();
      String? receivedData;

      // Subscribe to events
      final subscription = eventBus.on<String>('test_event').listen((data) {
        receivedData = data;
        completer.complete(data);
      });

      // Emit event
      eventBus.emit('test_event', 'test_data');

      // Wait for event to be received
      await completer.future;

      expect(receivedData, equals('test_data'));
      await subscription.cancel();
    });

    test('should handle multiple subscribers', () async {
      final completer1 = Completer<String>();
      final completer2 = Completer<String>();
      String? received1, received2;

      // Subscribe to same event with multiple listeners
      final subscription1 = eventBus.on<String>('multi_event').listen((data) {
        received1 = data;
        completer1.complete(data);
      });

      final subscription2 = eventBus.on<String>('multi_event').listen((data) {
        received2 = data;
        completer2.complete(data);
      });

      // Emit event
      eventBus.emit('multi_event', 'shared_data');

      // Wait for both to receive
      await Future.wait([completer1.future, completer2.future]);

      expect(received1, equals('shared_data'));
      expect(received2, equals('shared_data'));
      
      await subscription1.cancel();
      await subscription2.cancel();
    });

    test('should handle different event types', () async {
      final stringCompleter = Completer<String>();
      final mapCompleter = Completer<Map<String, String>>();
      String? stringReceived;
      Map<String, String>? mapReceived;

      // Subscribe to different types
      final stringSubscription = eventBus.on<String>('string_event').listen((data) {
        stringReceived = data;
        stringCompleter.complete(data);
      });

      final mapSubscription = eventBus.on<Map<String, String>>('map_event').listen((data) {
        mapReceived = data;
        mapCompleter.complete(data);
      });

      // Emit different types
      eventBus.emit('string_event', 'string_data');
      eventBus.emit('map_event', {'key': 'value'});

      // Wait for both
      await Future.wait([stringCompleter.future, mapCompleter.future]);

      expect(stringReceived, equals('string_data'));
      expect(mapReceived, equals({'key': 'value'}));

      await stringSubscription.cancel();
      await mapSubscription.cancel();
    });

    test('should support event replay for late subscribers', () async {
      // Emit event before subscribing
      eventBus.emit('replay_event', 'replayed_data', replay: true);

      final completer = Completer<String>();
      String? receivedData;

      // Subscribe after event was emitted
      final subscription = eventBus.on<String>('replay_event', replay: true).listen((data) {
        receivedData = data;
        completer.complete(data);
      });

      await completer.future;

      expect(receivedData, equals('replayed_data'));
      await subscription.cancel();
    });

    test('should filter events correctly', () async {
      final completer = Completer<int>();
      final receivedValues = <int>[];

      final subscription = eventBus.on<int>('filtered_event')
          .where((value) => value > 5)
          .listen((data) {
        receivedValues.add(data);
        if (receivedValues.length == 2) {
          completer.complete(data);
        }
      });

      // Emit various values
      eventBus.emit('filtered_event', 2); // Should be filtered out
      eventBus.emit('filtered_event', 7); // Should pass
      eventBus.emit('filtered_event', 3); // Should be filtered out
      eventBus.emit('filtered_event', 10); // Should pass

      await completer.future;

      expect(receivedValues, equals([7, 10]));
      await subscription.cancel();
    });

    test('should handle subscription cleanup', () async {
      final subscription = eventBus.on<String>('cleanup_event').listen((_) {});
      
      expect(eventBus.hasSubscriptions('cleanup_event'), true);
      
      await subscription.cancel();
      
      // Should clean up automatically
      expect(eventBus.hasSubscriptions('cleanup_event'), false);
    });

    test('should provide statistics', () async {
      final sub1 = eventBus.on<String>('stats_event1').listen((_) {});
      final sub2 = eventBus.on<int>('stats_event2').listen((_) {});

      final stats = eventBus.getStatistics();

      expect(stats['activeControllers'], 2);
      expect(stats['uniqueEvents'], 0); // No events emitted yet

      await sub1.cancel();
      await sub2.cancel();
    });
  });

  group('CrossBlocCommunication Tests', () {
    test('should register and communicate between BLoCs', () async {
      final testBloc = TestBloc();
      final userBloc = UserBloc();

      // Register BLoCs
      communication.registerBloc('test', testBloc);
      communication.registerBloc('user', userBloc);

      final completer = Completer<void>();
      
      // Listen for events
      final subscription = eventBus.on<Map<String, dynamic>>('user_profile_loaded').listen((data) {
        expect(data['userId'], equals('123'));
        expect(data['name'], equals('User 123'));
        completer.complete();
      });

      // Trigger event
      userBloc.add(UserProfileRequested('123'));
      
      await completer.future.timeout(Duration(seconds: 2));

      await subscription.cancel();
      await testBloc.close();
      await userBloc.close();
      communication.unregisterBloc('test');
      communication.unregisterBloc('user');
    });

    test('should handle BLoC lifecycle management', () {
      final testBloc = TestBloc();
      
      expect(communication.isRegistered('lifecycle_test'), false);
      
      communication.registerBloc('lifecycle_test', testBloc);
      expect(communication.isRegistered('lifecycle_test'), true);
      
      communication.unregisterBloc('lifecycle_test');
      expect(communication.isRegistered('lifecycle_test'), false);

      testBloc.close();
    });

    test('should provide registered BLoCs list', () {
      final testBloc1 = TestBloc();
      final testBloc2 = TestBloc();

      final initialCount = communication.getRegisteredBlocs().length;

      communication.registerBloc('test1', testBloc1);
      communication.registerBloc('test2', testBloc2);

      final registeredBlocs = communication.getRegisteredBlocs();
      expect(registeredBlocs.length, equals(initialCount + 2));
      expect(registeredBlocs.containsKey('test1'), true);
      expect(registeredBlocs.containsKey('test2'), true);

      communication.unregisterBloc('test1');
      communication.unregisterBloc('test2');
      
      testBloc1.close();
      testBloc2.close();
    });

    test('should handle direct BLoC-to-BLoC communication', () async {
      final testBloc = TestBloc();
      final userBloc = UserBloc();

      communication.registerBloc('sender', testBloc);
      communication.registerBloc('receiver', userBloc);

      final completer = Completer<void>();

      // Listen for direct communication
      userBloc.stream.listen((state) {
        if (state is UserProfileLoaded && state.userId == 'direct') {
          completer.complete();
        }
      });

      // Send direct message between BLoCs - cast to correct type
      communication.sendMessage<UserEvent>(
        from: 'sender',
        to: 'receiver',
        event: UserProfileRequested('direct'),
      );

      await completer.future.timeout(Duration(seconds: 2));

      await testBloc.close();
      await userBloc.close();
      communication.unregisterBloc('sender');
      communication.unregisterBloc('receiver');
    });
  });

  group('CrossBlocCommunicationMixin Tests', () {
    test('should enable cross-bloc event emission and subscription', () async {
      final testBloc = TestBloc();
      final completer = Completer<void>();

      // Subscribe to cross-bloc events
      final subscription = eventBus.on<Map<String, dynamic>>('user_data_updated').listen((data) {
        expect(data['data'], equals('test_data'));
        completer.complete();
      });

      // Trigger event that should emit cross-bloc event
      testBloc.add(TestDataLoaded('test_data'));

      await completer.future.timeout(Duration(seconds: 2));
      
      await subscription.cancel();
      await testBloc.close();
    });

    test('should handle subscription management in mixin', () async {
      final testBloc = TestBloc();
      
      // Initially no active subscriptions
      expect(testBloc.hasActiveSubscriptions, false);

      // Add a subscription
      testBloc.subscribeToCrossBlocEvents<String>((data) {
        // Handle data
      }, eventKey: 'test_subscription');

      expect(testBloc.hasActiveSubscriptions, true);

      await testBloc.close();
      
      // Subscriptions should be cleaned up
      expect(testBloc.hasActiveSubscriptions, false);
    });
  });

  group('Integration Tests', () {
    test('should handle complex multi-BLoC communication flow', () async {
      final authBloc = TestBloc();
      final userBloc = UserBloc();

      communication.registerBloc('auth', authBloc);
      communication.registerBloc('user', userBloc);

      final completer = Completer<void>();
      int eventCount = 0;

      // Monitor events
      final subscription1 = eventBus.on<Map<String, dynamic>>('user_data_updated').listen((data) {
        eventCount++;
        if (eventCount >= 2 && !completer.isCompleted) {
          completer.complete();
        }
      });

      final subscription2 = eventBus.on<Map<String, dynamic>>('user_profile_loaded').listen((data) {
        eventCount++;
        if (eventCount >= 2 && !completer.isCompleted) {
          completer.complete();
        }
      });

      // Start the flow
      authBloc.add(TestDataLoaded('auth_success'));
      userBloc.add(UserProfileRequested('user_123'));

      await completer.future.timeout(Duration(seconds: 2));

      await subscription1.cancel();
      await subscription2.cancel();
      await authBloc.close();
      await userBloc.close();
      
      communication.unregisterBloc('auth');
      communication.unregisterBloc('user');
    });
  });
}