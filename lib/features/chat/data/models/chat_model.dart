import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat.dart';
import 'message_model.dart';

class ChatModel extends Chat {
  const ChatModel({
    required super.id,
    required super.participantIds,
    required super.participantNames,
    required super.participantAvatars,
    super.lastMessage,
    super.lastMessageTime,
    required super.unreadCount,
    required super.isTyping,
    required super.lastSeen,
    required super.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
      participantNames: Map<String, String>.from(json['participantNames'] as Map),
      participantAvatars: Map<String, String?>.from(json['participantAvatars'] as Map),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageTime: json['lastMessageTime'] != null
          ? (json['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(json['unreadCount'] as Map),
      isTyping: Map<String, bool>.from(json['isTyping'] as Map),
      lastSeen: (json['lastSeen'] as Map).map(
        (key, value) => MapEntry(
          key as String,
          value != null ? (value as Timestamp).toDate() : null,
        ),
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  factory ChatModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return ChatModel.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage != null
          ? MessageModel.fromEntity(lastMessage!).toJson()
          : null,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'lastSeen': lastSeen.map(
        (key, value) =>
            MapEntry(key, value != null ? Timestamp.fromDate(value) : null),
      ),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
