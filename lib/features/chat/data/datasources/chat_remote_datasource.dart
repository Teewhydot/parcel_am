import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../../domain/entities/chat_entity.dart';

abstract class ChatRemoteDataSource {
  Stream<List<ChatModel>> getChatList(String userId);
  Stream<PresenceStatus> getPresenceStatus(String userId);
  Future<void> deleteChat(String chatId);
  Future<void> markAsRead(String chatId);
  Future<void> togglePin(String chatId, bool isPinned);
  Future<void> toggleMute(String chatId, bool isMuted);
  Future<List<ChatUserModel>> searchUsers(String query);
  Future<String> createChat(String currentUserId, String participantId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;

  ChatRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<ChatModel>> getChatList(String userId) {
    return firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<PresenceStatus> getPresenceStatus(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return PresenceStatus.offline;
      final data = snapshot.data();
      final status = data?['presenceStatus'] as String?;
      switch (status) {
        case 'online':
          return PresenceStatus.online;
        case 'typing':
          return PresenceStatus.typing;
        default:
          return PresenceStatus.offline;
      }
    });
  }

  @override
  Future<void> deleteChat(String chatId) async {
    await firestore.collection('chats').doc(chatId).delete();
  }

  @override
  Future<void> markAsRead(String chatId) async {
    await firestore.collection('chats').doc(chatId).update({
      'unreadCount': 0,
    });
  }

  @override
  Future<void> togglePin(String chatId, bool isPinned) async {
    await firestore.collection('chats').doc(chatId).update({
      'isPinned': isPinned,
    });
  }

  @override
  Future<void> toggleMute(String chatId, bool isMuted) async {
    await firestore.collection('chats').doc(chatId).update({
      'isMuted': isMuted,
    });
  }

  @override
  Future<List<ChatUserModel>> searchUsers(String query) async {
    final snapshot = await firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThan: '${query}z')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => ChatUserModel.fromFirestore(doc)).toList();
  }

  @override
  Future<String> createChat(String currentUserId, String participantId) async {
    final existingChat = await firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in existingChat.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(participantId)) {
        return doc.id;
      }
    }

    final participantDoc = await firestore.collection('users').doc(participantId).get();
    final participantData = participantDoc.data();

    final newChat = await firestore.collection('chats').add({
      'participants': [currentUserId, participantId],
      'participantId': participantId,
      'participantName': participantData?['displayName'] ?? 'Unknown',
      'participantAvatar': participantData?['photoURL'],
      'lastMessage': null,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': 0,
      'presenceStatus': 'offline',
      'isPinned': false,
      'isMuted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }
}
