import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc_event_bus.dart';

/// Singleton manager for cross-BLoC communication
class CrossBlocCommunication {
  static CrossBlocCommunication? _instance;
  static CrossBlocCommunication get instance => _instance ??= CrossBlocCommunication._();

  CrossBlocCommunication._();

  final Map<String, BlocBase> _registeredBlocs = {};
  final BlocEventBus _eventBus = BlocEventBus.instance;

  /// Register a BLoC for cross-communication
  void registerBloc<T extends BlocBase>(String key, T bloc) {
    if (_registeredBlocs.containsKey(key)) {
      debugPrint('[CrossBlocCommunication] Warning: Overwriting existing BLoC with key: $key');
    }

    _registeredBlocs[key] = bloc;
    
    if (kDebugMode) {
      debugPrint('[CrossBlocCommunication] BLoC registered: $key (${T.toString()})');
    }
  }

  /// Unregister a BLoC
  void unregisterBloc(String key) {
    final bloc = _registeredBlocs.remove(key);
    
    if (bloc != null && kDebugMode) {
      debugPrint('[CrossBlocCommunication] BLoC unregistered: $key');
    }
  }

  /// Check if a BLoC is registered
  bool isRegistered(String key) {
    return _registeredBlocs.containsKey(key);
  }

  /// Get a registered BLoC
  T? getBloc<T extends BlocBase>(String key) {
    final bloc = _registeredBlocs[key];
    return bloc is T ? bloc : null;
  }

  /// Get all registered BLoCs
  Map<String, BlocBase> getRegisteredBlocs() {
    return Map<String, BlocBase>.from(_registeredBlocs);
  }

