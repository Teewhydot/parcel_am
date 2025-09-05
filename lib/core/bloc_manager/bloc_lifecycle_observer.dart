import 'package:flutter_bloc/flutter_bloc.dart';

/// Observer for BLoC lifecycle events
abstract class BlocLifecycleObserver {
  /// Called when a BLoC is created
  void onBlocCreated(BlocBase bloc);
  
  /// Called when a BLoC is disposed
  void onBlocDisposed(BlocBase bloc);
  
  /// Called when a BLoC encounters an error
  void onBlocError(BlocBase bloc, Object error, StackTrace stackTrace);
  
  /// Called when a BLoC state changes
  void onBlocStateChange(BlocBase bloc, Object? currentState, Object? nextState);
}

/// Default implementation of BlocLifecycleObserver
class DefaultBlocLifecycleObserver extends BlocLifecycleObserver {
  final Set<BlocBase> _activeBlocs = {};
  final Map<Type, int> _blocInstanceCount = {};
  final Map<Type, DateTime> _blocCreationTimes = {};
  
  /// Get the list of currently active BLoCs
  Set<BlocBase> get activeBlocs => Set.unmodifiable(_activeBlocs);
  
  /// Get the count of instances for each BLoC type
  Map<Type, int> get blocInstanceCount => Map.unmodifiable(_blocInstanceCount);
  
  /// Get the creation times for BLoC types
  Map<Type, DateTime> get blocCreationTimes => Map.unmodifiable(_blocCreationTimes);

  @override
  void onBlocCreated(BlocBase bloc) {
    _activeBlocs.add(bloc);
    final type = bloc.runtimeType;
    _blocInstanceCount[type] = (_blocInstanceCount[type] ?? 0) + 1;
    _blocCreationTimes[type] = DateTime.now();
  }

  @override
  void onBlocDisposed(BlocBase bloc) {
    _activeBlocs.remove(bloc);
    final type = bloc.runtimeType;
    if (_blocInstanceCount.containsKey(type)) {
      _blocInstanceCount[type] = _blocInstanceCount[type]! - 1;
      if (_blocInstanceCount[type]! <= 0) {
        _blocInstanceCount.remove(type);
        _blocCreationTimes.remove(type);
      }
    }
  }

  @override
  void onBlocError(BlocBase bloc, Object error, StackTrace stackTrace) {
    // Override in subclass to handle errors
  }

  @override
  void onBlocStateChange(BlocBase bloc, Object? currentState, Object? nextState) {
    // Override in subclass to handle state changes
  }
  
  /// Check for potential memory leaks
  List<String> checkForLeaks() {
    final leaks = <String>[];
    final now = DateTime.now();
    
    for (final entry in _blocCreationTimes.entries) {
      final age = now.difference(entry.value);
      if (age.inMinutes > 30) {
        final count = _blocInstanceCount[entry.key] ?? 0;
        if (count > 0) {
          leaks.add('${entry.key} has $count instances alive for ${age.inMinutes} minutes');
        }
      }
    }
    
    return leaks;
  }
  
  /// Dispose all active BLoCs (use with caution)
  Future<void> disposeAll() async {
    final blocsToDispose = List<BlocBase>.from(_activeBlocs);
    for (final bloc in blocsToDispose) {
      await bloc.close();
    }
    _activeBlocs.clear();
    _blocInstanceCount.clear();
    _blocCreationTimes.clear();
  }
  
  /// Get statistics about BLoC usage
  Map<String, dynamic> getStatistics() {
    return {
      'activeCount': _activeBlocs.length,
      'instanceCounts': _blocInstanceCount,
      'oldestBloc': _findOldestBloc(),
      'memoryLeaks': checkForLeaks(),
    };
  }
  
  String? _findOldestBloc() {
    if (_blocCreationTimes.isEmpty) return null;
    
    DateTime? oldest;
    String? oldestType;
    
    for (final entry in _blocCreationTimes.entries) {
      if (oldest == null || entry.value.isBefore(oldest)) {
        oldest = entry.value;
        oldestType = entry.key.toString();
      }
    }
    
    return oldestType;
  }
}