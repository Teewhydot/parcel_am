import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:parcel_am/core/utils/logger.dart' show Logger, LogTag;
import '../data/models/message_model.dart';
import '../domain/entities/message.dart';
import '../domain/entities/message_type.dart';

/// Service for real-time chat messages using Firebase Realtime Database.
/// RTDB provides lower latency (~50ms) compared to Firestore (~200-500ms).
class MessageRtdbService {
  static final MessageRtdbService _instance = MessageRtdbService._internal();
  factory MessageRtdbService() => _instance;
  MessageRtdbService._internal();

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

  // FirebaseAuth available if needed for user validation
  // FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Reference to messages in RTDB
  /// Structure: /messages/{chatId}/{messageId} = { message data }
  DatabaseReference _messagesRef(String chatId) {
    return database.ref('messages/$chatId');
  }

  /// Reference to chat metadata in RTDB
  /// Structure: /chats/{chatId} = { lastMessage, participantIds, etc. }
  DatabaseReference _chatRef(String chatId) {
    return database.ref('chats/$chatId');
  }

  /// Reference to user's chats index
  /// Structure: /user_chats/{userId}/{chatId} = { lastMessageTime }
  DatabaseReference _userChatsRef(String userId) {
    return database.ref('user_chats/$userId');
  }

  // ============================================
  // Message Operations
  // ============================================