  /// Send a direct message between BLoCs
  void sendMessage<T>({
    required String from,
    required String to,
    required T event,
  }) {
    final fromBloc = _registeredBlocs[from];
    final toBloc = _registeredBlocs[to];

    if (fromBloc == null) {
      debugPrint('[CrossBlocCommunication] Error: Sender BLoC not found: $from');
      return;
    }

    if (toBloc == null) {
      debugPrint('[CrossBlocCommunication] Error: Receiver BLoC not found: $to');
      return;
    }

    try {
      // Try to cast and add the event - let Dart's type system handle the validation
      (toBloc as dynamic).add(event);
      
      if (kDebugMode) {
        debugPrint('[CrossBlocCommunication] Message sent from $from to $to: ${T.toString()}');
      }
    } catch (e, stackTrace) {
      debugPrint('[CrossBlocCommunication] Error sending message from $from to $to: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Broadcast an event to all registered BLoCs that can handle it
  void broadcastEvent<T>(T event, {String? excludeKey}) {
    int receiverCount = 0;

    for (final entry in _registeredBlocs.entries) {
      if (excludeKey != null && entry.key == excludeKey) {
        continue;
      }

      try {
        (entry.value as dynamic).add(event);
        receiverCount++;
      } catch (e) {
        // Silently ignore if BLoC cannot handle the event type
        if (kDebugMode && !e.toString().contains('NoSuchMethodError')) {
          debugPrint('[CrossBlocCommunication] Error broadcasting to ${entry.key}: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('[CrossBlocCommunication] Event broadcasted to $receiverCount BLoCs: ${T.toString()}');
    }
  }

  /// Send an event through the event bus
  void emitEvent<T>(String eventKey, T data, {bool replay = false}) {
    _eventBus.emit(eventKey, data, replay: replay);
  }

  /// Subscribe to events from the event bus
  Stream<T> onEvent<T>(String eventKey, {bool replay = false}) {
    return _eventBus.on<T>(eventKey, replay: replay);
  }

  /// Create a subscription that automatically manages lifecycle
  StreamSubscription<T> subscribe<T>(
    String eventKey,
    void Function(T data) onData, {
    bool replay = false,
    Function(Object error)? onError,
  }) {
    return onEvent<T>(eventKey, replay: replay).listen(
      onData,
      onError: onError,
    );
  }

  /// Get statistics about communication
  Map<String, dynamic> getStatistics() {
    final eventBusStats = _eventBus.getStatistics();
    
    return {
      'registeredBlocs': _registeredBlocs.length,
      'blocKeys': _registeredBlocs.keys.toList(),
      'eventBus': eventBusStats,
    };
  }

  /// Reset all communication (useful for testing)
  Future<void> reset() async {
    _registeredBlocs.clear();
    await _eventBus.reset();
    
    if (kDebugMode) {
      debugPrint('[CrossBlocCommunication] Reset complete');
    }
  }

  /// Dispose the communication system
  Future<void> dispose() async {
    await reset();
    await _eventBus.dispose();
    _instance = null;
  }
}

/// Mixin to add cross-BLoC communication capabilities to any BLoC
mixin CrossBlocCommunicationMixin<E, S> on BlocBase<S> {
  final List<StreamSubscription> _communicationSubscriptions = [];
  final CrossBlocCommunication _communication = CrossBlocCommunication.instance;

  /// Emit a cross-BLoC event
  void emitCrossBlocEvent<T>(String eventKey, T data, {bool replay = false}) {
    _communication.emitEvent(eventKey, data, replay: replay);
  }

  /// Subscribe to cross-BLoC events
  StreamSubscription<T> subscribeToCrossBlocEvents<T>(
    void Function(T data) onData, {
    String? eventKey,
    bool replay = false,
    Function(Object error)? onError,
  }) {
    final key = eventKey ?? T.toString().toLowerCase();
    final subscription = _communication.subscribe<T>(
      key,
      onData,
      replay: replay,
      onError: onError,
    );

    _communicationSubscriptions.add(subscription);
    return subscription;
  }

  /// Send a direct message to another BLoC
  void sendToBloC<T>({
    required String to,
    required T event,
    String? from,
  }) {
    final fromKey = from ?? runtimeType.toString().toLowerCase();
    _communication.sendMessage(from: fromKey, to: to, event: event);
  }

  /// Broadcast an event to all compatible BLoCs
  void broadcastToBLoCs<T>(T event) {
    final excludeKey = runtimeType.toString().toLowerCase();
    _communication.broadcastEvent(event, excludeKey: excludeKey);
  }

  /// Listen to events from a specific BLoC
  StreamSubscription<T> listenToBloC<T>(
    String eventKey,
    void Function(T data) onData, {
    bool replay = false,
  }) {
    final subscription = _communication.onEvent<T>(eventKey, replay: replay).listen(onData);
    _communicationSubscriptions.add(subscription);
    return subscription;
  }

  /// Check if there are active subscriptions
  bool get hasActiveSubscriptions => _communicationSubscriptions.isNotEmpty;

  /// Get the number of active subscriptions
  int get activeSubscriptionCount => _communicationSubscriptions.length;

  @override
  Future<void> close() async {
    // Cancel all communication subscriptions
    final futures = _communicationSubscriptions.map((s) => s.cancel());
    await Future.wait(futures);
    _communicationSubscriptions.clear();

    return super.close();
  }
}

/// Extension for easy BLoC registration
extension BlocRegistrationExtension on BlocBase {
  /// Register this BLoC for cross-communication
  void registerForCommunication([String? key]) {
    final registrationKey = key ?? runtimeType.toString().toLowerCase();
    CrossBlocCommunication.instance.registerBloc(registrationKey, this);
  }

  /// Unregister this BLoC from cross-communication
  void unregisterFromCommunication([String? key]) {
    final registrationKey = key ?? runtimeType.toString().toLowerCase();
    CrossBlocCommunication.instance.unregisterBloc(registrationKey);
  }
}

/// Specialized events for cross-BLoC communication
abstract class CrossBlocEvent {}

/// Event to request data from another BLoC
class DataRequestEvent extends CrossBlocEvent {
  final String requestId;
  final String dataType;
  final Map<String, dynamic> parameters;

  DataRequestEvent({
    required this.requestId,
    required this.dataType,
    this.parameters = const {},
  });
}

/// Event to provide data to other BLoCs
class DataResponseEvent extends CrossBlocEvent {
  final String requestId;
  final String dataType;
  final dynamic data;
  final bool success;
  final String? error;

  DataResponseEvent({
    required this.requestId,
    required this.dataType,
    required this.data,
    this.success = true,
    this.error,
  });
}

/// Event to notify state changes to other BLoCs
class StateChangeNotificationEvent extends CrossBlocEvent {
  final String sourceBloc;
  final String stateType;
  final dynamic state;
  final DateTime timestamp;

  StateChangeNotificationEvent({
    required this.sourceBloc,
    required this.stateType,
    required this.state,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Event for coordinated actions between BLoCs
class CoordinatedActionEvent extends CrossBlocEvent {
  final String actionType;
  final Map<String, dynamic> payload;
  final List<String> targetBlocs;
  final String initiatorBloc;

  CoordinatedActionEvent({
    required this.actionType,
    required this.payload,
    required this.targetBlocs,
    required this.initiatorBloc,
  });
}