import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

abstract class ChatRemoteDataSource {
  Stream<List<ChatModel>> watchUserChats(String userId);
  Stream<ChatModel> watchChat(String chatId);
  Future<ChatModel> createChat(List<String> participantIds, Map<String, dynamic> participantInfo);
  Future<void> updateChat(String chatId, Map<String, dynamic> updates);
  Future<void> deleteChat(String chatId);
  Future<void> markMessagesAsRead(String chatId, String userId);
  Future<ChatModel?> getChatByParticipants(List<String> participantIds);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;

  ChatRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<ChatModel>> watchUserChats(String userId) {
    return firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<ChatModel> watchChat(String chatId) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Chat not found');
      }
      return ChatModel.fromFirestore(snapshot);
    });
  }

  @override
  Future<ChatModel> createChat(List<String> participantIds, Map<String, dynamic> participantInfo) async {
    final now = DateTime.now();
    final chatData = {
      'participantIds': participantIds,
      'participantInfo': participantInfo,
      'lastMessage': null,
      'lastMessageSenderId': null,
      'lastMessageAt': null,
      'unreadCount': {for (var id in participantIds) id: 0},
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'metadata': {},
      'chatType': participantIds.length == 2 ? 'direct' : 'group',
    };

    final docRef = await firestore.collection('chats').add(chatData);
    final doc = await docRef.get();
    return ChatModel.fromFirestore(doc);
  }

  @override
  Future<void> updateChat(String chatId, Map<String, dynamic> updates) async {
    await firestore.collection('chats').doc(chatId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteChat(String chatId) async {
    await firestore.collection('chats').doc(chatId).delete();
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    await firestore.collection('chats').doc(chatId).update({
      'unreadCount.$userId': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final messagesQuery = await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('status', isNotEqualTo: 'read')
        .get();

    final batch = firestore.batch();
    for (var doc in messagesQuery.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }
    await batch.commit();
  }

  @override
  Future<ChatModel?> getChatByParticipants(List<String> participantIds) async {
    final sortedIds = List<String>.from(participantIds)..sort();
    
    final querySnapshot = await firestore
        .collection('chats')
        .where('participantIds', isEqualTo: sortedIds)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return ChatModel.fromFirestore(querySnapshot.docs.first);
  }
}
