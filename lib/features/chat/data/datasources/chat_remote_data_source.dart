import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../../../../core/utils/logger.dart' show Logger, LogTag;
import '../../../file_upload/data/remote/data_sources/file_upload.dart';
import '../../services/message_rtdb_service.dart';

abstract class ChatRemoteDataSource {
  Stream<List<MessageModel>> getMessagesStream(String chatId);
  /// Sends a message using the client-provided message ID
  Future<void> sendMessage(MessageModel message);
  Future<void> updateMessageStatus(String messageId, MessageStatus status);
  Future<void> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  );
  Future<String> uploadMedia(
    String filePath,
    String chatId,
    MessageType type,
    Function(double) onProgress,
  );
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping);
  Future<void> updateLastSeen(String chatId, String userId);
  Stream<ChatModel> getChatStream(String chatId);
  Future<void> deleteMessage(String messageId, {String? chatId});

  // Chat management methods
  Future<ChatModel> createChat(List<String> participantIds);
  Future<ChatModel> getChat(String chatId);
  Future<List<ChatModel>> getUserChats(String userId);
  Stream<ChatModel> watchChat(String chatId);
  Stream<List<ChatModel>> watchUserChats(String userId);
  Future<ChatModel> getOrCreateChat({
    required String chatId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
  });

  Future<void> markMessageNotificationSent(String chatId, String messageId);

  /// Atomically check if notification can be claimed and mark it as sent.
  /// Returns true if notification should be shown (was not previously sent).
  /// Returns false if notification was already sent (skip showing).
  Future<bool> tryClaimNotification(String chatId, String messageId);
}

