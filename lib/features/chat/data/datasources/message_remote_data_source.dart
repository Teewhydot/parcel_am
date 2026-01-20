import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/message_model.dart';
import '../models/message_page_model.dart';
import '../../domain/entities/message.dart';
import '../../../../core/utils/logger.dart';

abstract class MessageRemoteDataSource {
  Stream<List<MessageModel>> watchMessages(String chatId);
  Future<MessageModel> sendMessage(MessageModel message);
  Future<MessageModel> updateMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> updates,
  );
  Future<void> deleteMessage(String chatId, String messageId);
  Future<String> uploadFile(
    File file,
    String chatId,
    String fileName,
    String fileType,
  );
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    MessageStatus status,
  );

  /// Load older message pages for pagination
  Future<List<MessageModel>> loadOlderMessages(
    String chatId, {
    int? beforePageNumber,
  });

  /// Check if there are older pages available
  Future<bool> hasOlderMessages(String chatId, int currentPageNumber);
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  MessageRemoteDataSourceImpl({required this.firestore, required this.storage});

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
      tag: 'MessageDataSource',
    );

    return docRef;
  }

  @override
  Stream<List<MessageModel>> watchMessages(String chatId) {
    // Watch only the latest page for real-time updates
    // Older pages are loaded on demand via loadOlderMessages
    return _pagesRef(chatId)
        .orderBy('pageNumber', descending: true)
        .limit(1)
        .snapshots()
        .handleError((error) {
          Logger.logError(
            'Firestore Error (watchMessages): $error',
            tag: 'MessageDataSource',
          );
          if (error.toString().contains('index')) {
            Logger.logError(
              'INDEX REQUIRED: Create a composite index for:',
              tag: 'MessageDataSource',
            );
            Logger.logError(
              '   Collection: chats/{chatId}/pages',
              tag: 'MessageDataSource',
            );
            Logger.logError(
              '   Fields: pageNumber (Descending)',
              tag: 'MessageDataSource',
            );
            Logger.logError(
              '   Or visit the Firebase Console to create the index automatically.',
              tag: 'MessageDataSource',
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
  Future<MessageModel> sendMessage(MessageModel message) async {
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

    // Update chat metadata
    batch.update(chatRef, {
      'lastMessage': message.content,
      'lastMessageSenderId': message.senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Update unread counts for other participants
    final chatDoc = await chatRef.get();
    final participantIds = List<String>.from(
      chatDoc.data()?['participantIds'] ?? [],
    );
    final unreadUpdate = <String, dynamic>{};
    for (var participantId in participantIds) {
      if (participantId != message.senderId) {
        unreadUpdate['unreadCount.$participantId'] = FieldValue.increment(1);
      }
    }
    if (unreadUpdate.isNotEmpty) {
      await chatRef.update(unreadUpdate);
    }

    Logger.logBasic(
      'Message $messageId appended to page ${pageRef.id} in chat ${message.chatId}',
      tag: 'MessageDataSource',
    );
    return messageWithId;
  }

  @override
  Future<List<MessageModel>> loadOlderMessages(
    String chatId, {
    int? beforePageNumber,
  }) async {
    Query<Map<String, dynamic>> query = _pagesRef(
      chatId,
    ).orderBy('pageNumber', descending: true);

    if (beforePageNumber != null) {
      query = query.where('pageNumber', isLessThan: beforePageNumber);
    } else {
      // Skip the latest page (already loaded via stream)
      query = query.startAfter([
        0,
      ]); // This won't work well, need to handle differently
    }

    final snapshot = await query.limit(1).get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    final page = MessagePageModel.fromFirestore(snapshot.docs.first);
    final messages = List<MessageModel>.from(page.messages);
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  @override
  Future<bool> hasOlderMessages(String chatId, int currentPageNumber) async {
    if (currentPageNumber <= 0) return false;

    final snapshot = await _pagesRef(
      chatId,
    ).where('pageNumber', isLessThan: currentPageNumber).limit(1).get();

    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<MessageModel> updateMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> updates,
  ) async {
    // Find the page containing this message
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
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await pageDoc.reference.update({
          'messages': updatedMessages,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Return the updated message
        final updatedMessage = MessageModel.fromJson({
          ...page.messages[messageIndex].toJson(),
          ...updates,
        });
        return updatedMessage;
      }
    }

    throw Exception('Message $messageId not found in chat $chatId');
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    // Find the page containing this message and mark as deleted
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
          'isDeleted': true,
          'content': 'This message was deleted',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await pageDoc.reference.update({
          'messages': updatedMessages,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Logger.logBasic(
          'Message $messageId marked as deleted in page ${pageDoc.id}',
          tag: 'MessageDataSource',
        );
        return;
      }
    }

    Logger.logError(
      'Message $messageId not found in chat $chatId for deletion',
      tag: 'MessageDataSource',
    );
  }

  @override
  Future<String> uploadFile(
    File file,
    String chatId,
    String fileName,
    String fileType,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'chats/$chatId/$fileType/$timestamp-$fileName';

    final ref = storage.ref().child(storagePath);

    String? contentType;
    if (fileType == 'images') {
      contentType = 'image/jpeg';
    } else if (fileType == 'videos') {
      contentType = 'video/mp4';
    } else if (fileType == 'documents') {
      contentType = 'application/pdf';
    }

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  @override
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    MessageStatus status,
  ) async {
    // Find the page containing this message and update status
    final pagesSnapshot = await _pagesRef(chatId).get();

    for (final pageDoc in pagesSnapshot.docs) {
      final page = MessagePageModel.fromFirestore(pageDoc);
      final messageIndex = page.messages.indexWhere((m) => m.id == messageId);

      if (messageIndex != -1) {
        // Found the message, update status in the array
        final updatedMessages = List<Map<String, dynamic>>.from(
          page.messages.map((m) => m.toJson()),
        );
        updatedMessages[messageIndex] = {
          ...updatedMessages[messageIndex],
          'status': status.name,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await pageDoc.reference.update({
          'messages': updatedMessages,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Logger.logBasic(
          'Message $messageId status updated to ${status.name} in page ${pageDoc.id}',
          tag: 'MessageDataSource',
        );
        return;
      }
    }

    Logger.logError(
      'Message $messageId not found in chat $chatId for status update',
      tag: 'MessageDataSource',
    );
  }
}
