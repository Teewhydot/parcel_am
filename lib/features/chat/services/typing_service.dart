import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parcel_am/core/utils/logger.dart' show Logger, LogTag;

/// Service for real-time typing status and chat presence using Firebase Realtime Database.
/// RTDB provides lower latency (~50ms) compared to Firestore (~200-500ms)
/// for presence-like features.
class TypingService {
  static final TypingService _instance = TypingService._internal();
  factory TypingService() => _instance;
  TypingService._internal();

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

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Reference to typing status in RTDB
  /// Structure: /typing/{chatId}/{userId} = { isTyping: bool, timestamp: int }
  DatabaseReference _typingRef(String chatId) {
    return database.ref('typing/$chatId');
  }

  /// Set typing status for current user in a chat
  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Logger.logWarning(
        'setTypingStatus: No user logged in',
        tag: 'TypingService',
      );
      return;
    }

    try {
      final ref = _typingRef(chatId).child(userId);
      Logger.logBasic(
        'setTypingStatus: chatId=$chatId, userId=$userId, isTyping=$isTyping',
        tag: 'TypingService',
      );

      if (isTyping) {
        // Set typing with timestamp for auto-cleanup
        await ref.set({
          'isTyping': true,
          'timestamp': ServerValue.timestamp,
        });
        Logger.logSuccess(
          'setTypingStatus: Successfully set typing=true',
          tag: 'TypingService',
        );
      } else {
        // Remove typing status completely for efficiency
        await ref.remove();
        Logger.logSuccess(
          'setTypingStatus: Successfully removed typing status',
          tag: 'TypingService',
        );
      }
    } catch (e) {
      Logger.logError('setTypingStatus failed: $e', tag: 'TypingService');
    }
  }

  /// Listen to other user's typing status in a chat
  /// Returns a stream of (userId, isTyping) pairs
  Stream<Map<String, bool>> watchTypingStatus(String chatId) {
    final currentUserId = _auth.currentUser?.uid;
    Logger.logBasic(
      'watchTypingStatus: Starting for chatId=$chatId, currentUserId=$currentUserId',
      tag: 'TypingService',
    );

    return _typingRef(chatId).onValue.map((event) {
      final Map<String, bool> typingStatus = {};

      Logger.logBasic(
        'watchTypingStatus: Received event, value=${event.snapshot.value}',
        tag: 'TypingService',
      );

      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        for (final entry in data.entries) {
          // Skip current user's typing status
          if (entry.key == currentUserId) continue;

          final value = Map<String, dynamic>.from(entry.value as Map);
          final isTyping = value['isTyping'] as bool? ?? false;
          final timestamp = value['timestamp'] as int?;

          // Consider typing stale if older than 10 seconds (auto-cleanup)
          if (timestamp != null) {
            final age = DateTime.now().millisecondsSinceEpoch - timestamp;
            Logger.logBasic(
              'watchTypingStatus: userId=${entry.key}, isTyping=$isTyping, age=${age}ms',
              tag: 'TypingService',
            );
            if (age < 10000) {
              typingStatus[entry.key] = isTyping;
            } else {
              Logger.logWarning(
                'watchTypingStatus: Typing status stale (age=${age}ms)',
                tag: 'TypingService',
              );
            }
          }
        }
      }

      Logger.logBasic(
        'watchTypingStatus: Returning status=$typingStatus',
        tag: 'TypingService',
      );
      return typingStatus;
    });
  }

  /// Check if a specific user is typing in a chat
  Stream<bool> watchUserTyping(String chatId, String userId) {
    Logger.logBasic(
      'watchUserTyping: chatId=$chatId, userId=$userId',
      tag: 'TypingService',
    );
    return watchTypingStatus(chatId).map((status) {
      final isTyping = status[userId] ?? false;
      Logger.logBasic(
        'watchUserTyping: User $userId isTyping=$isTyping',
        tag: 'TypingService',
      );
      return isTyping;
    });
  }

  /// Clear typing status when leaving chat or on disconnect
  Future<void> clearTypingStatus(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _typingRef(chatId).child(userId).remove();
    } catch (e) {
      // Silently fail
    }
  }

  /// Set up onDisconnect handler to auto-clear typing when connection drops
  Future<void> setupOnDisconnect(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _typingRef(chatId).child(userId).onDisconnect().remove();
    } catch (e) {
      // Silently fail
    }
  }

  // ============================================
  // Chat Viewing Presence (for notification suppression)
  // ============================================

  /// Reference to viewing status in RTDB
  /// Structure: /viewing/{userId} = { chatId: string, timestamp: int }
  DatabaseReference _viewingRef(String userId) {
    return database.ref('viewing/$userId');
  }

  /// Set which chat the user is currently viewing
  /// Call when entering a chat screen
  Future<void> setViewingChat(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final ref = _viewingRef(userId);
      await ref.set({
        'chatId': chatId,
        'timestamp': ServerValue.timestamp,
      });
      // Auto-clear on disconnect
      await ref.onDisconnect().remove();
      Logger.logBasic('Set viewing chat: $chatId', tag: LogTag.chat);
    } catch (e) {
      Logger.logError('setViewingChat failed: $e', tag: LogTag.chat);
    }
  }

  /// Clear viewing status when leaving a chat screen
  Future<void> clearViewingChat() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _viewingRef(userId).remove();
      Logger.logBasic('Cleared viewing chat', tag: LogTag.chat);
    } catch (e) {
      Logger.logError('clearViewingChat failed: $e', tag: LogTag.chat);
    }
  }

  /// Check if a user is currently viewing a specific chat
  /// Used by NotificationService to suppress notifications
  Future<bool> isUserViewingChat(String userId, String chatId) async {
    try {
      final snapshot = await _viewingRef(userId).get();
      if (!snapshot.exists || snapshot.value == null) return false;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final viewingChatId = data['chatId'] as String?;
      final timestamp = data['timestamp'] as int?;

      // Consider stale if older than 30 seconds (user may have crashed)
      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age > 30000) return false;
      }

      return viewingChatId == chatId;
    } catch (e) {
      Logger.logError('isUserViewingChat failed: $e', tag: LogTag.chat);
      return false;
    }
  }

  /// Stream to watch if current user is viewing a specific chat
  /// More efficient than polling for real-time updates
  Stream<bool> watchUserViewingChat(String userId, String chatId) {
    return _viewingRef(userId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return false;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final viewingChatId = data['chatId'] as String?;
      final timestamp = data['timestamp'] as int?;

      // Consider stale if older than 30 seconds
      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age > 30000) return false;
      }

      return viewingChatId == chatId;
    });
  }
}
