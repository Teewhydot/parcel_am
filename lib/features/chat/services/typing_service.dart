import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for real-time typing status using Firebase Realtime Database.
/// RTDB provides lower latency (~50ms) compared to Firestore (~200-500ms)
/// for presence-like features.
class TypingService {
  static final TypingService _instance = TypingService._internal();
  factory TypingService() => _instance;
  TypingService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Reference to typing status in RTDB
  /// Structure: /typing/{chatId}/{userId} = { isTyping: bool, timestamp: int }
  DatabaseReference _typingRef(String chatId) {
    return _database.ref('typing/$chatId');
  }

  /// Set typing status for current user in a chat
  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final ref = _typingRef(chatId).child(userId);
      
      if (isTyping) {
        // Set typing with timestamp for auto-cleanup
        await ref.set({
          'isTyping': true,
          'timestamp': ServerValue.timestamp,
        });
      } else {
        // Remove typing status completely for efficiency
        await ref.remove();
      }
    } catch (e) {
      // Silently fail - typing status is non-critical
    }
  }

  /// Listen to other user's typing status in a chat
  /// Returns a stream of (userId, isTyping) pairs
  Stream<Map<String, bool>> watchTypingStatus(String chatId) {
    final currentUserId = _auth.currentUser?.uid;
    
    return _typingRef(chatId).onValue.map((event) {
      final Map<String, bool> typingStatus = {};
      
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
            if (age < 10000) {
              typingStatus[entry.key] = isTyping;
            }
          }
        }
      }
      
      return typingStatus;
    });
  }

  /// Check if a specific user is typing in a chat
  Stream<bool> watchUserTyping(String chatId, String userId) {
    return watchTypingStatus(chatId).map((status) => status[userId] ?? false);
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
}
