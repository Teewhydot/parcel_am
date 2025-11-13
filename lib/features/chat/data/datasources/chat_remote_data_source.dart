import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/message.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

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
    
    if (message.id.isEmpty || message.id.startsWith('temp_')) {
      await messagesRef.add(messageData);
    } else {
      await messagesRef.doc(message.id).set(messageData);
    }

    await firestore.collection('chats').doc(message.chatId).update({
      'lastMessage': messageData,
      'lastMessageTime': message.timestamp,
    });
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
    await firestore.collection('chats').doc(chatId).update({
      'isTyping.$userId': isTyping,
    });
  }

  @override
  Future<void> updateLastSeen(String chatId, String userId) async {
    await firestore.collection('chats').doc(chatId).update({
      'lastSeen.$userId': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<ChatModel> getChatStream(String chatId) {
    return firestore.collection('chats').doc(chatId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Chat not found');
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
}
