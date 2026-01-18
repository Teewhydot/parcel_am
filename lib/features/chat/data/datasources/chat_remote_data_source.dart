import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../../../../core/utils/logger.dart';

abstract class ChatRemoteDataSource {
  Stream<List<MessageModel>> getMessagesStream(String chatId);
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
  Future<void> deleteMessage(String messageId);

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
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ChatRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
      Logger.logError('Firestore Error (getMessagesStream): $error', tag: 'ChatDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Create a composite index for:', tag: 'ChatDataSource');
        Logger.logError('   Collection: chats/{chatId}/messages', tag: 'ChatDataSource');
        Logger.logError('   Fields: timestamp (Descending)', tag: 'ChatDataSource');
        Logger.logError('   Or visit the Firebase Console to create the index automatically.', tag: 'ChatDataSource');
      }
    })
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MessageModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    final messagesRef = firestore
        .collection('chats')
        .doc(message.chatId)
        .collection('messages');

    final messageData = message.toJson();

    // Add message to collection
    if (message.id.isEmpty || message.id.startsWith('temp_')) {
      await messagesRef.add(messageData);
    } else {
      await messagesRef.doc(message.id).set(messageData);
    }

    // Update chat document with last message and notification trigger
    await firestore.collection('chats').doc(message.chatId).update({
      'lastMessage': messageData,
      'lastMessageTime': message.timestamp,
      // Add notification trigger data for Cloud Function
      // This can be picked up by a Firestore trigger to send FCM notifications
      'pendingNotification': {
        'senderId': message.senderId,
        'senderName': message.senderName,
        'messagePreview': message.content.length > 100
            ? '${message.content.substring(0, 100)}...'
            : message.content,
        'chatId': message.chatId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': message.type.toString(),
      },
    });

    // Note: In a production app, a Cloud Function would listen to the
    // 'pendingNotification' field update and send FCM notifications to
    // all chat participants except the sender. The function would:
    // 1. Get FCM tokens for all participants from users/{userId}/fcmTokens
    // 2. Filter out the sender's tokens
    // 3. Send FCM data message with chatId, senderName, and messagePreview
    // 4. Clear the pendingNotification field after sending
  }

  @override
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final messagesQuery = await firestore
        .collectionGroup('messages')
        .where('id', isEqualTo: messageId)
        .limit(1)
        .get();

    if (messagesQuery.docs.isNotEmpty) {
      await messagesQuery.docs.first.reference.update({
        'status': status.name,
      });
    }
  }

  @override
  Future<void> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  ) async {
    final messageRef = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({
      'readBy.$userId': FieldValue.serverTimestamp(),
      'status': MessageStatus.read.name,
    });
  }

  @override
  Future<String> uploadMedia(
    String filePath,
    String chatId,
    MessageType type,
    Function(double) onProgress,
  ) async {
    final file = File(filePath);
    final fileName = file.path.split('/').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String folder = type == MessageType.image
        ? 'images'
        : type == MessageType.video
            ? 'videos'
            : 'documents';

    final ref = storage.ref().child('chats/$chatId/$folder/$timestamp-$fileName');

    final uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress(progress);
    });

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  @override
  Future<void> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    try {
      // Use update() to avoid creating partial documents without participantIds
      // The chat should already exist from getOrCreateChat before navigating
      await firestore.collection('chats').doc(chatId).update({
        'isTyping.$userId': isTyping,
      });
    } catch (e) {
      // Log but don't fail - chat may not exist yet if navigated directly
      Logger.logError('setTypingStatus failed for chat $chatId: $e', tag: 'ChatDataSource');
    }
  }

  @override
  Future<void> updateLastSeen(String chatId, String userId) async {
    try {
      // Use update() to avoid creating partial documents without participantIds
      // The chat should already exist from getOrCreateChat before navigating
      await firestore.collection('chats').doc(chatId).update({
        'lastSeen.$userId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log but don't fail - chat may not exist yet if navigated directly
      Logger.logError('updateLastSeen failed for chat $chatId: $e', tag: 'ChatDataSource');
    }
  }

  @override
  Stream<ChatModel> getChatStream(String chatId) {
    return firestore.collection('chats').doc(chatId).snapshots().handleError((error) {
      Logger.logError('Firestore Error (getChatStream): $error', tag: 'ChatDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Check Firebase Console for index requirements', tag: 'ChatDataSource');
      }
    }).map((snapshot) {
      if (!snapshot.exists) {
        // Return a default chat when document doesn't exist yet
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
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      return ChatModel.fromJson(data);
    });
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    final messagesQuery = await firestore
        .collectionGroup('messages')
        .where('id', isEqualTo: messageId)
        .limit(1)
        .get();

    if (messagesQuery.docs.isNotEmpty) {
      await messagesQuery.docs.first.reference.update({
        'isDeleted': true,
        'content': 'This message was deleted',
      });
    }
  }

  @override
  Future<ChatModel> createChat(List<String> participantIds) async {
    final chatRef = firestore.collection('chats').doc();

    // Set lastMessageTime to createdAt so it appears in orderBy queries
    final chatData = {
      'participantIds': participantIds,
      'participantNames': <String, String>{},
      'participantAvatars': <String, String?>{},
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': <String, int>{},
      'isTyping': <String, bool>{},
      'lastSeen': <String, dynamic>{},
    };

    await chatRef.set(chatData);

    final createdDoc = await chatRef.get();
    final data = createdDoc.data()!;
    data['id'] = createdDoc.id;
    return ChatModel.fromJson(data);
  }

  @override
  Future<ChatModel> getChat(String chatId) async {
    final doc = await firestore.collection('chats').doc(chatId).get();

    if (!doc.exists) {
      throw Exception('Chat not found');
    }

    final data = doc.data()!;
    data['id'] = doc.id;
    return ChatModel.fromJson(data);
  }

  @override
  Future<List<ChatModel>> getUserChats(String userId) async {
    final snapshot = await firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ChatModel.fromJson(data);
    }).toList();
  }

  @override
  Stream<ChatModel> watchChat(String chatId) {
    return firestore.collection('chats').doc(chatId).snapshots().handleError((error) {
      Logger.logError('Firestore Error (watchChat): $error', tag: 'ChatDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Check Firebase Console for index requirements', tag: 'ChatDataSource');
      }
    }).map((snapshot) {
      if (!snapshot.exists) {
        // Return a default chat when document doesn't exist yet
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
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      return ChatModel.fromJson(data);
    });
  }

  @override
  Stream<List<ChatModel>> watchUserChats(String userId) {
    Logger.logBasic('watchUserChats called with userId: $userId', tag: 'ChatDataSource');
    return firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .handleError((error) {
      Logger.logError('Firestore Error (watchUserChats): $error', tag: 'ChatDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Create a composite index for:', tag: 'ChatDataSource');
        Logger.logError('   Collection: chats', tag: 'ChatDataSource');
        Logger.logError('   Fields: participantIds (Array), lastMessageTime (Descending)', tag: 'ChatDataSource');
        Logger.logError('   Or visit the Firebase Console to create the index automatically.', tag: 'ChatDataSource');
      }
    })
        .map((snapshot) {
      Logger.logBasic('watchUserChats returned ${snapshot.docs.length} chats for userId: $userId', tag: 'ChatDataSource');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        Logger.logBasic('Chat doc ${doc.id} participantIds: ${data['participantIds']}', tag: 'ChatDataSource');
        return ChatModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<ChatModel> getOrCreateChat({
    required String chatId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
  }) async {
    Logger.logBasic('getOrCreateChat called - chatId: $chatId, participantIds: $participantIds', tag: 'ChatDataSource');
    final chatRef = firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (chatDoc.exists) {
      final data = chatDoc.data()!;

      // Check if participantIds is missing or empty - repair if needed
      final existingParticipantIds = data['participantIds'] as List<dynamic>?;
      if (existingParticipantIds == null || existingParticipantIds.isEmpty) {
        Logger.logBasic('Chat $chatId exists but missing participantIds - repairing', tag: 'ChatDataSource');

        // Update the document with missing fields
        await chatRef.update({
          'participantIds': participantIds,
          'participantNames': participantNames,
          // Ensure lastMessageTime exists for ordering in queries
          if (data['lastMessageTime'] == null) 'lastMessageTime': FieldValue.serverTimestamp(),
        });

        Logger.logBasic('Chat $chatId repaired with participantIds: $participantIds', tag: 'ChatDataSource');

        // Return with updated data
        data['participantIds'] = participantIds;
        data['participantNames'] = participantNames;
      } else {
        Logger.logBasic('Chat $chatId already exists with participantIds: $existingParticipantIds', tag: 'ChatDataSource');
      }

      data['id'] = chatDoc.id;
      return ChatModel.fromJson(data);
    }

    Logger.logBasic('Creating new chat $chatId with participantIds: $participantIds', tag: 'ChatDataSource');
    // Create new chat with the specified ID
    // Set lastMessageTime to createdAt so it appears in orderBy queries
    final chatData = {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': <String, String?>{},
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': <String, int>{},
      'isTyping': <String, bool>{},
      'lastSeen': <String, dynamic>{},
    };

    await chatRef.set(chatData);
    Logger.logBasic('Chat $chatId created successfully', tag: 'ChatDataSource');

    // Return the created chat
    return ChatModel(
      id: chatId,
      participantIds: participantIds,
      participantNames: participantNames,
      participantAvatars: {},
      unreadCount: {},
      isTyping: {},
      lastSeen: {},
      createdAt: DateTime.now(),
    );
  }
}
