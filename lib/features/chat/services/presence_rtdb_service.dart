import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:parcel_am/core/utils/logger.dart' show Logger, LogTag;
import '../domain/entities/presence_entity.dart';

/// Service for real-time user presence using Firebase Realtime Database.
/// RTDB provides lower latency (~50ms) and automatic disconnect handling
/// compared to Firestore (~200-500ms).
///
/// RTDB Structure:
/// /presence/{userId} = {
///   status: "online" | "offline" | "away",
///   lastSeen: number (timestamp),
///   updatedAt: number (timestamp)
/// }
///
/// NOTE: All methods that require user identification accept userId as a parameter.
/// The userId should be obtained from context.currentUserId in the presentation layer.
class PresenceRtdbService {
  static final PresenceRtdbService _instance = PresenceRtdbService._internal();
  factory PresenceRtdbService() => _instance;
  PresenceRtdbService._internal();

  /// Lazily initialized database instance
  FirebaseDatabase? _database;

  /// Get the database instance, initializing if needed
  FirebaseDatabase get database {
    _database ??= FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://parcel-am-default-rtdb.europe-west1.firebasedatabase.app',
    );
    return _database!;
  }

  /// Reference to presence status in RTDB
  /// Structure: /presence/{userId} = { status, lastSeen, updatedAt }
  DatabaseReference _presenceRef(String userId) {
    return database.ref('presence/$userId');
  }

  /// Reference to the special .info/connected path
  /// This tells us if we're connected to RTDB
  DatabaseReference get _connectedRef => database.ref('.info/connected');

  // ============================================
  // Presence Operations
  // ============================================

  /// Set user as online with automatic offline on disconnect
  /// This is the main method to call when user becomes active
  /// [userId] should be obtained from context.currentUserId in presentation layer
  Future<void> setOnline(String userId) async {
    if (userId.isEmpty) {
      Logger.logWarning('setOnline: Empty userId provided', tag: LogTag.chat);
      return;
    }

    try {
      final ref = _presenceRef(userId);
      final now = ServerValue.timestamp;

      // Set current status to online
      await ref.update({
        'status': 'online',
        'updatedAt': now,
      });

      // Set up onDisconnect to automatically mark offline
      await ref.onDisconnect().update({
        'status': 'offline',
        'lastSeen': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      Logger.logSuccess(
        'setOnline: User $userId set to online with onDisconnect handler',
        tag: LogTag.chat,
      );
    } catch (e) {
      Logger.logError('setOnline failed: $e', tag: LogTag.chat);
    }
  }

  /// Set user as offline and update lastSeen
  /// Call this when user explicitly goes offline (logout, app background)
  /// [userId] should be obtained from context.currentUserId in presentation layer
  Future<void> setOffline(String userId) async {
    if (userId.isEmpty) {
      Logger.logWarning('setOffline: Empty userId provided', tag: LogTag.chat);
      return;
    }

    try {
      final ref = _presenceRef(userId);
      final now = ServerValue.timestamp;

      await ref.update({
        'status': 'offline',
        'lastSeen': now,
        'updatedAt': now,
      });

      // Cancel any pending onDisconnect since we're explicitly going offline
      await ref.onDisconnect().cancel();

      Logger.logSuccess('setOffline: User $userId set to offline', tag: LogTag.chat);
    } catch (e) {
      Logger.logError('setOffline failed: $e', tag: LogTag.chat);
    }
  }

  /// Set user as away (e.g., app in background but not fully offline)
  /// [userId] should be obtained from context.currentUserId in presentation layer
  Future<void> setAway(String userId) async {
    if (userId.isEmpty) return;

    try {
      final ref = _presenceRef(userId);

      await ref.update({
        'status': 'away',
        'updatedAt': ServerValue.timestamp,
      });

      Logger.logBasic('setAway: User $userId set to away', tag: LogTag.chat);
    } catch (e) {
      Logger.logError('setAway failed: $e', tag: LogTag.chat);
    }
  }

  /// Update last seen timestamp without changing status
  /// [userId] should be obtained from context.currentUserId in presentation layer
  Future<void> updateLastSeen(String userId) async {
    if (userId.isEmpty) return;

    try {
      await _presenceRef(userId).update({
        'lastSeen': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      Logger.logError('updateLastSeen failed: $e', tag: LogTag.chat);
    }
  }

  /// Get current presence for a user (one-time fetch)
  Future<PresenceData?> getPresence(String userId) async {
    if (userId.isEmpty) return null;

    try {
      final snapshot = await _presenceRef(userId).get();
      if (!snapshot.exists || snapshot.value == null) {
        return PresenceData(
          userId: userId,
          status: PresenceStatus.offline,
          lastSeen: null,
        );
      }

      return _parsePresenceData(userId, snapshot.value as Map);
    } catch (e) {
      Logger.logError('getPresence failed: $e', tag: LogTag.chat);
      return null;
    }
  }

  /// Watch a user's presence in real-time
  /// Returns a stream of PresenceData updates
  Stream<PresenceData> watchPresence(String userId) {
    if (userId.isEmpty) {
      return Stream.value(PresenceData(
        userId: userId,
        status: PresenceStatus.offline,
        lastSeen: null,
      ));
    }

    return _presenceRef(userId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return PresenceData(
          userId: userId,
          status: PresenceStatus.offline,
          lastSeen: null,
        );
      }

      return _parsePresenceData(userId, event.snapshot.value as Map);
    });
  }

  /// Watch multiple users' presence at once
  /// Useful for chat list to show online indicators
  Stream<Map<String, PresenceData>> watchMultiplePresence(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value({});
    }

    // Create individual streams for each user
    final streams = userIds.map((userId) => watchPresence(userId));

    // Combine all streams into a single map
    return StreamZip(streams).map((presenceList) {
      final Map<String, PresenceData> result = {};
      for (final presence in presenceList) {
        result[presence.userId] = presence;
      }
      return result;
    });
  }

  /// Listen to connection state changes
  /// Useful for re-establishing presence when reconnecting
  Stream<bool> watchConnectionState() {
    return _connectedRef.onValue.map((event) {
      return event.snapshot.value == true;
    });
  }

  /// Set up connection state listener that auto-restores presence on reconnect
  /// [userId] should be obtained from context.currentUserId in presentation layer
  StreamSubscription<bool>? setupConnectionListener(String userId) {
    if (userId.isEmpty) return null;

    return watchConnectionState().listen((connected) {
      if (connected) {
        Logger.logBasic(
          'Connection restored, re-establishing presence for $userId',
          tag: LogTag.chat,
        );
        setOnline(userId);
      }
    });
  }

  // ============================================
  // Helper Methods
  // ============================================

  /// Parse RTDB data into PresenceData
  PresenceData _parsePresenceData(String userId, Map data) {
    final statusStr = data['status'] as String? ?? 'offline';
    final lastSeenMs = data['lastSeen'] as int?;

    PresenceStatus status;
    switch (statusStr.toLowerCase()) {
      case 'online':
        status = PresenceStatus.online;
        break;
      case 'away':
        status = PresenceStatus.away;
        break;
      default:
        status = PresenceStatus.offline;
    }

    return PresenceData(
      userId: userId,
      status: status,
      lastSeen: lastSeenMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSeenMs)
          : null,
    );
  }
}

