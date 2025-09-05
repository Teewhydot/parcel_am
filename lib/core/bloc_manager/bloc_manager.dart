import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc_manager_config.dart';
import 'bloc_lifecycle_observer.dart';
import 'plugins/bloc_manager_plugin.dart';

/// A comprehensive BLoC manager that provides centralized lifecycle management,
/// enhanced error handling, and better developer experience for TravelLink.
class BlocManager<T extends BlocBase<S>, S> extends StatefulWidget {
  /// Configuration for the BlocManager
  final BlocManagerConfig config;
  
  /// Factory function to create the BLoC
  final T Function(BuildContext context) create;
  
  /// Optional plugins to extend functionality
  final List<BlocManagerPlugin>? plugins;
  
  /// Optional lifecycle observer
  final BlocLifecycleObserver? lifecycleObserver;
  
  /// Whether to register the BLoC with dependency injection
  final bool registerWithDI;
  
  /// Optional callback when BLoC is disposed
  final VoidCallback? onDispose;
  
  /// Optional error builder for error states
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  
  /// The child widget
  final Widget child;
  
  /// Optional listener for state changes
  final void Function(BuildContext context, S state)? listener;
  
  /// Whether to lazily create the BLoC
  final bool lazy;

  const BlocManager({
    Key? key,
    required this.config,
    required this.create,
    required this.child,
    this.plugins,
    this.lifecycleObserver,
    this.registerWithDI = false,
    this.onDispose,
    this.errorBuilder,
    this.listener,
    this.lazy = false,
  }) : super(key: key);

  @override
  State<BlocManager<T, S>> createState() => _BlocManagerState<T, S>();
}

class _BlocManagerState<T extends BlocBase<S>, S> extends State<BlocManager<T, S>> {
  late T _bloc;
  bool _isInitialized = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.lazy) {
      _initializeBloc();
    }
  }

  void _initializeBloc() {
    try {
      _bloc = widget.create(context);
      _isInitialized = true;

      // Register with dependency injection if requested
      if (widget.registerWithDI) {
        widget.config.getIt.registerSingleton<T>(_bloc);
      }

      // Notify lifecycle observer
      widget.lifecycleObserver?.onBlocCreated(_bloc);

      // Initialize plugins
      widget.plugins?.forEach((plugin) {
        plugin.onBlocCreated(_bloc, widget.config);
      });

      // Set up state listener for plugins
      if (widget.plugins != null && widget.plugins!.isNotEmpty) {
        _bloc.stream.listen((state) {
          for (final plugin in widget.plugins!) {
            plugin.onStateChange(_bloc, null, state);
          }
        });
      }

      // Enable logging if configured
      if (widget.config.enableLogging) {
        _bloc.stream.listen((state) {
          debugPrint('[BlocManager] ${T.toString()} state changed to: ${state.runtimeType}');
        });
      }

      // Performance monitoring
      if (widget.config.enablePerformanceMonitoring) {
        final stopwatch = Stopwatch();
        _bloc.stream.listen((state) {
          if (stopwatch.isRunning) {
            debugPrint('[BlocManager] State transition took: ${stopwatch.elapsedMilliseconds}ms');
            stopwatch.reset();
          }
          stopwatch.start();
        });
      }
    } catch (e, stackTrace) {
      _error = e;
      if (widget.config.enableLogging) {
        debugPrint('[BlocManager] Error creating BLoC: $e\n$stackTrace');
      }
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      // Notify lifecycle observer
      widget.lifecycleObserver?.onBlocDisposed(_bloc);

      // Notify plugins
      widget.plugins?.forEach((plugin) {
        plugin.onBlocDisposed(_bloc);
      });

      // Unregister from dependency injection
      if (widget.registerWithDI && widget.config.getIt.isRegistered<T>()) {
        widget.config.getIt.unregister<T>();
      }

      // Call custom dispose callback
      widget.onDispose?.call();

      // Close the BLoC
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle initialization error
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error!);
    }

    // If there's an error but no error builder, throw it
    if (_error != null) {
      throw _error!;
    }

    // For lazy loading, use BlocProvider.create instead of value
    if (widget.lazy && !_isInitialized) {
      return BlocProvider<T>(
        create: (context) {
          _initializeBloc();
          return _bloc;
        },
        child: widget.listener != null
            ? BlocListener<T, S>(
                listener: widget.listener!,
                child: widget.child,
              )
            : widget.child,
      );
    }

    // For eager loading or already initialized lazy loading
    return BlocProvider<T>.value(
      value: _bloc,
      child: widget.listener != null
          ? BlocListener<T, S>(
              listener: widget.listener!,
              child: widget.child,
            )
          : widget.child,
    );
  }
}

/// Extension methods for BlocManager
extension BlocManagerExtensions on BuildContext {
  /// Get a BLoC from the nearest BlocManager
  T getBloc<T extends BlocBase<Object?>>() {
    try {
      return read<T>();
    } catch (e) {
      throw FlutterError(
        'BlocManager: Could not find BLoC of type $T in the widget tree.\n'
        'Make sure you have a BlocManager<$T, State> as an ancestor widget.',
      );
    }
  }

  /// Watch a BLoC state from the nearest BlocManager
  S watchBloc<T extends BlocBase<S>, S>() {
    try {
      return watch<T>().state;
    } catch (e) {
      throw FlutterError(
        'BlocManager: Could not watch BLoC of type $T in the widget tree.\n'
        'Make sure you have a BlocManager<$T, $S> as an ancestor widget.',
      );
    }
  }

  /// Select a specific part of a BLoC state
  R selectBloc<T extends BlocBase<S>, S, R>(R Function(S state) selector) {
    try {
      return select<T, R>((bloc) => selector(bloc.state));
    } catch (e) {
      throw FlutterError(
        'BlocManager: Could not select from BLoC of type $T in the widget tree.\n'
        'Make sure you have a BlocManager<$T, $S> as an ancestor widget.',
      );
    }
  }
}