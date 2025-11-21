import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/message_model.dart';
import '../../domain/entities/message.dart';
import '../../../../core/utils/logger.dart';

abstract class MessageRemoteDataSource {
  Stream<List<MessageModel>> watchMessages(String chatId);
  Future<MessageModel> sendMessage(MessageModel message);
  Future<MessageModel> updateMessage(String chatId, String messageId, Map<String, dynamic> updates);
  Future<void> deleteMessage(String chatId, String messageId);
  Future<String> uploadFile(File file, String chatId, String fileName, String fileType);
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status);
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  MessageRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .handleError((error) {
      Logger.logError('Firestore Error (watchMessages): $error', tag: 'MessageDataSource');
      if (error.toString().contains('index')) {
        Logger.logError('INDEX REQUIRED: Create a composite index for:', tag: 'MessageDataSource');
        Logger.logError('   Collection: chats/{chatId}/messages', tag: 'MessageDataSource');
        Logger.logError('   Fields: createdAt (Ascending)', tag: 'MessageDataSource');
        Logger.logError('   Or visit the Firebase Console to create the index automatically.', tag: 'MessageDataSource');
      }
    })
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    final chatRef = firestore.collection('chats').doc(message.chatId);
    final messagesRef = chatRef.collection('messages');

    final messageData = message.toJson();
    final docRef = await messagesRef.add(messageData);

    await chatRef.update({
      'lastMessage': message.content,
      'lastMessageSenderId': message.senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final chatDoc = await chatRef.get();
    final participantIds = List<String>.from(chatDoc.data()?['participantIds'] ?? []);
    final unreadUpdate = <String, dynamic>{};
    for (var participantId in participantIds) {
      if (participantId != message.senderId) {
        unreadUpdate['unreadCount.$participantId'] = FieldValue.increment(1);
      }
    }
    if (unreadUpdate.isNotEmpty) {
      await chatRef.update(unreadUpdate);
    }

    final doc = await docRef.get();
    return MessageModel.fromFirestore(doc);
  }

  @override
  Future<MessageModel> updateMessage(String chatId, String messageId, Map<String, dynamic> updates) async {
    final messageRef = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await messageRef.get();
    return MessageModel.fromFirestore(doc);
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isDeleted': true,
      'content': 'This message was deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String> uploadFile(File file, String chatId, String fileName, String fileType) async {
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
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