/// RTDB-based implementation for low-latency chat messaging (~50ms vs 2-4s Firestore)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseStorage storage;
  final FileUploadDataSource fileUploadDataSource;
  final MessageRtdbService _rtdbService;

  ChatRemoteDataSourceImpl({
    required this.storage,
    FileUploadDataSource? fileUploadDataSource,
    MessageRtdbService? rtdbService,
  })  : fileUploadDataSource =
            fileUploadDataSource ?? sl<FileUploadDataSource>(),
        _rtdbService = rtdbService ?? MessageRtdbService();

  // ============================================
  // Message Operations (via RTDB for low latency)
  // ============================================

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    Logger.logBasic(
      'getMessagesStream: Starting RTDB stream for chatId=$chatId',
      tag: LogTag.chat,
    );
    return _rtdbService.watchMessages(chatId, limit: 100);
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    await _rtdbService.sendMessage(
      messageId: message.id,
      chatId: message.chatId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      content: message.content,
      type: message.type,
      mediaUrl: message.mediaUrl,
      thumbnailUrl: message.thumbnailUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      replyToMessageId: message.replyToMessageId,
    );

    // Increment unread count for other participants
    await _rtdbService.incrementUnreadForOthers(
      message.chatId,
      message.senderId,
    );
  }

  @override
  Future<void> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    // This method requires chatId - log warning for now
    // In practice, the caller should use the version with chatId
    Logger.logWarning(
      'updateMessageStatus called without chatId - this is inefficient',
      tag: LogTag.chat,
    );
  }

  @override
  Future<void> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  ) async {
    await _rtdbService.markAsRead(chatId, messageId, userId);
    // Reset unread count for this user
    await _rtdbService.updateUnreadCount(chatId, userId, 0);
  }

  @override
  Future<String> uploadMedia(
    String filePath,
    String chatId,
    MessageType type,
    Function(double) onProgress,
  ) async {
    final file = File(filePath);
    final String folder = type == MessageType.image
        ? 'images'
        : type == MessageType.video
            ? 'videos'
            : 'documents';

    final result = await fileUploadDataSource.uploadChatMedia(
      file: file,
      chatId: chatId,
      folder: folder,
      onProgress: onProgress,
    );

    return result.url;
  }

  @override
  Future<void> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    // Typing is handled by TypingService (already on RTDB)
    // This method is kept for interface compatibility
    Logger.logBasic(
      'setTypingStatus: Use TypingService directly for RTDB typing',
      tag: LogTag.chat,
    );
  }

  @override
  Future<void> updateLastSeen(String chatId, String userId) async {
    await _rtdbService.updateLastSeen(chatId, userId);
  }

  @override
  Stream<ChatModel> getChatStream(String chatId) {
    return _rtdbService.watchChat(chatId).map((data) {
      if (data == null) {
        return ChatModel(
          id: chatId,
          participantIds: [],
          participantNames: {},
          participantAvatars: {},
          unreadCount: {},
          isTyping: {},
          lastSeen: {},
          createdAt: DateTime.now(),
        );
      }
      return _chatModelFromRtdb(chatId, data);
    });
  }

  @override
  Future<void> deleteMessage(String messageId, {String? chatId}) async {
    if (chatId == null) {
      Logger.logError(
        'deleteMessage requires chatId for RTDB',
        tag: LogTag.chat,
      );
      return;
    }
    await _rtdbService.deleteMessage(chatId, messageId);
  }

  // ============================================
  // Chat Management Operations (via RTDB)
  // ============================================

  @override
  Future<ChatModel> createChat(List<String> participantIds) async {
    // Generate a chat ID from sorted participant IDs for 1:1 chats
    final sortedIds = List<String>.from(participantIds)..sort();
    final chatId = sortedIds.join('_');

    await _rtdbService.getOrCreateChat(
      chatId: chatId,
      participantIds: participantIds,
      participantNames: {},
    );

    return ChatModel(
      id: chatId,
      participantIds: participantIds,
      participantNames: {},
      participantAvatars: {},
      unreadCount: {},
      isTyping: {},
      lastSeen: {},
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<ChatModel> getChat(String chatId) async {
    final data = await _rtdbService.watchChat(chatId).first;
    if (data == null) {
      throw Exception('Chat not found');
    }
    return _chatModelFromRtdb(chatId, data);
  }

  @override
  Future<List<ChatModel>> getUserChats(String userId) async {
    final chatsData = await _rtdbService.watchUserChats(userId).first;
    return chatsData.map((data) {
      final chatId = data['id'] as String? ?? '';
      return _chatModelFromRtdb(chatId, data);
    }).toList();
  }

  @override
  Stream<ChatModel> watchChat(String chatId) {
    return getChatStream(chatId);
  }

  @override
  Stream<List<ChatModel>> watchUserChats(String userId) {
    return _rtdbService.watchUserChats(userId).map((chatsData) {
      return chatsData.map((data) {
        final chatId = data['id'] as String? ?? '';
        return _chatModelFromRtdb(chatId, data);
      }).toList();
    });
  }

  @override
  Future<ChatModel> getOrCreateChat({
    required String chatId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
  }) async {
    Logger.logBasic(
      'getOrCreateChat: chatId=$chatId, participantIds=$participantIds',
      tag: LogTag.chat,
    );

    await _rtdbService.getOrCreateChat(
      chatId: chatId,
      participantIds: participantIds,
      participantNames: participantNames,
    );

    return ChatModel(
      id: chatId,
      participantIds: participantIds,
      participantNames: participantNames,
      participantAvatars: {},
      unreadCount: {for (var id in participantIds) id: 0},
      isTyping: {},
      lastSeen: {},
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> markMessageNotificationSent(
    String chatId,
    String messageId,
  ) async {
    // Notification flag is updated via tryClaimNotification
    Logger.logBasic(
      'markMessageNotificationSent: chatId=$chatId, messageId=$messageId',
      tag: LogTag.notification,
    );
  }

  @override
  Future<bool> tryClaimNotification(
    String chatId,
    String messageId,
  ) async {
    return _rtdbService.tryClaimNotification(chatId, messageId);
  }

  // ============================================
  // Helper Methods
  // ============================================

  ChatModel _chatModelFromRtdb(String chatId, Map<String, dynamic> data) {
    // Parse participantIds
    List<String> participantIds = [];
    if (data['participantIds'] is List) {
      participantIds = List<String>.from(data['participantIds'] as List);
    }

    // Parse participantNames
    Map<String, String> participantNames = {};
    if (data['participantNames'] is Map) {
      participantNames = Map<String, String>.from(
        data['participantNames'] as Map,
      );
    }

    // Parse participantAvatars
    Map<String, String?> participantAvatars = {};
    if (data['participantAvatars'] is Map) {
      final avatarsMap = data['participantAvatars'] as Map;
      for (final entry in avatarsMap.entries) {
        participantAvatars[entry.key.toString()] = entry.value?.toString();
      }
    }

    // Parse unreadCount
    Map<String, int> unreadCount = {};
    if (data['unreadCount'] is Map) {
      final unreadMap = data['unreadCount'] as Map;
      for (final entry in unreadMap.entries) {
        unreadCount[entry.key.toString()] = (entry.value as num?)?.toInt() ?? 0;
      }
    }

    // Parse isTyping
    Map<String, bool> isTyping = {};
    if (data['isTyping'] is Map) {
      final typingMap = data['isTyping'] as Map;
      for (final entry in typingMap.entries) {
        isTyping[entry.key.toString()] = entry.value == true;
      }
    }

    // Parse lastSeen
    Map<String, DateTime?> lastSeen = {};
    if (data['lastSeen'] is Map) {
      final lastSeenMap = data['lastSeen'] as Map;
      for (final entry in lastSeenMap.entries) {
        if (entry.value is int) {
          lastSeen[entry.key.toString()] = DateTime.fromMillisecondsSinceEpoch(
            entry.value as int,
          );
        }
      }
    }

    // Parse lastMessage
    MessageModel? lastMessage;
    if (data['lastMessage'] is Map) {
      final msgData = Map<String, dynamic>.from(data['lastMessage'] as Map);
      final msgId = msgData['id'] as String? ?? '';
      lastMessage = _messageFromRtdb(msgId, msgData);
    }

    // Parse createdAt
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int);
    }

    return ChatModel(
      id: chatId,
      participantIds: participantIds,
      participantNames: participantNames,
      participantAvatars: participantAvatars,
      lastMessage: lastMessage,
      lastMessageTime: data['lastMessageTime'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['lastMessageTime'] as int)
          : null,
      unreadCount: unreadCount,
      isTyping: isTyping,
      lastSeen: lastSeen,
      createdAt: createdAt,
    );
  }

  MessageModel _messageFromRtdb(String id, Map<String, dynamic> data) {
    DateTime timestamp;
    if (data['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
    } else {
      timestamp = DateTime.now();
    }

    Map<String, DateTime>? readBy;
    if (data['readBy'] is Map) {
      final readByData = data['readBy'] as Map;
      readBy = {};
      for (final entry in readByData.entries) {
        if (entry.value is int) {
          readBy[entry.key.toString()] = DateTime.fromMillisecondsSinceEpoch(
            entry.value as int,
          );
        }
      }
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
      isDeleted: data['isDeleted'] as bool? ?? false,
      readBy: readBy,
      notificationSent: data['notificationSent'] as bool? ?? false,
    );
  }
}
