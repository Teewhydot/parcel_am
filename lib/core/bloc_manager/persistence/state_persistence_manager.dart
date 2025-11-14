import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'error_recovery_strategy.dart';

/// Manager for persisting and restoring BLoC states
class StatePersistenceManager {
  final FlutterSecureStorage _storage;
  final ErrorRecoveryStrategy _errorRecoveryStrategy;
  final String _keyPrefix;
  final Duration _cacheTimeout;
  
  // In-memory cache for frequently accessed states
  final Map<String, _CachedState> _cache = {};

  StatePersistenceManager({
    FlutterSecureStorage? storage,
    ErrorRecoveryStrategy? errorRecoveryStrategy,
    String keyPrefix = 'bloc_state_',
    Duration cacheTimeout = const Duration(minutes: 10),
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _errorRecoveryStrategy = errorRecoveryStrategy ?? ExponentialBackoffStrategy(),
       _keyPrefix = keyPrefix,
       _cacheTimeout = cacheTimeout;

  /// Save state to secure storage with error recovery
  Future<void> saveState<T extends Object>({
    required String key,
    required T state,
    required Map<String, dynamic> Function(T state) serializer,
    bool Function(T state)? validator,
    bool useCache = true,
  }) async {
    try {
      // Validate state if validator is provided
      if (validator != null && !validator(state)) {
        debugPrint('[StatePersistenceManager] State validation failed for key: $key');
        return;
      }

      await _errorRecoveryStrategy.execute(() async {
        final serializedData = serializer(state);
        final jsonString = jsonEncode({
          'data': serializedData,
          'timestamp': DateTime.now().toIso8601String(),
          'version': 1,
        });

        final fullKey = '$_keyPrefix$key';
        await _storage.write(key: fullKey, value: jsonString);

        // Update cache
        if (useCache) {
          _cache[key] = _CachedState(
            data: state,
            timestamp: DateTime.now(),
          );
        }

        debugPrint('[StatePersistenceManager] State saved successfully for key: $key');
      });
    } catch (e, stackTrace) {
      debugPrint('[StatePersistenceManager] Failed to save state for key: $key - $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Restore state from secure storage with error recovery
  Future<T?> restoreState<T extends Object>({
    required String key,
    required T Function(Map<String, dynamic> data) deserializer,
    bool useCache = true,
  }) async {
    try {
      // Check cache first
      if (useCache && _cache.containsKey(key)) {
        final cached = _cache[key]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheTimeout) {
          debugPrint('[StatePersistenceManager] State restored from cache for key: $key');
          return cached.data as T;
        } else {
          // Remove expired cache entry
          _cache.remove(key);
        }
      }

      return await _errorRecoveryStrategy.execute<T?>(() async {
        final fullKey = '$_keyPrefix$key';
        final jsonString = await _storage.read(key: fullKey);

        if (jsonString == null) {
          debugPrint('[StatePersistenceManager] No saved state found for key: $key');
          return null;
        }

        final decodedData = jsonDecode(jsonString) as Map<String, dynamic>;
        final stateData = decodedData['data'] as Map<String, dynamic>;
        final timestamp = DateTime.tryParse(decodedData['timestamp'] as String? ?? '');
        final version = decodedData['version'] as int? ?? 1;

        // Check if state is too old (optional)
        if (timestamp != null && DateTime.now().difference(timestamp).inDays > 30) {
          debugPrint('[StatePersistenceManager] Saved state is too old, ignoring for key: $key');
          await clearState(key);
          return null;
        }

        final restoredState = deserializer(stateData);

        // Update cache
        if (useCache) {
          _cache[key] = _CachedState(
            data: restoredState,
            timestamp: DateTime.now(),
          );
        }

        debugPrint('[StatePersistenceManager] State restored successfully for key: $key (version: $version)');
        return restoredState;
      });
    } catch (e, stackTrace) {
      debugPrint('[StatePersistenceManager] Failed to restore state for key: $key - $e');
      debugPrint('Stack trace: $stackTrace');
      return null; // Return null instead of throwing for restore operations
    }
  }

  /// Clear a specific state
  Future<void> clearState(String key) async {
    try {
      await _errorRecoveryStrategy.execute(() async {
        final fullKey = '$_keyPrefix$key';
        await _storage.delete(key: fullKey);
        _cache.remove(key);
        debugPrint('[StatePersistenceManager] State cleared for key: $key');
      });
    } catch (e, stackTrace) {
      debugPrint('[StatePersistenceManager] Failed to clear state for key: $key - $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Clear all states with a specific prefix
  Future<void> clearAllStatesWithPrefix(String prefix) async {
    try {
      await _errorRecoveryStrategy.execute(() async {
        final fullPrefix = '$_keyPrefix$prefix';
        final allKeys = await _storage.readAll();
        
        final keysToDelete = allKeys.keys
            .where((key) => key.startsWith(fullPrefix))
            .toList();

        for (final key in keysToDelete) {
          await _storage.delete(key: key);
          // Remove from cache (extract original key)
          final originalKey = key.substring(_keyPrefix.length);
          _cache.remove(originalKey);
        }

        debugPrint('[StatePersistenceManager] Cleared ${keysToDelete.length} states with prefix: $prefix');
      });
    } catch (e, stackTrace) {
      debugPrint('[StatePersistenceManager] Failed to clear states with prefix: $prefix - $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Clear all saved states
  Future<void> clearAllStates() async {
    try {
      await _errorRecoveryStrategy.execute(() async {
        final allKeys = await _storage.readAll();
        
        final keysToDelete = allKeys.keys
            .where((key) => key.startsWith(_keyPrefix))
            .toList();

        for (final key in keysToDelete) {
          await _storage.delete(key: key);
        }

        _cache.clear();
        debugPrint('[StatePersistenceManager] Cleared all ${keysToDelete.length} saved states');
      });
    } catch (e, stackTrace) {
      debugPrint('[StatePersistenceManager] Failed to clear all states - $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get information about saved states
  Future<Map<String, StateInfo>> getStateInfo() async {
    try {
      return await _errorRecoveryStrategy.execute(() async {
        final allKeys = await _storage.readAll();
        final stateInfo = <String, StateInfo>{};

        for (final entry in allKeys.entries) {
          final key = entry.key;
          final value = entry.value;

          if (!key.startsWith(_keyPrefix)) continue;

          try {
            final decodedData = jsonDecode(value) as Map<String, dynamic>;
            final timestamp = DateTime.tryParse(decodedData['timestamp'] as String? ?? '');
            final version = decodedData['version'] as int? ?? 1;

            final originalKey = key.substring(_keyPrefix.length);
            stateInfo[originalKey] = StateInfo(
              key: originalKey,
              timestamp: timestamp,
              version: version,
              sizeBytes: value.length,
              isCached: _cache.containsKey(originalKey),
            );
          } catch (e) {
            // Skip corrupted entries
            debugPrint('[StatePersistenceManager] Corrupted state data for key: $key');
          }
        }

        return stateInfo;
      });
    } catch (e, stackTrace) {
      debugPrint('[StatePersistenceManager] Failed to get state info - $e');
      debugPrint('Stack trace: $stackTrace');
      return {};
    }
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cache.entries
        .where((entry) => now.difference(entry.value.timestamp) > _cacheTimeout)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('[StatePersistenceManager] Cleared ${expiredKeys.length} expired cache entries');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'totalEntries': _cache.length,
      'cacheTimeout': _cacheTimeout.toString(),
      'entries': _cache.entries.map((e) => {
        'key': e.key,
        'timestamp': e.value.timestamp.toIso8601String(),
        'age': DateTime.now().difference(e.value.timestamp).toString(),
      }).toList(),
    };
  }

  /// Dispose resources
  void dispose() {
    _cache.clear();
  }
}

/// Information about a saved state
class StateInfo {
  final String key;
  final DateTime? timestamp;
  final int version;
  final int sizeBytes;
  final bool isCached;

  const StateInfo({
    required this.key,
    this.timestamp,
    required this.version,
    required this.sizeBytes,
    required this.isCached,
  });

  @override
  String toString() {
    return 'StateInfo(key: $key, timestamp: $timestamp, version: $version, '
           'size: $sizeBytes bytes, cached: $isCached)';
  }
}

/// Cached state entry
class _CachedState {
  final Object data;
  final DateTime timestamp;

  const _CachedState({
    required this.data,
    required this.timestamp,
  });
}