  /// Send a new message to a chat
  /// Uses the provided messageId (client-generated) for consistency
  Future<void> sendMessage({
    required String messageId,
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    required MessageType type,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
    Map<String, dynamic>? replyToMessageData,
  }) async {
    try {
      final timestamp = ServerValue.timestamp;

      final messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'content': content,
        'type': type.name,
        'status': MessageStatus.sent.name,
        'timestamp': timestamp,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'replyToMessageId': replyToMessageId,
        'replyToMessageData': replyToMessageData,
        'isDeleted': false,
        'notificationSent': false,
        'readBy': <String, dynamic>{},
      };

      // Get participant IDs to update their user_chats index
      final chatSnapshot = await _chatRef(chatId).child('participantIds').get();
      final List<String> participantIds;
      if (chatSnapshot.exists && chatSnapshot.value != null) {
        final value = chatSnapshot.value;
        if (value is List) {
          participantIds = List<String>.from(value);
        } else if (value is Map) {
          // Firebase RTDB can convert arrays to maps with numeric keys
          participantIds = (value.values).whereType<String>().toList();
        } else {
          participantIds = <String>[];
        }
      } else {
        participantIds = <String>[];
      }

      // Write message and update chat metadata atomically
      final updates = <String, dynamic>{
        'messages/$chatId/$messageId': messageData,
        'chats/$chatId/lastMessage': messageData,
        'chats/$chatId/lastMessageTime': timestamp,
      };

      // Update user_chats index for all participants (triggers notification listeners)
      for (final participantId in participantIds) {
        updates['user_chats/$participantId/$chatId/lastMessageTime'] = timestamp;
      }

      await database.ref().update(updates);

      Logger.logSuccess(
        'Message sent: chatId=$chatId, messageId=$messageId',
        tag: LogTag.chat,
      );
    } catch (e) {
      Logger.logError('sendMessage failed: $e', tag: LogTag.chat);
      rethrow;
    }
  }

  /// Watch messages in a chat in real-time
  /// Returns stream of messages sorted by timestamp (ascending)
  Stream<List<MessageModel>> watchMessages(String chatId, {int limit = 100}) {
    Logger.logBasic(
      'watchMessages: Starting for chatId=$chatId, limit=$limit',
      tag: LogTag.chat,
    );

    return _messagesRef(chatId)
        .orderByChild('timestamp')
        .limitToLast(limit)
        .onValue
        .map((event) {
      final List<MessageModel> messages = [];

      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        for (final entry in data.entries) {
          try {
            final messageData = Map<String, dynamic>.from(entry.value as Map);
            final message = _messageFromRtdb(entry.key, messageData);
            if (!message.isDeleted) {
              messages.add(message);
            }
          } catch (e) {
            Logger.logError(
              'Error parsing message ${entry.key}: $e',
              tag: LogTag.chat,
            );
          }
        }

        // Sort by timestamp ascending (oldest first)
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      Logger.logBasic(
        'watchMessages: Returning ${messages.length} messages',
        tag: LogTag.chat,
      );

      return messages;
    });
  }

  /// Watch a single message for real-time updates
  Stream<MessageModel?> watchMessage(String chatId, String messageId) {
    return _messagesRef(chatId).child(messageId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return _messageFromRtdb(messageId, data);
    });
  }

  /// Update message status
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    MessageStatus status,
  ) async {
    try {
      await _messagesRef(chatId).child(messageId).update({
        'status': status.name,
      });

      Logger.logBasic(
        'updateMessageStatus: messageId=$messageId, status=${status.name}',
        tag: LogTag.chat,
      );
    } catch (e) {
      Logger.logError('updateMessageStatus failed: $e', tag: LogTag.chat);
    }
  }

  /// Mark message as read by a user
  Future<void> markAsRead(
    String chatId,
    String messageId,
    String userId,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _messagesRef(chatId).child(messageId).update({
        'readBy/$userId': timestamp,
        'status': MessageStatus.read.name,
      });

      Logger.logBasic(
        'markAsRead: messageId=$messageId, userId=$userId',
        tag: LogTag.chat,
      );
    } catch (e) {
      Logger.logError('markAsRead failed: $e', tag: LogTag.chat);
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _messagesRef(chatId).child(messageId).update({
        'isDeleted': true,
        'content': '',
        'mediaUrl': null,
        'thumbnailUrl': null,
      });

      Logger.logBasic(
        'deleteMessage: messageId=$messageId',
        tag: LogTag.chat,
      );
    } catch (e) {
      Logger.logError('deleteMessage failed: $e', tag: LogTag.chat);
    }
  }

  /// Claim notification atomically (prevent duplicates)
  Future<bool> tryClaimNotification(String chatId, String messageId) async {
    try {
      final ref = _messagesRef(chatId).child(messageId).child('notificationSent');

      final result = await ref.runTransaction((currentValue) {
        if (currentValue == true) {
          // Already claimed
          return Transaction.abort();
        }
        return Transaction.success(true);
      });

      return result.committed;
    } catch (e) {
      Logger.logError('tryClaimNotification failed: $e', tag: LogTag.chat);
      return false;
    }
  }

  // ============================================
  // Chat Metadata Operations
  // ============================================

  /// Get or create a chat
  Future<void> getOrCreateChat({
    required String chatId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String?>? participantAvatars,
  }) async {
    try {
      final chatRef = _chatRef(chatId);
      final snapshot = await chatRef.get();

      if (!snapshot.exists) {
        // Create new chat
        await chatRef.set({
          'id': chatId,
          'participantIds': participantIds,
          'participantNames': participantNames,
          'participantAvatars': participantAvatars ?? {},
          'createdAt': ServerValue.timestamp,
          'lastMessageTime': ServerValue.timestamp,
          'unreadCount': {for (var id in participantIds) id: 0},
        });

        // Add to user_chats index for each participant
        for (final userId in participantIds) {
          await _userChatsRef(userId).child(chatId).set({
            'lastMessageTime': ServerValue.timestamp,
          });
        }

        Logger.logSuccess('Created new chat: $chatId', tag: LogTag.chat);
      }
    } catch (e) {
      Logger.logError('getOrCreateChat failed: $e', tag: LogTag.chat);
      rethrow;
    }
  }

  /// Watch a chat's metadata
  Stream<Map<String, dynamic>?> watchChat(String chatId) {
    return _chatRef(chatId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  /// Watch all chats for a user with real-time updates (including typing)
  Stream<List<Map<String, dynamic>>> watchUserChats(String userId) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    final Map<String, Map<String, dynamic>> chatDataCache = {};
    final Map<String, StreamSubscription<DatabaseEvent>> chatListeners = {};
    StreamSubscription<DatabaseEvent>? userChatsSubscription;
    Set<String> currentChatIds = {};

    void emitSortedChats() {
      if (controller.isClosed) return;

      final chats = chatDataCache.values.toList();
      chats.sort((a, b) {
        final aTime = a['lastMessageTime'] as int? ?? 0;
        final bTime = b['lastMessageTime'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });
      controller.add(chats);
    }

    void subscribeToChatUpdates(String chatId) {
      if (chatListeners.containsKey(chatId)) return;

      chatListeners[chatId] = _chatRef(chatId).onValue.listen(
        (event) {
          if (controller.isClosed) return;

          if (event.snapshot.exists && event.snapshot.value != null) {
            final chatData = Map<String, dynamic>.from(event.snapshot.value as Map);
            chatData['id'] = chatId;
            chatDataCache[chatId] = chatData;
            emitSortedChats();
          }
        },
        onError: (error) {
          Logger.logError(
            'Chat listener error for $chatId: $error',
            tag: LogTag.chat,
          );
          // Don't cancel on error - keep trying to listen
        },
        cancelOnError: false,
      );
    }

    void unsubscribeFromChat(String chatId) {
      chatListeners[chatId]?.cancel();
      chatListeners.remove(chatId);
      chatDataCache.remove(chatId);
    }

    // Watch user's chat list for added/removed chats
    userChatsSubscription = _userChatsRef(userId).onValue.listen(
      (event) {
        final newChatIds = <String>{};

        if (event.snapshot.value != null) {
          final chatIdsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          newChatIds.addAll(chatIdsMap.keys);
        }

        // Subscribe to new chats
        for (final chatId in newChatIds) {
          if (!currentChatIds.contains(chatId)) {
            subscribeToChatUpdates(chatId);
          }
        }

        // Unsubscribe from removed chats
        for (final chatId in currentChatIds) {
          if (!newChatIds.contains(chatId)) {
            unsubscribeFromChat(chatId);
          }
        }

        currentChatIds = newChatIds;

        // If no chats, emit empty list
        if (newChatIds.isEmpty && !controller.isClosed) {
          controller.add([]);
        }
      },
      onError: (error) {
        Logger.logError(
          'User chats listener error for $userId: $error',
          tag: LogTag.chat,
        );
      },
      cancelOnError: false,
    );

    controller.onCancel = () async {
      // Cancel user chats subscription
      await userChatsSubscription?.cancel();

      // Cancel all individual chat listeners
      final cancelFutures = chatListeners.values.map((sub) => sub.cancel());
      await Future.wait(cancelFutures);

      // Clear all data
      chatListeners.clear();
      chatDataCache.clear();

      Logger.logBasic(
        'Cleaned up watchUserChats for userId=$userId',
        tag: LogTag.chat,
      );
    };

    return controller.stream;
  }

  /// Update unread count for a user in a chat
  Future<void> updateUnreadCount(
    String chatId,
    String userId,
    int count,
  ) async {
    try {
      await _chatRef(chatId).child('unreadCount').child(userId).set(count);
    } catch (e) {
      Logger.logError('updateUnreadCount failed: $e', tag: LogTag.chat);
    }
  }

  /// Increment unread count for all participants except sender
  Future<void> incrementUnreadForOthers(
    String chatId,
    String senderId,
  ) async {
    try {
      final chatSnapshot = await _chatRef(chatId).get();
      if (!chatSnapshot.exists) return;

      final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
      final List<String> participantIds;
      final rawIds = chatData['participantIds'];
      if (rawIds is List) {
        participantIds = List<String>.from(rawIds);
      } else if (rawIds is Map) {
        participantIds = (rawIds.values).whereType<String>().toList();
      } else {
        participantIds = <String>[];
      }

      for (final participantId in participantIds) {
        if (participantId != senderId) {
          await _chatRef(chatId)
              .child('unreadCount')
              .child(participantId)
              .runTransaction((currentValue) {
            final current = (currentValue as int?) ?? 0;
            return Transaction.success(current + 1);
          });
        }
      }
    } catch (e) {
      Logger.logError('incrementUnreadForOthers failed: $e', tag: LogTag.chat);
    }
  }

  /// Update last seen timestamp for a user
  Future<void> updateLastSeen(String chatId, String userId) async {
    try {
      await _chatRef(chatId).child('lastSeen').child(userId).set(
            ServerValue.timestamp,
          );
    } catch (e) {
      Logger.logError('updateLastSeen failed: $e', tag: LogTag.chat);
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  /// Convert RTDB data to MessageModel
  MessageModel _messageFromRtdb(String id, Map<String, dynamic> data) {
    // Handle timestamp - can be int (from RTDB) or ServerValue placeholder
    DateTime timestamp;
    if (data['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
    } else {
      timestamp = DateTime.now();
    }

    // Parse readBy map
    Map<String, DateTime>? readBy;
    if (data['readBy'] != null && data['readBy'] is Map) {
      final readByData = Map<String, dynamic>.from(data['readBy'] as Map);
      readBy = {};
      for (final entry in readByData.entries) {
        if (entry.value is int) {
          readBy[entry.key] = DateTime.fromMillisecondsSinceEpoch(
            entry.value as int,
          );
        }
      }
    }

    // Parse replyToMessage if data exists
    Message? replyToMessage;
    final replyData = data['replyToMessageData'];
    if (replyData != null && replyData is Map) {
      final replyMap = Map<String, dynamic>.from(replyData);
      replyToMessage = Message(
        id: replyMap['id'] as String? ?? '',
        chatId: replyMap['chatId'] as String? ?? '',
        senderId: replyMap['senderId'] as String? ?? '',
        senderName: replyMap['senderName'] as String? ?? '',
        senderAvatar: replyMap['senderAvatar'] as String?,
        content: replyMap['content'] as String? ?? '',
        type: MessageType.values.firstWhere(
          (e) => e.name == replyMap['type'],
          orElse: () => MessageType.text,
        ),
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
      );
    }

    return MessageModel(
      id: id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderAvatar: data['senderAvatar'] as String?,
      content: data['content'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: timestamp,
      mediaUrl: data['mediaUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSize: data['fileSize'] as int?,
      replyToMessageId: data['replyToMessageId'] as String?,
      replyToMessage: replyToMessage,
      isDeleted: data['isDeleted'] as bool? ?? false,
      readBy: readBy,
      notificationSent: data['notificationSent'] as bool? ?? false,
    );
  }
}
