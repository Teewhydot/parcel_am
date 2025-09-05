import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc_manager_config.dart';

/// Base interface for BlocManager plugins
abstract class BlocManagerPlugin {
  /// Plugin name for identification
  String get name;
  
  /// Plugin version
  String get version;
  
  /// Called when a BLoC is created
  Future<void> onBlocCreated(BlocBase bloc, BlocManagerConfig config);
  
  /// Called when a BLoC is disposed
  Future<void> onBlocDisposed(BlocBase bloc);
  
  /// Called when a BLoC state changes
  Future<void> onStateChange(BlocBase bloc, Object? previousState, Object? newState);
  
  /// Called when a BLoC encounters an error
  Future<void> onError(BlocBase bloc, Object error, StackTrace stackTrace);
  
  /// Initialize the plugin
  Future<void> initialize();
  
  /// Dispose the plugin
  Future<void> dispose();
}

/// Base implementation of BlocManagerPlugin with default behaviors
abstract class BaseBlocManagerPlugin implements BlocManagerPlugin {
  @override
  String get version => '1.0.0';

  @override
  Future<void> onBlocCreated(BlocBase bloc, BlocManagerConfig config) async {
    // Default implementation - override if needed
  }

  @override
  Future<void> onBlocDisposed(BlocBase bloc) async {
    // Default implementation - override if needed
  }

  @override
  Future<void> onStateChange(BlocBase bloc, Object? previousState, Object? newState) async {
    // Default implementation - override if needed
  }

  @override
  Future<void> onError(BlocBase bloc, Object error, StackTrace stackTrace) async {
    // Default implementation - override if needed
  }

  @override
  Future<void> initialize() async {
    // Default implementation - override if needed
  }

  @override
  Future<void> dispose() async {
    // Default implementation - override if needed
  }
}

/// Logging plugin for BlocManager
class LoggingPlugin extends BaseBlocManagerPlugin {
  final bool enableVerboseLogging;
  final void Function(String message)? customLogger;

  LoggingPlugin({
    this.enableVerboseLogging = false,
    this.customLogger,
  });

  @override
  String get name => 'LoggingPlugin';

  void _log(String message) {
    if (customLogger != null) {
      customLogger!(message);
    } else {
      print('[BlocManager] $message');
    }
  }

  @override
  Future<void> onBlocCreated(BlocBase bloc, BlocManagerConfig config) async {
    _log('BLoC ${bloc.runtimeType} created');
  }

  @override
  Future<void> onBlocDisposed(BlocBase bloc) async {
    _log('BLoC ${bloc.runtimeType} disposed');
  }

  @override
  Future<void> onStateChange(BlocBase bloc, Object? previousState, Object? newState) async {
    if (enableVerboseLogging) {
      _log('BLoC ${bloc.runtimeType} state changed: ${previousState?.runtimeType} -> ${newState?.runtimeType}');
    }
  }

  @override
  Future<void> onError(BlocBase bloc, Object error, StackTrace stackTrace) async {
    _log('BLoC ${bloc.runtimeType} error: $error');
    if (enableVerboseLogging) {
      _log('Stack trace: $stackTrace');
    }
  }
}

/// Performance monitoring plugin for BlocManager
class PerformancePlugin extends BaseBlocManagerPlugin {
  final Map<BlocBase, DateTime> _blocCreationTimes = {};
  final Map<BlocBase, int> _stateChangeCount = {};
  final Map<BlocBase, List<Duration>> _stateChangeTimes = {};

  @override
  String get name => 'PerformancePlugin';

  @override
  Future<void> onBlocCreated(BlocBase bloc, BlocManagerConfig config) async {
    _blocCreationTimes[bloc] = DateTime.now();
    _stateChangeCount[bloc] = 0;
    _stateChangeTimes[bloc] = [];
  }

  @override
  Future<void> onBlocDisposed(BlocBase bloc) async {
    final lifespan = DateTime.now().difference(_blocCreationTimes[bloc]!);
    final stateChanges = _stateChangeCount[bloc] ?? 0;
    
    print('[Performance] BLoC ${bloc.runtimeType}:');
    print('  Lifespan: ${lifespan.inMilliseconds}ms');
    print('  State changes: $stateChanges');
    
    if (stateChanges > 0) {
      final avgTime = _calculateAverageStateChangeTime(bloc);
      print('  Average state change time: ${avgTime?.inMilliseconds ?? 0}ms');
    }
    
    _blocCreationTimes.remove(bloc);
    _stateChangeCount.remove(bloc);
    _stateChangeTimes.remove(bloc);
  }

  @override
  Future<void> onStateChange(BlocBase bloc, Object? previousState, Object? newState) async {
    _stateChangeCount[bloc] = (_stateChangeCount[bloc] ?? 0) + 1;
    
    // Measure time between state changes
    if (_stateChangeTimes[bloc]!.isNotEmpty) {
      final lastTime = _stateChangeTimes[bloc]!.last;
      final now = DateTime.now();
      final timeSinceCreation = now.difference(_blocCreationTimes[bloc]!);
      _stateChangeTimes[bloc]!.add(timeSinceCreation);
    } else {
      _stateChangeTimes[bloc]!.add(Duration.zero);
    }
  }

  Duration? _calculateAverageStateChangeTime(BlocBase bloc) {
    final times = _stateChangeTimes[bloc];
    if (times == null || times.isEmpty) return null;
    
    final totalMs = times.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ times.length);
  }

  /// Get performance statistics for all tracked BLoCs
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};
    
    for (final entry in _blocCreationTimes.entries) {
      final bloc = entry.key;
      final creationTime = entry.value;
      final stateChanges = _stateChangeCount[bloc] ?? 0;
      final avgTime = _calculateAverageStateChangeTime(bloc);
      
      stats[bloc.runtimeType.toString()] = {
        'created': creationTime.toIso8601String(),
        'stateChanges': stateChanges,
        'averageStateChangeTime': avgTime?.inMilliseconds,
        'isActive': !bloc.isClosed,
      };
    }
    
    return stats;
  }
}