/// Simple data class for presence information
class PresenceData {
  final String userId;
  final PresenceStatus status;
  final DateTime? lastSeen;

  const PresenceData({
    required this.userId,
    required this.status,
    this.lastSeen,
  });

  bool get isOnline => status == PresenceStatus.online;
  bool get isAway => status == PresenceStatus.away;
  bool get isOffline => status == PresenceStatus.offline;

  @override
  String toString() => 'PresenceData(userId: $userId, status: $status, lastSeen: $lastSeen)';
}

/// Helper class to combine multiple streams
class StreamZip<T> extends Stream<List<T>> {
  final Iterable<Stream<T>> _streams;

  StreamZip(this._streams);

  @override
  StreamSubscription<List<T>> listen(
    void Function(List<T> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<T>>();
    final subscriptions = <StreamSubscription<T>>[];
    final values = List<T?>.filled(_streams.length, null);
    final hasValue = List<bool>.filled(_streams.length, false);
    var completedCount = 0;

    void emitIfReady() {
      if (hasValue.every((v) => v)) {
        controller.add(List<T>.from(values));
      }
    }

    var index = 0;
    for (final stream in _streams) {
      final currentIndex = index;
      subscriptions.add(stream.listen(
        (value) {
          values[currentIndex] = value;
          hasValue[currentIndex] = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: () {
          completedCount++;
          if (completedCount == _streams.length) {
            controller.close();
          }
        },
      ));
      index++;
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
