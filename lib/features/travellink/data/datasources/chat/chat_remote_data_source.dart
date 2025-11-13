import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/chat/chat_entity.dart';
import '../../../domain/entities/chat/message_entity.dart';
import '../../../domain/entities/chat/presence_entity.dart';

abstract class ChatRemoteDataSource {
  Stream<List<ChatEntity>> watchUserChats(String userId);
  Stream<List<MessageEntity>> watchMessages(String chatId);
  Future<ChatEntity> createChat(List<String> participantIds);
  Future<MessageEntity> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    required MessageType type,
    String? replyToId,
  });
  Future<void> deleteMessage(String messageId);
  Future<void> markAsRead(String chatId, String userId);
  Stream<PresenceEntity> watchUserPresence(String userId);
  Future<void> updatePresence({
    required String userId,
    required OnlineStatus status,
    String? currentChatId,
  });
  Future<void> setTypingStatus({
    required String userId,
    required String chatId,
    required bool isTyping,
  });
  Stream<Map<String, bool>> watchTypingStatus(String chatId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;

  ChatRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<ChatEntity>> watchUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatEntity(
          id: doc.id,
          participantIds: List<String>.from(data['participantIds'] ?? []),
          lastMessage: data['lastMessage'],
          lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
          lastMessageSenderId: data['lastMessageSenderId'],
          unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
      }).toList();
    });
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageEntity(
          id: doc.id,
          chatId: chatId,
          senderId: data['senderId'] ?? '',
          content: data['content'] ?? '',
          type: _parseMessageType(data['type']),
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          isRead: data['isRead'] ?? false,
          readBy: List<String>.from(data['readBy'] ?? []),
          replyToId: data['replyToId'],
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
      }).toList();
    });
  }

  @override
  Future<ChatEntity> createChat(List<String> participantIds) async {
    final now = DateTime.now();
    final chatRef = _firestore.collection('chats').doc();

    final chatData = {
      'participantIds': participantIds,
      'lastMessage': null,
      'lastMessageTime': null,
      'lastMessageSenderId': null,
      'unreadCounts': {for (var id in participantIds) id: 0},
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'metadata': {},
    };

    await chatRef.set(chatData);

    return ChatEntity(
      id: chatRef.id,
      participantIds: participantIds,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<MessageEntity> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    required MessageType type,
    String? replyToId,
  }) async {
    final now = DateTime.now();
    final messageRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();

    final messageData = {
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(now),
      'isRead': false,
      'readBy': [],
      'replyToId': replyToId,
      'metadata': {},
    };

    await messageRef.set(messageData);

    // Update chat's last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': content,
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageSenderId': senderId,
      'updatedAt': Timestamp.fromDate(now),
    });

    return MessageEntity(
      id: messageRef.id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: type,
      timestamp: now,
      replyToId: replyToId,
    );
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    // Note: In production, you'd need to pass chatId or query for it
    final chatsSnapshot = await _firestore.collection('chats').get();
    for (var chatDoc in chatsSnapshot.docs) {
      final messageRef =
          chatDoc.reference.collection('messages').doc(messageId);
      await messageRef.delete();
    }
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCounts.$userId': 0,
    });
  }

  @override
  Stream<PresenceEntity> watchUserPresence(String userId) {
    return _firestore
        .collection('presence')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return PresenceEntity(
          userId: userId,
          status: OnlineStatus.offline,
        );
      }

      final data = snapshot.data()!;
      return PresenceEntity(
        userId: userId,
        status: _parseOnlineStatus(data['status']),
        lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
        currentChatId: data['currentChatId'],
        isTyping: data['isTyping'] ?? false,
      );
    });
  }

  @override
  Future<void> updatePresence({
    required String userId,
    required OnlineStatus status,
    String? currentChatId,
  }) async {
    await _firestore.collection('presence').doc(userId).set({
      'status': status.name,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
      'currentChatId': currentChatId,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setTypingStatus({
    required String userId,
    required String chatId,
    required bool isTyping,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(userId)
        .set({
      'isTyping': isTyping,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Stream<Map<String, bool>> watchTypingStatus(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      final typingMap = <String, bool>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        typingMap[doc.id] = data['isTyping'] ?? false;
      }
      return typingMap;
    });
  }

  MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    switch (type.toString()) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  OnlineStatus _parseOnlineStatus(dynamic status) {
    if (status == null) return OnlineStatus.offline;
    switch (status.toString()) {
      case 'online':
        return OnlineStatus.online;
      case 'away':
        return OnlineStatus.away;
      default:
        return OnlineStatus.offline;
    }
  }
}
