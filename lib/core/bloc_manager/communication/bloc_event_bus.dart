import 'dart:async';
import 'package:flutter/foundation.dart';

/// A singleton event bus for cross-BLoC communication
class BlocEventBus {
  static BlocEventBus? _instance;
  static BlocEventBus get instance => _instance ??= BlocEventBus._();

  BlocEventBus._();

  // Event streams for different event types
  final Map<String, StreamController<dynamic>> _controllers = {};
  
  // Subscription tracking
  final Map<String, List<StreamSubscription>> _subscriptions = {};
  
  // Event replay support
  final Map<String, dynamic> _lastEvents = {};
  final Set<String> _replayableEvents = {};
  
  // Statistics
  int _totalEventsEmitted = 0;
  final Map<String, int> _eventCounts = {};

  /// Emit an event to all subscribers
  void emit<T>(String eventKey, T data, {bool replay = false}) {
    try {
      if (replay) {
        _replayableEvents.add(eventKey);
        _lastEvents[eventKey] = data;
      }

      final controller = _getOrCreateController<T>(eventKey);
      controller.add(data);

      _totalEventsEmitted++;
      _eventCounts[eventKey] = (_eventCounts[eventKey] ?? 0) + 1;

      if (kDebugMode) {
        debugPrint('[BlocEventBus] Event emitted: $eventKey (type: ${T.toString()})');
      }
    } catch (e, stackTrace) {
      debugPrint('[BlocEventBus] Error emitting event $eventKey: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Subscribe to events of a specific type
  Stream<T> on<T>(String eventKey, {bool replay = false}) {
    try {
      final controller = _getOrCreateController<T>(eventKey);
      Stream<T> stream = controller.stream.where((data) => data is T).cast<T>();

      // Handle replay if requested and available
      if (replay && _replayableEvents.contains(eventKey) && _lastEvents.containsKey(eventKey)) {
        final lastEvent = _lastEvents[eventKey];
        if (lastEvent is T) {
          // Create a stream that emits the last event first, then continues with live events
          final replayController = StreamController<T>();
          replayController.add(lastEvent);
          stream.listen(
            (data) => replayController.add(data),
            onError: (error) => replayController.addError(error),
            onDone: () => replayController.close(),
          );
          stream = replayController.stream;
        }
      }

      if (kDebugMode) {
        debugPrint('[BlocEventBus] Subscriber added for: $eventKey (type: ${T.toString()})');
      }

      return stream;
    } catch (e, stackTrace) {
      debugPrint('[BlocEventBus] Error subscribing to event $eventKey: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Stream.empty();
    }
  }

  /// Check if there are active subscriptions for an event
  bool hasSubscriptions(String eventKey) {
    final controller = _controllers[eventKey];
    return controller != null && controller.hasListener;
  }

  /// Get or create a stream controller for an event
  StreamController<dynamic> _getOrCreateController<T>(String eventKey) {
    if (!_controllers.containsKey(eventKey)) {
      final controller = StreamController<dynamic>.broadcast();
      
      // Auto-cleanup when no more listeners
      controller.onCancel = () {
        if (!controller.hasListener) {
          _cleanupController(eventKey);
        }
      };

      _controllers[eventKey] = controller;
    }
    
    return _controllers[eventKey]!;
  }

  /// Clean up controller when no longer needed
  void _cleanupController(String eventKey) {
    final controller = _controllers[eventKey];
    if (controller != null && !controller.hasListener) {
      controller.close();
      _controllers.remove(eventKey);
      _subscriptions.remove(eventKey);
      
      if (kDebugMode) {
        debugPrint('[BlocEventBus] Controller cleaned up for: $eventKey');
      }
    }
  }

  /// Remove a specific event and its controller
  Future<void> removeEvent(String eventKey) async {
    final controller = _controllers[eventKey];
    if (controller != null) {
      await controller.close();
      _controllers.remove(eventKey);
    }
    
    final subscriptions = _subscriptions[eventKey];
    if (subscriptions != null) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.remove(eventKey);
    }

    _lastEvents.remove(eventKey);
    _replayableEvents.remove(eventKey);
    _eventCounts.remove(eventKey);

    if (kDebugMode) {
      debugPrint('[BlocEventBus] Event removed: $eventKey');
    }
  }

  /// Get statistics about the event bus
  Map<String, dynamic> getStatistics() {
    int activeSubscriptions = 0;
    for (final controller in _controllers.values) {
      if (controller.hasListener) {
        activeSubscriptions++;
      }
    }

    return {
      'totalEventsEmitted': _totalEventsEmitted,
      'activeControllers': _controllers.length,
      'activeSubscriptions': activeSubscriptions,
      'uniqueEvents': _eventCounts.length,
      'eventCounts': Map<String, int>.from(_eventCounts),
      'replayableEvents': Set<String>.from(_replayableEvents),
    };
  }

  /// Reset the event bus (useful for testing)
  Future<void> reset() async {
    final futures = <Future>[];
    
    // Close all controllers
    for (final controller in _controllers.values) {
      futures.add(controller.close());
    }
    
    // Cancel all subscriptions
    for (final subscriptions in _subscriptions.values) {
      for (final subscription in subscriptions) {
        futures.add(subscription.cancel());
      }
    }

    await Future.wait(futures);

    _controllers.clear();
    _subscriptions.clear();
    _lastEvents.clear();
    _replayableEvents.clear();
    _eventCounts.clear();
    _totalEventsEmitted = 0;

    if (kDebugMode) {
      debugPrint('[BlocEventBus] Reset complete');
    }
  }

  /// Dispose the event bus
  Future<void> dispose() async {
    await reset();
    _instance = null;
  }

  /// Get all active event keys
  Set<String> getActiveEventKeys() {
    return Set<String>.from(_controllers.keys);
  }

  /// Check if an event key is active
  bool isEventActive(String eventKey) {
    return _controllers.containsKey(eventKey);
  }

  /// Get the last emitted value for a replayable event
  T? getLastEvent<T>(String eventKey) {
    final lastEvent = _lastEvents[eventKey];
    return lastEvent is T ? lastEvent : null;
  }

  /// Enable/disable replay for an existing event
  void setReplay(String eventKey, bool enable) {
    if (enable) {
      _replayableEvents.add(eventKey);
    } else {
      _replayableEvents.remove(eventKey);
      _lastEvents.remove(eventKey);
    }
  }

  /// Create a filtered stream for specific conditions
  Stream<T> where<T>(String eventKey, bool Function(T) test) {
    return on<T>(eventKey).where(test);
  }

  /// Create a transformed stream
  Stream<R> map<T, R>(String eventKey, R Function(T) mapper) {
    return on<T>(eventKey).map(mapper);
  }

  /// Create a debounced stream
  Stream<T> debounce<T>(String eventKey, Duration duration) {
    StreamController<T>? controller;
    Timer? timer;

    controller = StreamController<T>(
      onListen: () {
        on<T>(eventKey).listen((data) {
          timer?.cancel();
          timer = Timer(duration, () {
            if (!controller!.isClosed) {
              controller.add(data);
            }
          });
        });
      },
      onCancel: () {
        timer?.cancel();
        controller?.close();
      },
    );

    return controller.stream;
  }

  /// Create a throttled stream
  Stream<T> throttle<T>(String eventKey, Duration duration) {
    StreamController<T>? controller;
    Timer? timer;
    bool canEmit = true;

    controller = StreamController<T>(
      onListen: () {
        on<T>(eventKey).listen((data) {
          if (canEmit && !controller!.isClosed) {
            controller.add(data);
            canEmit = false;
            timer = Timer(duration, () {
              canEmit = true;
            });
          }
        });
      },
      onCancel: () {
        timer?.cancel();
        controller?.close();
      },
    );

    return controller.stream;
  }
}