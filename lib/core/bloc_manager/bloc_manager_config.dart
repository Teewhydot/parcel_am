import 'package:get_it/get_it.dart';

/// Configuration class for BlocManager
class BlocManagerConfig {
  /// GetIt instance for dependency injection
  final GetIt getIt;
  
  /// Whether to enable logging for state changes
  final bool enableLogging;
  
  /// Whether to enable performance monitoring
  final bool enablePerformanceMonitoring;
  
  /// Maximum memory cache size in MB (null for unlimited)
  final int? maxMemoryCache;
  
  /// Custom error handler
  final void Function(Object error, StackTrace stackTrace)? errorHandler;
  
  /// Whether to enable state persistence
  final bool enableStatePersistence;
  
  /// State persistence key prefix
  final String persistenceKeyPrefix;
  
  /// Whether to enable cross-bloc communication
  final bool enableCrossBlocCommunication;

  const BlocManagerConfig({
    required this.getIt,
    this.enableLogging = false,
    this.enablePerformanceMonitoring = false,
    this.maxMemoryCache,
    this.errorHandler,
    this.enableStatePersistence = false,
    this.persistenceKeyPrefix = 'bloc_state_',
    this.enableCrossBlocCommunication = false,
  });

  /// Create a copy with modified values
  BlocManagerConfig copyWith({
    GetIt? getIt,
    bool? enableLogging,
    bool? enablePerformanceMonitoring,
    int? maxMemoryCache,
    void Function(Object error, StackTrace stackTrace)? errorHandler,
    bool? enableStatePersistence,
    String? persistenceKeyPrefix,
    bool? enableCrossBlocCommunication,
  }) {
    return BlocManagerConfig(
      getIt: getIt ?? this.getIt,
      enableLogging: enableLogging ?? this.enableLogging,
      enablePerformanceMonitoring: enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
      maxMemoryCache: maxMemoryCache ?? this.maxMemoryCache,
      errorHandler: errorHandler ?? this.errorHandler,
      enableStatePersistence: enableStatePersistence ?? this.enableStatePersistence,
      persistenceKeyPrefix: persistenceKeyPrefix ?? this.persistenceKeyPrefix,
      enableCrossBlocCommunication: enableCrossBlocCommunication ?? this.enableCrossBlocCommunication,
    );
  }

  /// Create a development configuration with debugging enabled
  factory BlocManagerConfig.development({
    required GetIt getIt,
    int? maxMemoryCache,
  }) {
    return BlocManagerConfig(
      getIt: getIt,
      enableLogging: true,
      enablePerformanceMonitoring: true,
      maxMemoryCache: maxMemoryCache,
      enableStatePersistence: true,
      enableCrossBlocCommunication: true,
    );
  }

  /// Create a production configuration with optimizations
  factory BlocManagerConfig.production({
    required GetIt getIt,
    int? maxMemoryCache,
    void Function(Object error, StackTrace stackTrace)? errorHandler,
  }) {
    return BlocManagerConfig(
      getIt: getIt,
      enableLogging: false,
      enablePerformanceMonitoring: false,
      maxMemoryCache: maxMemoryCache ?? 50, // 50MB default cache
      errorHandler: errorHandler,
      enableStatePersistence: true,
      enableCrossBlocCommunication: true,
    );
  }

  /// Create a test configuration
  factory BlocManagerConfig.test({
    required GetIt getIt,
  }) {
    return BlocManagerConfig(
      getIt: getIt,
      enableLogging: false,
      enablePerformanceMonitoring: false,
      enableStatePersistence: false,
      enableCrossBlocCommunication: false,
    );
  }
}