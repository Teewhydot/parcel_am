import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';
import '../models/message_model.dart';
import '../models/message_page_model.dart';
import '../models/chat_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../file_upload/data/remote/data_sources/file_upload.dart';

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

  Future<void> markMessageNotificationSent(String chatId, String messageId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final FileUploadDataSource fileUploadDataSource;

  ChatRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
    FileUploadDataSource? fileUploadDataSource,
  }) : fileUploadDataSource = fileUploadDataSource ?? GetIt.instance<FileUploadDataSource>();

  /// Get reference to the pages subcollection for a chat
  CollectionReference<Map<String, dynamic>> _pagesRef(String chatId) {
    return firestore.collection('chats').doc(chatId).collection('pages');
  }

  /// Get or create the current (latest) message page for a chat
  Future<DocumentReference<Map<String, dynamic>>> _getCurrentPage(
    String chatId,
  ) async {
    final pagesQuery = await _pagesRef(
      chatId,
    ).orderBy('pageNumber', descending: true).limit(1).get();

    if (pagesQuery.docs.isEmpty) {
      // Create the first page
      return _createNewPage(chatId, pageNumber: 0, hasOlderPages: false);
    }

    final currentPage = MessagePageModel.fromFirestore(pagesQuery.docs.first);

    if (!currentPage.canAcceptMoreMessages) {
      // Current page is full, create a new one
      return _createNewPage(
        chatId,
        pageNumber: currentPage.pageNumber + 1,
        hasOlderPages: true,
      );
    }

    return pagesQuery.docs.first.reference;
  }

  /// Create a new message page
  Future<DocumentReference<Map<String, dynamic>>> _createNewPage(
    String chatId, {
    required int pageNumber,
    required bool hasOlderPages,
  }) async {
    final newPage = MessagePageModel.empty(
      chatId: chatId,
      pageNumber: pageNumber,
      hasOlderPages: hasOlderPages,
    );

    final docRef = _pagesRef(chatId).doc();
    final pageData = newPage.toJson();
    pageData['id'] = docRef.id;

    await docRef.set(pageData);
    Logger.logBasic(
      'Created new message page ${docRef.id} (page $pageNumber) for chat $chatId',
      tag: 'ChatDataSource',
    );

    return docRef;
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    // Watch the latest page for real-time updates
    return _pagesRef(chatId)
        .orderBy('pageNumber', descending: true)
        .limit(1)
        .snapshots(includeMetadataChanges: false)
        .handleError((error) {
          Logger.logError(
            'Firestore Error (getMessagesStream): $error',
            tag: 'ChatDataSource',
          );
          if (error.toString().contains('index')) {
            Logger.logError(
              'INDEX REQUIRED: Create a composite index for:',
              tag: 'ChatDataSource',
            );
            Logger.logError(
              '   Collection: chats/{chatId}/pages',
              tag: 'ChatDataSource',
            );
            Logger.logError(
              '   Fields: pageNumber (Descending)',
              tag: 'ChatDataSource',
            );
            Logger.logError(
              '   Or visit the Firebase Console to create the index automatically.',
              tag: 'ChatDataSource',
            );
          }
        })
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return <MessageModel>[];
          }

          final page = MessagePageModel.fromFirestore(snapshot.docs.first);
          // Return messages sorted by timestamp ascending (oldest first for display)
          final messages = List<MessageModel>.from(page.messages);
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    final chatRef = firestore.collection('chats').doc(message.chatId);
    final pageRef = await _getCurrentPage(message.chatId);

    // Generate a unique message ID
    final messageId = firestore.collection('_').doc().id;
    final messageWithId = MessageModel(
      id: messageId,
      chatId: message.chatId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      content: message.content,
      type: message.type,
      status: MessageStatus.sent,
      timestamp: message.timestamp,
      mediaUrl: message.mediaUrl,
      thumbnailUrl: message.thumbnailUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      replyToMessageId: message.replyToMessageId,
      isDeleted: message.isDeleted,
      readBy: message.readBy,
      notificationSent: message.notificationSent,
    );

    final messageData = messageWithId.toJson();
    final messageBytes = MessagePageModel.estimateMessageBytes(messageWithId);

    // Use a batch to update both the page and chat metadata atomically
    final batch = firestore.batch();

    // Append message to the page's messages array
    batch.update(pageRef, {
      'messages': FieldValue.arrayUnion([messageData]),
      'messageCount': FieldValue.increment(1),
      'bytesUsed': FieldValue.increment(messageBytes),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update chat document with last message and notification trigger
    batch.update(chatRef, {
      'lastMessage': messageData,
      'lastMessageTime': message.timestamp,
      // Add notification trigger data for Cloud Function
      'pendingNotification': {
        'senderId': message.senderId,
        'senderName': message.senderName,
        'messagePreview': message.content.length > 100
            ? '${message.content.substring(0, 100)}...'
            : message.content,
        'chatId': message.chatId,
        'messageId': messageId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': message.type.toString(),
      },
    });

    await batch.commit();

    Logger.logBasic(
      'Message $messageId appended to page ${pageRef.id} in chat ${message.chatId}',
      tag: 'ChatDataSource',
    );
  }

  /// Helper method to find and update a message in the paged structure
  Future<void> _updateMessageInPages(
    String chatId,
    String messageId,
    Map<String, dynamic> updates,
  ) async {
    final pagesSnapshot = await _pagesRef(chatId).get();

    for (final pageDoc in pagesSnapshot.docs) {
      final page = MessagePageModel.fromFirestore(pageDoc);
      final messageIndex = page.messages.indexWhere((m) => m.id == messageId);

      if (messageIndex != -1) {
        // Found the message, update it in the array
        final updatedMessages = List<Map<String, dynamic>>.from(
          page.messages.map((m) => m.toJson()),
        );
        updatedMessages[messageIndex] = {
          ...updatedMessages[messageIndex],
          ...updates,
        };

        await pageDoc.reference.update({
          'messages': updatedMessages,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Logger.logBasic(
          'Updated message $messageId in page ${pageDoc.id}',
          tag: 'ChatDataSource',
        );
        return;
      }
    }

    Logger.logError(
      'Message $messageId not found in chat $chatId for update',
      tag: 'ChatDataSource',
    );
  }

  @override
  Future<void> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    // Need to find the chat first - search across all chats' pages
    // This is expensive, so in practice the caller should provide chatId
    final chatsSnapshot = await firestore.collection('chats').get();

    for (final chatDoc in chatsSnapshot.docs) {
      final pagesSnapshot = await _pagesRef(chatDoc.id).get();

      for (final pageDoc in pagesSnapshot.docs) {
        final page = MessagePageModel.fromFirestore(pageDoc);
        final messageIndex = page.messages.indexWhere((m) => m.id == messageId);

        if (messageIndex != -1) {
          final updatedMessages = List<Map<String, dynamic>>.from(
            page.messages.map((m) => m.toJson()),
          );
          updatedMessages[messageIndex] = {
            ...updatedMessages[messageIndex],
            'status': status.name,
          };

          await pageDoc.reference.update({
            'messages': updatedMessages,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          Logger.logBasic(
            'Updated message $messageId status to ${status.name} in page ${pageDoc.id}',
            tag: 'ChatDataSource',
          );
          return;
        }
      }
    }

    Logger.logError(
      'Message $messageId not found for status update',
      tag: 'ChatDataSource',
    );
  }

  @override
  Future<void> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  ) async {
    await _updateMessageInPages(chatId, messageId, {
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
    try {
      // Use update() to avoid creating partial documents without participantIds
      // The chat should already exist from getOrCreateChat before navigating
      await firestore.collection('chats').doc(chatId).update({
        'isTyping.$userId': isTyping,
      });
    } catch (e) {
      // Log but don't fail - chat may not exist yet if navigated directly
      Logger.logError(
        'setTypingStatus failed for chat $chatId: $e',
        tag: 'ChatDataSource',
      );
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
      Logger.logError(
        'updateLastSeen failed for chat $chatId: $e',
        tag: 'ChatDataSource',
      );
    }
  }

  @override
  Stream<ChatModel> getChatStream(String chatId) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .snapshots(includeMetadataChanges: false) // Avoid duplicate emissions
        .handleError((error) {
          Logger.logError(
            'Firestore Error (getChatStream): $error',
            tag: 'ChatDataSource',
          );
          if (error.toString().contains('index')) {
            Logger.logError(
              'INDEX REQUIRED: Check Firebase Console for index requirements',
              tag: 'ChatDataSource',
            );
          }
        })
        .map((snapshot) {
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
    // Need to find the chat first - search across all chats' pages
    final chatsSnapshot = await firestore.collection('chats').get();

    for (final chatDoc in chatsSnapshot.docs) {
      final pagesSnapshot = await _pagesRef(chatDoc.id).get();

      for (final pageDoc in pagesSnapshot.docs) {
        final page = MessagePageModel.fromFirestore(pageDoc);
        final messageIndex = page.messages.indexWhere((m) => m.id == messageId);

        if (messageIndex != -1) {
          final updatedMessages = List<Map<String, dynamic>>.from(
            page.messages.map((m) => m.toJson()),
          );
          updatedMessages[messageIndex] = {
            ...updatedMessages[messageIndex],
            'isDeleted': true,
            'content': 'This message was deleted',
          };

          await pageDoc.reference.update({
            'messages': updatedMessages,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          Logger.logBasic(
            'Message $messageId marked as deleted in page ${pageDoc.id}',
            tag: 'ChatDataSource',
          );
          return;
        }
      }
    }

    Logger.logError(
      'Message $messageId not found for deletion',
      tag: 'ChatDataSource',
    );
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
    return firestore
        .collection('chats')
        .doc(chatId)
        .snapshots(includeMetadataChanges: false) // Avoid duplicate emissions
        .handleError((error) {
          Logger.logError(
            'Firestore Error (watchChat): $error',
            tag: 'ChatDataSource',
          );
          if (error.toString().contains('index')) {
            Logger.logError(
              'INDEX REQUIRED: Check Firebase Console for index requirements',
              tag: 'ChatDataSource',
            );
          }
        })
        .map((snapshot) {
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
    return firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .limit(20) // Limit to most recent chats for efficiency
        .snapshots(includeMetadataChanges: false) // Avoid duplicate emissions
        .handleError((error) {
          Logger.logError(
            'Firestore Error (watchUserChats): $error',
            tag: 'ChatDataSource',
          );
          if (error.toString().contains('index')) {
            Logger.logError(
              'INDEX REQUIRED: Create a composite index for:',
              tag: 'ChatDataSource',
            );
            Logger.logError('   Collection: chats', tag: 'ChatDataSource');
            Logger.logError(
              '   Fields: participantIds (Array), lastMessageTime (Descending)',
              tag: 'ChatDataSource',
            );
            Logger.logError(
              '   Or visit the Firebase Console to create the index automatically.',
              tag: 'ChatDataSource',
            );
          }
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
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
    Logger.logBasic(
      'getOrCreateChat called - chatId: $chatId, participantIds: $participantIds',
      tag: 'ChatDataSource',
    );
    final chatRef = firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (chatDoc.exists) {
      final data = chatDoc.data()!;

      // Check if participantIds is missing or empty - repair if needed
      final existingParticipantIds = data['participantIds'] as List<dynamic>?;
      if (existingParticipantIds == null || existingParticipantIds.isEmpty) {
        Logger.logBasic(
          'Chat $chatId exists but missing participantIds - repairing',
          tag: 'ChatDataSource',
        );

        // Update the document with missing fields
        await chatRef.update({
          'participantIds': participantIds,
          'participantNames': participantNames,
          // Ensure lastMessageTime exists for ordering in queries
          if (data['lastMessageTime'] == null)
            'lastMessageTime': FieldValue.serverTimestamp(),
        });

        Logger.logBasic(
          'Chat $chatId repaired with participantIds: $participantIds',
          tag: 'ChatDataSource',
        );

        // Return with updated data
        data['participantIds'] = participantIds;
        data['participantNames'] = participantNames;
      } else {
        Logger.logBasic(
          'Chat $chatId already exists with participantIds: $existingParticipantIds',
          tag: 'ChatDataSource',
        );
      }

      data['id'] = chatDoc.id;
      return ChatModel.fromJson(data);
    }

    Logger.logBasic(
      'Creating new chat $chatId with participantIds: $participantIds',
      tag: 'ChatDataSource',
    );
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

  @override
  Future<void> markMessageNotificationSent(
    String chatId,
    String messageId,
  ) async {
    try {
      // Update the message in the paged structure
      await _updateMessageInPages(chatId, messageId, {
        'notificationSent': true,
      });

      // Also update the lastMessage in the chat document if it matches
      final chatDoc = await firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final data = chatDoc.data();
        if (data != null && data['lastMessage'] != null) {
          final lastMessageData = data['lastMessage'] as Map<String, dynamic>;
          if (lastMessageData['id'] == messageId) {
            await firestore.collection('chats').doc(chatId).update({
              'lastMessage.notificationSent': true,
            });
          }
        }
      }
    } catch (e) {
      Logger.logError(
        'markMessageNotificationSent failed: $e',
        tag: 'ChatDataSource',
      );
    }
  }
}
