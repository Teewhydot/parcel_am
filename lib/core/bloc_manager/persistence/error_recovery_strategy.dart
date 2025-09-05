import 'dart:math';
import 'package:flutter/foundation.dart';

/// Base interface for error recovery strategies
abstract class ErrorRecoveryStrategy {
  /// Execute an operation with error recovery
  Future<T> execute<T>(Future<T> Function() operation);
}

/// Exponential backoff retry strategy
class ExponentialBackoffStrategy implements ErrorRecoveryStrategy {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double multiplier;
  final double jitterFactor;

  const ExponentialBackoffStrategy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 200),
    this.maxDelay = const Duration(seconds: 30),
    this.multiplier = 2.0,
    this.jitterFactor = 0.1,
  });

  @override
  Future<T> execute<T>(Future<T> Function() operation) async {
    int attempts = 0;
    Duration currentDelay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          debugPrint('[ExponentialBackoffStrategy] Max retries ($maxRetries) exceeded');
          rethrow;
        }

        // Calculate delay with jitter
        final jitter = currentDelay.inMilliseconds * jitterFactor * (Random().nextDouble() - 0.5);
        final delayMs = currentDelay.inMilliseconds + jitter.round();
        final actualDelay = Duration(milliseconds: delayMs.clamp(0, maxDelay.inMilliseconds));

        debugPrint('[ExponentialBackoffStrategy] Retry $attempts/$maxRetries after ${actualDelay.inMilliseconds}ms - Error: $e');
        
        await Future.delayed(actualDelay);
        
        // Increase delay for next attempt
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * multiplier).round()
        );
        if (currentDelay > maxDelay) {
          currentDelay = maxDelay;
        }
      }
    }

    throw StateError('This should never be reached');
  }
}

/// Circuit breaker strategy that fails fast after consecutive failures
class CircuitBreakerStrategy implements ErrorRecoveryStrategy {
  final int failureThreshold;
  final Duration timeout;
  
  int _consecutiveFailures = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  CircuitBreakerStrategy({
    this.failureThreshold = 5,
    this.timeout = const Duration(minutes: 1),
  });

  @override
  Future<T> execute<T>(Future<T> Function() operation) async {
    // Check if circuit is open
    if (_isOpen) {
      final now = DateTime.now();
      if (_lastFailureTime != null && 
          now.difference(_lastFailureTime!) < timeout) {
        throw CircuitBreakerOpenException(
          'Circuit breaker is open. Last failure: $_lastFailureTime'
        );
      } else {
        // Try to close circuit (half-open state)
        _isOpen = false;
        debugPrint('[CircuitBreakerStrategy] Circuit breaker entering half-open state');
      }
    }

    try {
      final result = await operation();
      
      // Success - reset failure count
      if (_consecutiveFailures > 0) {
        debugPrint('[CircuitBreakerStrategy] Operation succeeded, resetting failure count');
        _consecutiveFailures = 0;
        _lastFailureTime = null;
      }
      
      return result;
    } catch (e) {
      _consecutiveFailures++;
      _lastFailureTime = DateTime.now();
      
      if (_consecutiveFailures >= failureThreshold) {
        _isOpen = true;
        debugPrint('[CircuitBreakerStrategy] Circuit breaker opened after $failureThreshold failures');
      }
      
      debugPrint('[CircuitBreakerStrategy] Failure $_consecutiveFailures/$failureThreshold - $e');
      rethrow;
    }
  }

  /// Check if circuit is currently open
  bool get isOpen => _isOpen;

  /// Get current failure count
  int get consecutiveFailures => _consecutiveFailures;

  /// Reset the circuit breaker
  void reset() {
    _consecutiveFailures = 0;
    _lastFailureTime = null;
    _isOpen = false;
    debugPrint('[CircuitBreakerStrategy] Circuit breaker reset');
  }
}

/// Retry strategy with fallback
class RetryWithFallbackStrategy<T> implements ErrorRecoveryStrategy {
  final int maxRetries;
  final Duration delay;
  final Future<T> Function() fallback;

  const RetryWithFallbackStrategy({
    this.maxRetries = 2,
    this.delay = const Duration(milliseconds: 500),
    required this.fallback,
  });

  @override
  Future<R> execute<R>(Future<R> Function() operation) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          debugPrint('[RetryWithFallbackStrategy] Max retries exceeded, using fallback');
          // For test purposes, we'll assume T and R are compatible
          final fallbackResult = await fallback();
          return fallbackResult as R;
        }

        debugPrint('[RetryWithFallbackStrategy] Retry $attempts/$maxRetries after ${delay.inMilliseconds}ms - Error: $e');
        await Future.delayed(delay);
      }
    }

    throw StateError('This should never be reached');
  }
}

/// No-operation strategy that doesn't retry
class NoRetryStrategy implements ErrorRecoveryStrategy {
  const NoRetryStrategy();

  @override
  Future<T> execute<T>(Future<T> Function() operation) async {
    return await operation();
  }
}

/// Composite strategy that tries multiple strategies in sequence
class CompositeErrorRecoveryStrategy implements ErrorRecoveryStrategy {
  final List<ErrorRecoveryStrategy> strategies;

  const CompositeErrorRecoveryStrategy({
    required this.strategies,
  });

  @override
  Future<T> execute<T>(Future<T> Function() operation) async {
    dynamic lastError;

    for (int i = 0; i < strategies.length; i++) {
      try {
        return await strategies[i].execute(operation);
      } catch (e) {
        lastError = e;
        debugPrint('[CompositeErrorRecoveryStrategy] Strategy ${i + 1}/${strategies.length} failed: $e');
        
        if (i == strategies.length - 1) {
          // Last strategy failed
          rethrow;
        }
      }
    }

    throw lastError;
  }
}

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException implements Exception {
  final String message;
  
  const CircuitBreakerOpenException(this.message);
  
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// Adaptive strategy that changes behavior based on error types
class AdaptiveErrorRecoveryStrategy implements ErrorRecoveryStrategy {
  final Map<Type, ErrorRecoveryStrategy> _strategyMap;
  final ErrorRecoveryStrategy _defaultStrategy;

  AdaptiveErrorRecoveryStrategy({
    required Map<Type, ErrorRecoveryStrategy> strategyMap,
    ErrorRecoveryStrategy? defaultStrategy,
  }) : _strategyMap = strategyMap,
       _defaultStrategy = defaultStrategy ?? const ExponentialBackoffStrategy();

  @override
  Future<T> execute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      final strategy = _strategyMap[e.runtimeType] ?? _defaultStrategy;
      debugPrint('[AdaptiveErrorRecoveryStrategy] Using ${strategy.runtimeType} for ${e.runtimeType}');
      return await strategy.execute(operation);
    }
  }

  /// Add or update strategy for a specific error type
  void setStrategyForError<E extends Object>(ErrorRecoveryStrategy strategy) {
    _strategyMap[E] = strategy;
  }

  /// Remove strategy for a specific error type
  void removeStrategyForError<E extends Object>() {
    _strategyMap.remove(E);
  }
}